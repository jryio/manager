{ config, lib, pkgs, ... }:

# Vendored user fonts (D11 / ADR 6). Installs every file in ./assets/fonts/
# into ~/Library/Fonts/<filename> via home.file. System-supplied faces
# (/Library/Fonts, /System/Library/Fonts) are filtered out at vendor time,
# not here, so anything present in the assets directory is intentional.

let
  assetsDir = ./assets/fonts;

  isFont = name:
    let lower = lib.toLower name; in
    lib.hasSuffix ".otf" lower
      || lib.hasSuffix ".ttf" lower
      || lib.hasSuffix ".ttc" lower
      || lib.hasSuffix ".woff" lower
      || lib.hasSuffix ".woff2" lower;

  fontNames = lib.filter isFont (builtins.attrNames (builtins.readDir assetsDir));
in
{
  home.file = lib.listToAttrs (map (name: {
    name = "Library/Fonts/${name}";
    value = { source = assetsDir + "/${name}"; };
  }) fontNames);
}
