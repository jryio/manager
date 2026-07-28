{ config, lib, pkgs, vars, ... }:
{
  # Per D16: only intentionally-set values from
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

      # Trackpad tracking speed (live: com.apple.trackpad.scaling = 0.875).
      # macOS may rewrite this when pointing devices change; each switch
      # re-asserts the declared value.
      "com.apple.trackpad.scaling" = 0.875;

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
      # wvous-br-corner = 1, which is the "no-op" action). nix-darwin 25.11
      # does not expose wvous-br-modifier; the corner value alone is enough
      # to neutralize the action.
      wvous-br-corner = 1;

      # persistent-apps is NOT declared here: the dock is reordered by hand
      # often, and a declared list would clobber that on every switch. Fresh
      # machines instead get a one-time layout seed from
      # modules/home-manager/dock.nix (marker-guarded, never re-applied).
    };

    trackpad = {
      # Tap to click + three-finger drag (live: com.apple.AppleMultitouchTrackpad
      # Clicking = 1, TrackpadThreeFingerDrag = 1).
      Clicking = true;
      TrackpadThreeFingerDrag = true;
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
      NewWindowTarget = "Home";

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
      # /Users/CASE/Dropbox/media/screenshots). system.defaults.screencapture
      # is system-level and has no $HOME expansion, so the path is rendered
      # from vars.paths.screenshots at evaluation time.
      location = vars.paths.screenshots;

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

      # Mouse tracking speed (live: 1.5). nix-darwin has no first-class option
      # for com.apple.mouse.scaling, so it is written to the global domain here.
      NSGlobalDomain = {
        "com.apple.mouse.scaling" = 1.5;
      };
    };
  };

  # Operator-managed caveats from the inventory (NOT declared above):
  #
  # 1. NSGlobalDomain.NSUserDictionaryReplacementItems — 21 text-expansion
  #    shortcuts. Personal, high-churn, edited via System Settings.
  # 2. com.apple.dock persistent-apps / persistent-others — ongoing dock
  #    order is operator-managed (reordered frequently); fresh machines get a
  #    one-time seed from modules/home-manager/dock.nix instead of a declared
  #    list. (See dock block above: tilesize/autohide/etc. are declared.)
  # 3. com.apple.spaces app-bindings — references several long-uninstalled
  #    apps (Things, Quiver, Cloudmagic Mail, Nylas, Todoist, Keybase).
  #    Drift residue, not policy. Operator triages manually.
  # (mouse.scaling / trackpad.scaling, formerly caveat 4, are now declared
  # above: switches re-assert them if macOS rewrites the values.)
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
