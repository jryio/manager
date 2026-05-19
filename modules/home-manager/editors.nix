{ config, lib, pkgs, ... }:
{
  # Neovim runtime — config tree only; vim-plug bootstraps plugins imperatively on first launch.
  xdg.configFile."nvim" = {
    source = ./assets/nvim;
    recursive = true;
  };

  # LunarVim — config tree only; lvim installer bootstraps runtime under ~/.local/share/lunarvim imperatively.
  xdg.configFile."lvim" = {
    source = ./assets/lvim;
    recursive = true;
  };

  # nvim + lvim binaries: nvim comes from the Homebrew bridge per D5; lvim launcher under ~/.local/bin/lvim
  # is installed by the LunarVim installer and is NOT managed by Nix.
}
