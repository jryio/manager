{ config, lib, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
  fzfTabPackage =
    if builtins.hasAttr "zsh-fzf-tab" pkgs then
      pkgs."zsh-fzf-tab"
    else if builtins.hasAttr "fzf-tab" pkgs then
      pkgs."fzf-tab"
    else
      throw "No fzf-tab package found in pkgs";
  interactiveInit = lib.concatStringsSep "\n\n" [
    ''
      source_first_existing_script() {
        local script

        for script in "$@"; do
          if [[ -r "$script" ]]; then
            source "$script"
            return 0
          fi
        done

        return 1
      }

      source_first_existing_script \
        ${pkgs."zsh-powerlevel10k"}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme \
        ${pkgs."zsh-powerlevel10k"}/share/powerlevel10k/powerlevel10k.zsh-theme \
        ${pkgs."zsh-powerlevel10k"}/powerlevel10k.zsh-theme

      source_first_existing_script \
        ${fzfTabPackage}/share/fzf-tab/fzf-tab.plugin.zsh \
        ${fzfTabPackage}/fzf-tab.plugin.zsh

      source_first_existing_script \
        ${pkgs."zsh-autosuggestions"}/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        ${pkgs."zsh-autosuggestions"}/zsh-autosuggestions.zsh

      unfunction source_first_existing_script
    ''
    (builtins.readFile ./shell/init.zsh)
  ];
in
{
  programs.zsh = {
    enable = true;
    dotDir = homeDir;
    enableCompletion = true;

    envExtra = builtins.readFile ./shell/env.zsh;
    profileExtra = builtins.readFile ./shell/profile.zsh;
    initExtraBeforeCompInit = builtins.readFile ./shell/before-compinit.zsh;
    initContent = interactiveInit;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "common-aliases"
      ];
    };
  };

  home.file.".p10k.zsh".source = ./shell/p10k.zsh;

  home.sessionPath = [ "${homeDir}/.local/bin" ];

  home.sessionVariables = {
    FZF_DEFAULT_COMMAND = "rg --files --hidden --smart-case --follow --glob '!.git/*'";
  };
}
