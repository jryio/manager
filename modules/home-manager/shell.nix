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
  zshInitContent = lib.mkMerge [
    (lib.mkOrder 550 (builtins.readFile ./shell/before-compinit.zsh))
    (lib.mkOrder 850 ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    '')
    (lib.mkOrder 1000 (builtins.readFile ./shell/init.zsh))
  ];
in
{
  programs.zsh = {
    enable = true;
    dotDir = homeDir;
    enableCompletion = true;
    autosuggestion.enable = true;

    envExtra = builtins.readFile ./shell/env.zsh;
    profileExtra = builtins.readFile ./shell/profile.zsh;
    initContent = zshInitContent;

    plugins = [
      {
        name = "fzf-tab";
        src = fzfTabPackage;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];

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
