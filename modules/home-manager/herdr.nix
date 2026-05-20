{ config, lib, pkgs, ... }:

# Home Manager module for herdr (https://herdr.dev).
#
# herdr is a keyboard-driven workspace/tab/pane manager that runs inside
# Ghostty. The binary itself is dropped into ~/.local/bin/herdr by
# bootstrap/install.sh via the upstream curl-pipe installer (no
# Homebrew formula or nixpkgs derivation exists). ~/.local/bin is on
# PATH via home.sessionPath in shell.nix.
#
# This module owns ~/.config/herdr/config.toml only. The vendored
# ./assets/herdr/config.toml mirrors the user's tmux key conventions
# from ./assets/tmux/tmux.conf so the same muscle memory applies in
# both tools.

{
  xdg.configFile."herdr/config.toml".source = ./assets/herdr/config.toml;
}
