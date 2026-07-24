{ config, lib, pkgs, ... }:
let
  zedDir = "${config.home.homeDirectory}/.config/zed";
  seeds = [ "settings.json" "keymap.json" "tasks.json" ];
  seedLines = lib.concatStringsSep "\n" (map (file: ''
    target="${zedDir}/${file}"
    source="${./assets/zed}/${file}"
    if [ -L "$target" ]; then
      link_dest=$(readlink "$target")
      case "$link_dest" in
        "$HOME/dotfiles"/*|/Users/*/dotfiles/*) rm -f "$target" ;;
        *) [ ! -e "$target" ] && rm -f "$target" ;;
      esac
    fi
    if [ -f "$target" ] && grep -q "To see all of Zed's default settings" "$target"; then
      rm -f "$target"
    fi
    if [ ! -e "$target" ] && [ -f "$source" ]; then
      mkdir -p "${zedDir}"
      install -m 0644 "$source" "$target"
    fi
  '') seeds);
in
{
  home.activation.zedSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${seedLines}
  '';
}
