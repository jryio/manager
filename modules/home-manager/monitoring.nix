{ config, lib, pkgs, ... }:

{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "Default";
      theme_background = false;
      vim_keys = true;
      rounded_corners = true;
      update_ms = 1500;
    };
  };

  programs.htop = {
    enable = true;
    settings = {
      hide_kernel_threads = true;
      hide_userland_threads = true;
      tree_view = true;
      show_program_path = false;
      highlight_base_name = true;
      header_margin = true;
    };
  };
}
