{ config, ... }:
let
  # lazy.nvim writes lazy-lock.json into the config directory, so a read-only
  # copy in the Nix store would break `:Lazy update`. This is the one asset tree
  # that has to stay writable in place; the repo is assumed at ~/manager, the
  # same assumption the `drs` alias in shell.nix makes.
  configTree = "${config.home.homeDirectory}/manager/modules/home-manager/assets/nvim-lazy";
in
{
  # Neovim: LazyVim, replacing both the vim-plug/coc config and LunarVim as of
  # the 2026-08-13 cutover. `n` and `lazyvim` are aliases for `nvim` now, so
  # everything lands on this one config and one plugin state directory.
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink configTree;
}
