{ config, lib, pkgs, ... }:

{
  # Home Manager 25.11 has no first-class `programs.vale` module.
  # Install the binary and place config declaratively instead.
  home.packages = [ pkgs.vale ];

  # `StylesPath = ~/.config/vale` in vale.ini, so the entire vendored
  # tree (vale.ini + proselint/ + write-good/ + Vocab/) lives there.
  xdg.configFile."vale" = {
    source = ./assets/vale;
    recursive = true;
  };

  # Vale also reads `~/.vale.ini` by default; point it at the same source
  # of truth so a config-less invocation still resolves StylesPath.
  home.file.".vale.ini".source = ./assets/vale/vale.ini;
}
