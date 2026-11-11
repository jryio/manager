{
  config,
  lib,
  pkgs,
  host,
  ...
}:

# Always-on remote server role (opt-in per host via `server.enable`).
#
# Design (decided 2026-11-06 for GROT):
# - Remote access is SSH (key-only) + macOS Screen Sharing, reachable ONLY over
#   Tailscale. A pf anchor rejects those ports from any non-tailnet source and
#   on every physical interface, so LAN/Wi-Fi peers cannot reach them even by
#   spoofing a 100.64.0.0/10 source.
# - Tailscale stays the standalone Tailscale.app (user decision). It runs only
#   inside a login session, so FileVault + Tailscale.app means: after an
#   unplanned reboot the machine is offline until someone unlocks it locally
#   (or SSH-unlocks it from the same LAN; macOS 26+, apple_ssh_and_filevault(7)).
#   Planned reboots must use `server-reboot` (fdesetup authrestart), which
#   unlocks FileVault once and logs back in automatically.
# - Sleep is prevented twice: pmset (sleep 0 on AC and battery) and a
#   KeepAlive `caffeinate -i -s` daemon, so Amphetamine is optional rather than
#   load-bearing.
# - A user agent relaunches Tailscale.app and 1Password if they exit;
#   1Password must be running and unlocked for the SSH agent and `op`.
# - `server-doctor` verifies every invariant above; run it after any change.
# - Every machine change is recorded with `server-ledger <category> <msg>` in
#   an append-only (kernel `sappnd`), hash-chained log; see server-ledger.sh.
let
  cfg = config.server;

  # Ports that must only be reachable over Tailscale: SSH, Screen Sharing
  # (VNC 5900 + high-performance mode 5901-5902), Apple Remote Desktop (3283).
  pfAnchor = pkgs.writeText "pf-anchor-server" ''
    # Managed by modules/darwin/server.nix — remote-access ports are tailnet-only.
    ts4 = "100.64.0.0/10"
    ts6 = "fd7a:115c:a1e0::/48"
    svc_ports = "{ 22, 3283, 5900:5902 }"
    phys = "{ en0, en1, en2, en3, en4, en5, en6, en7, en8, en9, bridge0 }"

    # Never on a physical interface, regardless of claimed source.
    block return in quick on $phys proto { tcp, udp } from any to any port $svc_ports
    # Elsewhere (utun = Tailscale), only tailnet sources.
    block return in quick on ! lo0 inet proto { tcp, udp } from ! $ts4 to any port $svc_ports
    block return in quick on ! lo0 inet6 proto { tcp, udp } from ! $ts6 to any port $svc_ports
  '';

  # Mirrors Apple's stock /etc/pf.conf (which macOS updates may rewrite) and
  # appends our anchor, so we never edit the system file.
  pfConf = pkgs.writeText "pf-server.conf" ''
    scrub-anchor "com.apple/*"
    nat-anchor "com.apple/*"
    rdr-anchor "com.apple/*"
    dummynet-anchor "com.apple/*"
    anchor "com.apple/*"
    load anchor "com.apple" from "/etc/pf.anchors/com.apple"
    anchor "server"
    load anchor "server" from "${pfAnchor}"
  '';

  pfApply = pkgs.writeShellScript "server-pf-apply" ''
    set -u
    # Reload only when our anchor is missing (boot, or someone flushed pf), so
    # the periodic run never disturbs Apple's dynamic com.apple/* sub-anchors.
    if [ "''${1:-}" != "--force" ] && /sbin/pfctl -a server -sr 2>/dev/null | /usr/bin/grep -q block; then
      /sbin/pfctl -s info 2>/dev/null | /usr/bin/grep -q 'Status: Enabled' || /sbin/pfctl -e
      exit 0
    fi
    /sbin/pfctl -nf ${pfConf} || exit 1
    /sbin/pfctl -f ${pfConf}
    /sbin/pfctl -s info 2>/dev/null | /usr/bin/grep -q 'Status: Enabled' || /sbin/pfctl -e
  '';

  appWatchdog = pkgs.writeShellScript "server-app-watchdog" ''
    for app in Tailscale 1Password; do
      /usr/bin/pgrep -xq "$app" || /usr/bin/open -gja "$app"
    done
  '';

  serverReboot = pkgs.writeShellScriptBin "server-reboot" ''
    # Reboot without leaving FileVault locked: authrestart stores a one-time
    # unlock key, so the machine comes back logged in (Tailscale.app included).
    set -eu
    if ! /usr/bin/fdesetup supportsauthrestart >/dev/null; then
      echo "authrestart unsupported; refusing a reboot that would strand the server" >&2
      exit 1
    fi
    exec sudo /usr/bin/fdesetup authrestart -delayminutes 0
  '';

  serverDoctor = pkgs.writeShellScriptBin "server-doctor" (
    builtins.readFile ./assets/server/server-doctor.sh
  );

  serverLedger = pkgs.writeShellScriptBin "server-ledger" (
    builtins.readFile ./assets/server/server-ledger.sh
  );

  # Append-only change ledger (see assets/server/server-ledger.sh).
  ledgerPath = "${host.homeDirectory}/Library/Logs/server-ledger.log";
in
{
  options.server = {
    enable = lib.mkEnableOption "the always-on, Tailscale-only remote server role";

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SSH public keys allowed to log in as the primary user.";
    };
  };

  config = lib.mkIf cfg.enable {
    # ── SSH ────────────────────────────────────────────────────────────────
    services.openssh = {
      enable = true;
      extraConfig = ''
        PermitRootLogin no
        PasswordAuthentication no
        KbdInteractiveAuthentication no
        AuthenticationMethods publickey
        AllowUsers ${host.username}
        MaxAuthTries 4
        LoginGraceTime 30
        X11Forwarding no
        ClientAliveInterval 60
        ClientAliveCountMax 3
      '';
    };
    users.users.${host.username}.openssh.authorizedKeys.keys = cfg.authorizedKeys;

    # ── Power ──────────────────────────────────────────────────────────────
    power.restartAfterFreeze = true;

    launchd.daemons.server-caffeinate.serviceConfig = {
      ProgramArguments = [
        "/usr/bin/caffeinate"
        "-i"
        "-s"
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };

    # ── Firewall (pf) ──────────────────────────────────────────────────────
    launchd.daemons.server-pf.serviceConfig = {
      ProgramArguments = [ "${pfApply}" ];
      RunAtLoad = true;
      StartInterval = 300;
      StandardErrorPath = "/var/log/server-pf.log";
    };

    # ── Keep remote-access apps alive in the login session ─────────────────
    launchd.user.agents.server-app-watchdog.serviceConfig = {
      ProgramArguments = [ "${appWatchdog}" ];
      RunAtLoad = true;
      StartInterval = 120;
    };

    environment.systemPackages = [
      serverDoctor
      serverLedger
      serverReboot
    ];

    system.activationScripts.postActivation.text = lib.mkAfter ''
      echo "configuring server role (power, screen sharing, pf)..." >&2

      # Never sleep the system; let only the display sleep. womp/tcpkeepalive
      # keep the network stack reachable; standby/powernap are moot at sleep 0.
      /usr/bin/pmset -c sleep 0 disksleep 0 displaysleep 15 womp 1 tcpkeepalive 1 ttyskeepawake 1 standby 0
      /usr/bin/pmset -b sleep 0 disksleep 0 displaysleep 5 tcpkeepalive 1 ttyskeepawake 1 standby 0

      # Screen Sharing (Apple's VNC server). Idempotent.
      /bin/launchctl enable system/com.apple.screensharing
      /bin/launchctl print system/com.apple.screensharing >/dev/null 2>&1 \
        || /bin/launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.screensharing.plist \
        || echo "warning: could not bootstrap Screen Sharing; enable it in System Settings > General > Sharing" >&2

      ${pfApply} --force || echo "warning: pf ruleset failed to load; remote ports are NOT tailnet-restricted" >&2

      # Append-only ledger: user-writable, but `sappnd` (only root can clear)
      # forbids anything except appends. Never cleared here.
      if [ ! -e "${ledgerPath}" ]; then
        /usr/bin/install -d -o ${host.username} -g staff "$(dirname "${ledgerPath}")"
        /usr/bin/install -m 0644 -o ${host.username} -g staff /dev/null "${ledgerPath}"
        printf '# server-ledger: append-only (sappnd), hash-chained. Verify: server-ledger --verify\n' >> "${ledgerPath}"
      fi
      /usr/bin/chflags sappnd "${ledgerPath}"
    '';
  };
}
