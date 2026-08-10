{ config, lib, pkgs, ... }:

# Declarative /etc/hosts management (supersedes D26's mechanism).
#
# nix-darwin 25.11 does NOT expose networking.hosts / networking.extraHosts
# (verified against /nix/store/.../nix-darwin/modules/networking/default.nix).
# We manage a delimited block inside /etc/hosts via system.activationScripts.
# Source of truth: .ai/inventory/etc-hosts-blocks.txt — every `0.0.0.0 host`
# entry from that file becomes a managed line. Apple-default header (lines 1-9
# of /etc/hosts: localhost, broadcasthost, ::1) and any operator-added entries
# outside the BEGIN/END markers are preserved across rebuilds.

let
  blockMarker = {
    begin = "# BEGIN nix-darwin managed block (modules/darwin/hosts.nix)";
    end   = "# END nix-darwin managed block";
  };

  rawHosts = builtins.readFile ../../.ai/inventory/etc-hosts-blocks.txt;

  blockedLines = lib.filter
    (line: lib.hasPrefix "0.0.0.0 " line || lib.hasPrefix "0.0.0.0\t" line)
    (lib.splitString "\n" rawHosts);

  blockedHosts = map
    (line: lib.last (lib.filter (s: s != "")
      (lib.splitString " " (lib.replaceStrings [ "\t" ] [ " " ] line))))
    blockedLines;

  # Each host gets both an A (0.0.0.0) and AAAA (::) pin — an IPv4-only entry
  # leaks on IPv6 networks because the AAAA lookup falls through to DNS.
  # Trailing newline is load-bearing: without it /etc/hosts ends mid-line and
  # anything that later appends (Docker Desktop does) glues onto the END marker.
  managedBlockText = lib.concatStringsSep "\n" (
    [ blockMarker.begin ]
    ++ lib.concatMap (h: [ "0.0.0.0 ${h}" ":: ${h}" ]) blockedHosts
    ++ [ blockMarker.end ]
  ) + "\n";

  managedBlock = pkgs.writeText "etc-hosts-managed-block" managedBlockText;
in
{
  # nix-darwin runs only its named stages (preActivation, checks, createRun,
  # extraActivation, groups, users, applications, pam, patches, etc, defaults,
  # userDefaults, launchd, userLaunchd, nix-daemon, time, networking, power,
  # keyboard, fonts, nvram, homebrew, postActivation). Custom stage names are
  # silently ignored. Use postActivation so the block is written AFTER
  # nix-darwin's own networking script (which restores /etc/hosts from
  # `.before-nix-darwin` if present).
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "syncing /etc/hosts managed block..." >&2

    if [ ! -e /etc/hosts.before-managed-block ]; then
      cp /etc/hosts /etc/hosts.before-managed-block
    fi

    # Strip both the previous managed block (between markers) AND any bare
    # `0.0.0.0 host` lines outside the markers. The inventory is the sole
    # source of truth for the blocklist; operator additions belong there,
    # not in /etc/hosts directly. Non-blocklist content (Apple-default
    # header, operator IP overrides, comments) is preserved verbatim.
    awk '
      /^# BEGIN nix-darwin managed block/ { skip = 1; next }
      /^# END nix-darwin managed block/   { skip = 0; next }
      skip                                  { next }
      /^0\.0\.0\.0[[:space:]]/              { next }
      /^::[[:space:]]/                      { next }
      { print }
    ' /etc/hosts > /etc/hosts.tmp

    cat ${managedBlock} >> /etc/hosts.tmp
    mv /etc/hosts.tmp /etc/hosts
  '';
}
