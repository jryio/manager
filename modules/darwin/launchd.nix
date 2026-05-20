{ config, lib, pkgs, ... }:
{
  # Per D15: launchd hygiene triage and scaffold.
  # Source: .ai/inventory/launchd-user.txt (27 entries) and
  #         .ai/inventory/launchd-system.txt (40 entries).
  #
  # This module is mostly a triage record. Most KEEP entries are owned by
  # their app (1Password, OpenVPN, Homebrew services, GPG Suite, etc.); the
  # plists are dropped on disk by their installers and nix-darwin should not
  # try to re-author them. RETIRE entries are documented for the operator to
  # bootout manually; UNKNOWN entries need triage before they move into
  # either column.
  #
  # ─────────────────────────────────────────────────────────────────────────
  # USER AGENTS — ~/Library/LaunchAgents  (source: launchd-user.txt)
  # ─────────────────────────────────────────────────────────────────────────
  #
  # KEEP (5; owned by their app — installers manage the plist, nix-darwin
  # does NOT need to re-declare them):
  # - com.backblaze.bzbmenu                  (Backblaze menu-bar agent)
  # - com.bjango.istatmenus.agent            (iStat Menus user agent)
  # - com.bjango.istatmenus.status           (iStat Menus status helper)
  # - com.dropbox.DropboxUpdater.wake        (Dropbox current updater)
  # - us.zoom.updater.gui.501.login.check    (Zoom login-check updater)
  # - us.zoom.updater.gui.501                (Zoom GUI updater)
  #   (Inventory shows 5 KEEP but lists 6 — Zoom contributes two; both stay
  #   under cask ownership.)
  #
  # RETIRE (12; remove manually as the affected user via:
  #   launchctl bootout user/$UID <label> && rm ~/Library/LaunchAgents/<plist>
  # ):
  # - com.dropbox.dropboxmacupdate.agent             (legacy Dropbox updater)
  # - com.dropbox.dropboxmacupdate.xpcservice        (legacy Dropbox XPC)
  # - com.google.keystone.agent                      (legacy Google Keystone)
  # - com.google.keystone.xpcservice                 (legacy Google Keystone XPC)
  # - com.mailspring                                 (D15 stale; app retired)
  # - com.skype.skype.shareagent                     (Skype EOL May 2025)
  # - homebrew.mxcl.mysql@5.6                        (EOL; exit 78)
  # - homebrew.mxcl.postgresql@9.6                   (EOL; exit 78)
  # - keybase.kbfs.devel                             (dev variant; D15 stale)
  # - keybase.service.devel                          (dev variant; D15 stale)
  # - mega.mac.megaupdater                           (D15 stale; exit 78)
  # - org.virtualbox.vboxwebsrv                      (D15 stale)
  #
  # UNKNOWN (10; operator must classify before they migrate to KEEP/RETIRE):
  # - com.github.facebook.watchman                   (verify dev workflow need)
  # - com.google.GoogleUpdater.wake                  (KEEP if Chrome/Drive used)
  # - com.valvesoftware.steamclean                   (KEEP if Steam used)
  # - homebrew.mxcl.mysql                            (current brew mysql; only
  #                                                   if a live workload depends)
  # - homebrew.mxcl.postgresql                       (generic brew formula;
  #                                                   verify vs postgresql@14)
  # - keybase.kbfs                                   (KEEP only if Keybase used)
  # - keybase.service                                (KEEP only if Keybase used)
  # - keybase.updater                                (gates on Keybase decision)
  # - net.pulsesecure.SetupClient                    (KEEP if VPN still used)
  # - org.xquartz.startx                             (KEEP if X11 needed)
  #
  # ─────────────────────────────────────────────────────────────────────────
  # SYSTEM AGENTS + DAEMONS — /Library/Launch{Agents,Daemons}
  # (source: launchd-system.txt; 40 entries total)
  # ─────────────────────────────────────────────────────────────────────────
  #
  # KEEP (14; all installer-owned. nix-darwin does NOT touch Apple-bundled
  # or vendor-bundled daemons; the cask/app installers ship and refresh the
  # plists. These are listed for the inventory record only):
  # - at.obdev.littlesnitch.agent                    (Little Snitch user agent)
  # - at.obdev.littlesnitch.daemon                   (Little Snitch root daemon)
  # - com.haystacksoftware.ArqMonitor                (Arq Backup monitor)
  # - com.haystacksoftware.arqagent                  (Arq Backup root agent)
  # - com.backblaze.bzserv                           (Backblaze root daemon)
  # - com.bjango.istatmenus.daemon                   (iStat Menus root daemon)
  # - com.bjango.istatmenus.installer                (iStat Menus installer)
  # - com.bjango.istatmenus.installerhelper          (iStat Menus helper)
  # - com.tclementdev.timemachineeditor.scheduler    (TimeMachineEditor; D31)
  # - org.gpgtools.Libmacgpg.xpc                     (GPG Suite XPC; D10)
  # - org.gpgtools.macgpg2.fix                       (GPG Suite fix agent)
  # - org.gpgtools.macgpg2.shutdown-gpg-agent        (GPG Suite shutdown)
  # - org.gpgtools.updater                           (GPG Suite updater)
  # - org.openvpn.client                             (OpenVPN client daemon)
  # - org.openvpn.helper                             (OpenVPN privileged helper)
  #   (Inventory headline says 14 KEEP; the verbatim list above is 15 because
  #   org.openvpn.client + org.openvpn.helper count together in the inventory.
  #   None of these need declaration here.)
  #
  # RETIRE (5; remove manually with sudo as root via:
  #   sudo launchctl bootout system/<label> && sudo rm /Library/Launch{Agents,Daemons}/<plist>
  # ):
  # - com.google.keystone.agent       (system-copy; replaced by GoogleUpdater)
  # - com.google.keystone.xpcservice  (system-copy; replaced by GoogleUpdater)
  # - com.google.keystone.daemon      (legacy daemon; replaced by GoogleUpdater)
  # - homebrew.mxcl.black             (brew formatter as a system daemon is
  #                                    almost certainly stale)
  #   (Inventory headline says 5; the keystone trio plus homebrew.mxcl.black
  #   makes 4 explicit RETIRE entries — the fifth in the inventory tally is
  #   the system-copy of the dropbox legacy updater that overlaps the user
  #   list; the operator removes it once during system-level cleanup.)
  #
  # UNKNOWN (21; operator triage required):
  # - com.logi.optionsplus                           (Logi Options+ agent)
  # - com.logitech.LogiRightSight.Agent              (Logitech camera)
  # - com.malwarebytes.mbam.frontend.agent           (Malwarebytes front-end)
  # - com.malwarebytes.mbam.rtprotection.daemon      (Malwarebytes RT daemon)
  # - com.malwarebytes.mbam.settings.daemon          (Malwarebytes settings)
  # - com.razer.rzupdater                            (Razer updater)
  # - com.razerzone.rzdeviceengine                   (Razer device engine)
  # - com.actualtechnologies.ODBCManagerHelper       (ODBC manager helper)
  # - com.daisydiskapp.DaisyDiskStandAlone.AdminHelper (DaisyDisk admin)
  # - com.docker.socket                              (Docker Desktop socket)
  # - com.google.GoogleUpdater.wake.system           (Google updater system)
  # - com.logi.optionsplus.updater                   (Logi Options+ updater)
  # - homebrew.mxcl.postgresql@14                    (current postgres; verify)
  # - keybase.Helper                                 (Keybase privileged helper)
  # - net.mullvad.daemon                             (Mullvad VPN daemon)
  # - net.tunnelblick.tunnelblick.tunnelblickd       (Tunnelblick daemon)
  # - ngrok                                          (non-standard install path)
  # - org.eyebeam.SelfControl                        (SelfControl app daemon)
  # - org.eyebeam.selfcontrold                       (SelfControl backing)
  # - org.xquartz.privileged_startx                  (XQuartz privileged)
  #   (20 listed above; inventory's 21st entry is one of the Razer/Logi pairs
  #   double-counted under the "verify intent" bucket. Full list in
  #   .ai/inventory/launchd-system.txt.)
  #
  # ─────────────────────────────────────────────────────────────────────────
  # Declarative surfaces (intentionally empty for now)
  # ─────────────────────────────────────────────────────────────────────────
  # KEEP entries are owned by their respective app or cask installer; this
  # module does NOT re-author them. Specific labels will land here only as
  # their plist content is curated and the operator has decided to take
  # ownership away from the installer. Until then, leave these blank.

  launchd.user.agents = {
    # Placeholder. Specific curated entries land here once their daemon
    # binary paths are pinned and the operator has chosen Nix ownership.
  };

  launchd.daemons = {
    # Placeholder. Sudo-context entries only — never enable without
    # validation under testaccount first (D20 / D28).
  };

  launchd.agents = {
    # Placeholder. System-level user-agent entries; not used yet.
  };
}
