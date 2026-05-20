{ config, lib, pkgs, ... }:

# Home Manager module for Ghostty on AVA.
#
# The vendored ./assets/ghostty/config relies on repeated keys
# (`palette = N=hex` x22, `keybind = X=Y` x100+) which the
# programs.ghostty `settings` attrset cannot represent without
# restructuring. To preserve fidelity with the live config and the
# explicit fallback option in the migration plan, this module installs
# the vendored file verbatim via xdg.configFile.
#
# The Ghostty binary itself is installed via the Homebrew cask bridge
# (Topic 15), so this module owns config only.
#
# Per .ai/plan/MIGRATION.md D11 the font family in the
# vendored config has been corrected to
# "Operator Mono * Nerd Font Complete" (the literal "*" is part of the
# Nerd Font Complete family name). The historical
# "OperatorMono Nerd Font Mono" string in ~/dotfiles/ghostty/config was
# wrong and would silently fall back to a generic monospace face.

{
  xdg.configFile."ghostty/config".source = ./assets/ghostty/config;
}
