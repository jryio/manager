{ config, lib, pkgs, ... }:

# Vendored user fonts (D11). Physically copies every file in ./assets/fonts/
# into ~/Library/Fonts/<filename> via an activation script. macOS fontd does
# not reliably register fonts that live as symlinks into /nix/store, so the
# previous home.file (symlink) approach left Font Book empty even though the
# files resolved. A manifest at ~/.local/state/manager/fonts.manifest tracks
# what we own so files removed from the repo also disappear from
# ~/Library/Fonts/ on the next switch.

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

  manifest = pkgs.writeText "manager-fonts.manifest"
    (lib.concatStringsSep "\n" fontNames + "\n");
in
{
  home.activation.vendoredFonts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu
    target="$HOME/Library/Fonts"
    state="$HOME/.local/state/manager"
    mkdir -p "$target" "$state"

    new_manifest="${manifest}"
    old_manifest="$state/fonts.manifest"
    changed=0

    if [ -f "$old_manifest" ]; then
      while IFS= read -r name; do
        [ -z "$name" ] && continue
        if ! grep -Fxq -- "$name" "$new_manifest"; then
          rm -f "$target/$name"
          changed=1
        fi
      done < "$old_manifest"
    fi

    while IFS= read -r name; do
      [ -z "$name" ] && continue
      src="${assetsDir}/$name"
      dst="$target/$name"
      if [ -L "$dst" ] || [ ! -e "$dst" ] || ! cmp -s "$src" "$dst"; then
        rm -f "$dst"
        install -m 0644 "$src" "$dst"
        changed=1
      fi
    done < "$new_manifest"

    install -m 0644 "$new_manifest" "$old_manifest"

    # Nudge fontd to rescan when we added/removed/replaced anything. fontd is
    # per-user and respawns on demand, so this is cheap and safe.
    if [ "$changed" = 1 ]; then
      /usr/bin/killall -u "$USER" fontd 2>/dev/null || true
    fi
  '';
}
