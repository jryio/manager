{ config, lib, pkgs, ... }:

# Home Manager module for tmux on AVA.
#
# Per .ai/plan/MIGRATION.md (architecture freeze):
#   - Plugins are nix-packaged (no TPM bootstrap).
#   - extraConfig comes from the vendored ./assets/tmux/tmux.conf, curated
#     down from ~/dotfiles/tmux/tmux.conf so it no longer references
#     TPM, the legacy xterm-256color-italic terminfo, or the duplicate
#     mode-keys/escape-time/history-limit options that this module owns.
#
# The vendored conf still keeps every @-prefixed option that the
# resurrect/continuum/online-status plugins read at runtime.

{
  programs.tmux = {
    enable = true;
    shell = "/bin/zsh";
    # tmux-256color is the modern truecolor-friendly terminfo and ships
    # with nixpkgs' ncurses. xterm-256color-italic is intentionally
    # dropped per MIGRATION.md D11/D30 (no requirement to keep it).
    terminal = "tmux-256color";
    escapeTime = 0;
    historyLimit = 50000;
    keyMode = "vi";
    mouse = true;

    # Plugins matching the original TPM list from ~/dotfiles/tmux/tmux.conf.
    # tpm itself is intentionally omitted.
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      sessionist
      resurrect
      continuum
      battery
      online-status
    ];

    extraConfig = builtins.readFile ./assets/tmux/tmux.conf;
  };
}
