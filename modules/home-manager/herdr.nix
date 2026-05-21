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
#
# herdr writes runtime UI state (e.g. agent_panel_scope) back into
# config.toml, so a /nix/store symlink would fail with EACCES on every
# UI toggle. We copy the vendored file in instead and force-overwrite
# on every switch — declarative bindings always win, in-session UI
# toggles are accepted as ephemeral.

let
  herdrConfigDir = "${config.home.homeDirectory}/.config/herdr";
  vendoredConfig = ./assets/herdr/config.toml;
in
{
  home.activation.herdrConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${herdrConfigDir}"
    # rm first: a stale HM symlink would make `install` follow into the
    # read-only /nix/store target.
    rm -f "${herdrConfigDir}/config.toml"
    install -m 0644 "${vendoredConfig}" "${herdrConfigDir}/config.toml"
  '';
}
