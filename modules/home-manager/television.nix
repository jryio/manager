{ config, lib, pkgs, ... }:

{
  programs.television = {
    enable = true;
    settings = {
      ui = {
        theme = "default";
      };
    };
  };
}
