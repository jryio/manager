{ config, lib, ... }:
let
  home = config.home.homeDirectory;

  # Dock tiles as plist-XML fragments for `defaults write ... -array`.
  # _CFURLStringType 0 = plain filesystem path.
  appTile = path: ''<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>${path}</string><key>_CFURLStringType</key><integer>0</integer></dict></dict><key>tile-type</key><string>file-tile</string></dict>'';
  spacerTile = ''<dict><key>tile-data</key><dict/><key>tile-type</key><string>spacer-tile</string></dict>'';
  # arrangement 2 = sort by date added, displayas 1 = folder, showas 1 = fan.
  dirTile = path: ''<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>${path}</string><key>_CFURLStringType</key><integer>0</integer></dict><key>arrangement</key><integer>2</integer><key>displayas</key><integer>1</integer><key>showas</key><integer>1</integer></dict><key>tile-type</key><string>directory-tile</string></dict>'';

  # Snapshot of AVA's curated dock, 2026-07-28. Apps that install later in the
  # bootstrap (casks, MAS, manual) show as placeholder icons until present.
  persistentApps = [
    (appTile "/Applications/Ghostty.app")
    (appTile "/Applications/Zed.app")
    (appTile "/Applications/Conductor.app")
    spacerTile
    (appTile "/Applications/Firefox.app")
    (appTile "/Applications/Google Chrome.app")
    spacerTile
    (appTile "/Applications/TickTick.app")
    (appTile "/Applications/Craft.app")
    spacerTile
    (appTile "/Applications/Claude.app")
    (appTile "/Applications/MacWhisper.app")
    spacerTile
    (appTile "/Applications/Notion.app")
    (appTile "/Applications/Notion Calendar.app")
    (appTile "${home}/Applications/Mercury.app")
    spacerTile
    (appTile "/System/Applications/Messages.app")
    (appTile "/Applications/HEY.app")
    (appTile "/Applications/Signal.app")
    (appTile "/Applications/Slack.app")
    (appTile "/Applications/Zulip.app")
    (appTile "/Applications/Spotify.app")
    spacerTile
    (appTile "/System/Applications/System Settings.app")
    spacerTile
  ];

  persistentOthers = [ (dirTile "${home}/Downloads") ];
in
{
  # Seed-once dock layout. The dock app list is reordered often by hand, so a
  # declarative system.defaults.dock.persistent-apps would clobber that on
  # every switch (see defaults.nix caveats). Instead this writes the layout
  # exactly once per machine, tracked by a marker file; later manual reorders
  # are never touched. Delete the marker and re-switch to re-seed.
  home.activation.dockSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dockSeedMarker="$HOME/.local/state/manager/dock.seeded"
    if [ ! -f "$dockSeedMarker" ]; then
      echo "seeding dock layout (once)..."
      run /usr/bin/defaults write com.apple.dock persistent-apps -array ${lib.concatMapStringsSep " " lib.escapeShellArg persistentApps}
      run /usr/bin/defaults write com.apple.dock persistent-others -array ${lib.concatMapStringsSep " " lib.escapeShellArg persistentOthers}
      run mkdir -p "$(dirname "$dockSeedMarker")"
      run touch "$dockSeedMarker"
      run /usr/bin/killall Dock 2>/dev/null || true
    fi
  '';
}
