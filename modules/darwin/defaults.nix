{ config, lib, pkgs, ... }:
{
  # Per D16 / manager-4.17: only intentionally-set values from
  # .ai/inventory/defaults-intentional.md are declared here, not a snapshot of
  # every key macOS rewrites at runtime. D27 explicitly defers the firewall
  # (`com.apple.alf`) and PAM/Touch ID sudo — neither appears below.
  #
  # The 13 "obvious intentional" settings called out in the inventory's
  # "Notes for Topic 07" section are encoded here verbatim. The 4 caveat
  # categories are explicitly left as operator-managed.

  system.defaults = {

    NSGlobalDomain = {
      # Dark mode (inventory: AppleInterfaceStyle = Dark).
      AppleInterfaceStyle = "Dark";

      # 24-hour clock everywhere (inventory: AppleICUForce24HourTime = 1).
      AppleICUForce24HourTime = true;

      # Show all file extensions (inventory: AppleShowAllExtensions = 1).
      AppleShowAllExtensions = true;

      # Fast keyboard repeat (inventory: InitialKeyRepeat = 15, KeyRepeat = 2;
      # well below macOS defaults of 25 / 6).
      InitialKeyRepeat = 15;
      KeyRepeat = 2;

      # Smart-substitution off for code/Markdown writing (inventory:
      # NSAutomaticQuoteSubstitutionEnabled = 0, NSAutomaticDashSubstitutionEnabled = 0).
      # Spelling correction and capitalization stay on per the inventory.
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;

      # NSUserDictionaryReplacementItems (21 text-expansion entries) is
      # operator-managed, not declarative. Inventory caveat: managing a
      # personal shortcut list in Nix is high-friction; the operator edits
      # via System Settings → Keyboard → Text Replacements.
    };

    dock = {
      # Auto-hide dock (inventory: autohide = 1).
      autohide = true;

      # Small tile size (inventory: tilesize = 52). Encoded as int.
      tilesize = 52;

      # No "Recents" tray (inventory: show-recents = 0).
      show-recents = false;

      # No bouncing launch animation (inventory: launchanim = 0).
      launchanim = false;

      # Scale (not genie) minimize effect (inventory: mineffect = scale).
      mineffect = "scale";

      # Bottom-right hot corner explicitly disabled (inventory:
      # wvous-br-corner = 1, which is the "no-op" action; wvous-br-modifier = 0).
      wvous-br-corner = 1;
      wvous-br-modifier = 0;

      # persistent-apps is operator-managed, not declarative. The inventory
      # caveat is clear: the dock contents change every time the user reorders,
      # so declaring it would clobber that. lib.mkDefault [] would force-empty
      # the dock on activation; we deliberately do NOT set it.
    };

    finder = {
      # Show all extensions in Finder (inventory: AppleShowAllExtensions = 1
      # on NSGlobalDomain implies the finder mirror; inventory also confirms
      # the dotfile-surfacing partner AppleShowAllFiles = TRUE).
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;

      # Clean desktop policy (inventory: CreateDesktop = FALSE,
      # ShowHardDrivesOnDesktop = 0, ShowExternalHardDrivesOnDesktop = 0,
      # ShowMountedServersOnDesktop = 0, ShowRemovableMediaOnDesktop = 0).
      CreateDesktop = false;
      ShowHardDrivesOnDesktop = false;
      ShowExternalHardDrivesOnDesktop = false;
      ShowMountedServersOnDesktop = false;
      ShowRemovableMediaOnDesktop = false;

      # New Finder windows open at $HOME (inventory: NewWindowTarget = PfHm,
      # NewWindowTargetPath = file:///Users/case/).
      NewWindowTarget = "PfHm";

      # Column view + folders-first sort (inventory: FXPreferredViewStyle = clmv,
      # _FXSortFoldersFirst = 1).
      FXPreferredViewStyle = "clmv";
      _FXSortFoldersFirst = true;

      # Pathbar on (inventory: ShowPathbar = 1).
      ShowPathbar = true;
    };

    menuExtraClock = {
      # Show date and day-of-week in menu-bar clock (inventory: ShowDate = 1,
      # ShowDayOfWeek = 1). ShowDate uses macOS semantics: 0=when-space-allows,
      # 1=always, 2=never. The raw value is 1 = always.
      ShowDate = 1;
      ShowDayOfWeek = true;
      IsAnalog = false;
      Show24Hour = true;
    };

    screencapture = {
      # Screenshots redirected to Dropbox (inventory: location =
      # /Users/CASE/Dropbox/media/screenshots). Path is the literal current
      # value; uses a hard-coded prefix because system.defaults.screencapture
      # is system-level and has no $HOME expansion.
      location = "/Users/CASE/Dropbox/media/screenshots";

      # show-thumbnail = 0 (inventory: thumbnail preview off).
      show-thumbnail = false;

      # style = display (inventory: last-used capture mode persisted).
      type = "png";
    };

    SoftwareUpdate = {
      # Auto-update pinned to macOS 15.x major (inventory:
      # AutoUpdateMajorOSVersion = 15). The nix-darwin module does not expose
      # AutoUpdateMajorOSVersion directly; flip auto-installs off so OS
      # upgrades stay deliberate per the inventory's intent. The pinned
      # major-version key is recorded via CustomUserPreferences below.
      AutomaticallyInstallMacOSUpdates = false;
    };

    # com.apple.alf intentionally skipped per D27 (firewall deferred).
    # PAM / Touch ID sudo intentionally skipped per D27.

    CustomUserPreferences = {
      # Pinned macOS major-version line so software-update offers 15.x patches
      # without prompting for 26.x upgrades (inventory:
      # com.apple.SoftwareUpdate.AutoUpdateMajorOSVersion = 15).
      "com.apple.SoftwareUpdate" = {
        AutoUpdateMajorOSVersion = 15;
      };
    };
  };

  # Operator-managed caveats from the inventory (NOT declared above):
  #
  # 1. NSGlobalDomain.NSUserDictionaryReplacementItems — 21 text-expansion
  #    shortcuts. Personal, high-churn, edited via System Settings.
  # 2. com.apple.dock persistent-apps / persistent-others — dock layout is
  #    reordered frequently; declaring it would clobber operator state on
  #    every activation. (See dock block above: tilesize/autohide/etc. are
  #    declared but the app list is not.)
  # 3. com.apple.spaces app-bindings — references several long-uninstalled
  #    apps (Things, Quiver, Cloudmagic Mail, Nylas, Todoist, Keybase).
  #    Drift residue, not policy. Operator triages manually.
  # 4. NSGlobalDomain.com.apple.mouse.scaling (1.5) and trackpad.scaling
  #    (0.875) — macOS rewrites these when devices change; declaring them
  #    would fight the runtime. Operator keeps current values manually.
  #
  # Out of scope per D27:
  # - Firewall (com.apple.alf)
  # - Touch ID sudo (PAM stack)
  # - 26 disabled symbolichotkeys bindings (the inventory flags this as a
  #   separate follow-up; not encoded in this pass).
  # - LaunchServices URL-scheme / UTI handler map (no first-class
  #   nix-darwin module; large surface; left to runtime).
  # - HIToolbox input-source layout (Hebrew enabled; no first-class module).
  # - controlcenter menu-bar item positions (runtime state).
}
