{ lib, host, ... }:
let
  # Extracted from AVA's directory-services record (dscl JPEGPhoto), 2026-07-28.
  picture = ./assets/user-picture.jpg;
in
{
  # Seed-once account picture. macOS stores the login/System Settings avatar in
  # the user record's JPEGPhoto attribute; there is no nix-darwin option for it.
  # dsimport is the supported write path. Only runs when the record has no
  # JPEGPhoto yet, so a photo chosen later by hand is never clobbered.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    if ! /usr/bin/dscl . -read "/Users/${host.username}" JPEGPhoto >/dev/null 2>&1; then
      echo "seeding account picture for ${host.username}..." >&2
      userPictureImport=$(mktemp)
      printf '0x0A 0x5C 0x3A 0x2C dsRecTypeStandard:Users 2 dsAttrTypeStandard:RecordName externalbinary:dsAttrTypeStandard:JPEGPhoto\n%s:%s\n' \
        "${host.username}" "${picture}" > "$userPictureImport"
      /usr/bin/dsimport "$userPictureImport" /Local/Default M
      rm -f "$userPictureImport"
    fi
  '';
}
