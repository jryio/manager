{ config, lib, pkgs, ... }:
let
  zedDir = "${config.home.homeDirectory}/.config/zed";
  seeds = [ "settings.json" "keymap.json" "tasks.json" ];
  copyOnceLines = lib.concatStringsSep "\n" (map (file: ''
    if [ ! -e "${zedDir}/${file}" ] && [ -f "${./assets/zed}/${file}" ]; then
      mkdir -p "${zedDir}"
      cp "${./assets/zed}/${file}" "${zedDir}/${file}"
    fi
  '') seeds);
in
{
  home.activation.zedSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${copyOnceLines}
  '';
}
