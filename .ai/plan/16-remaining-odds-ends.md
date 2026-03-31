# 16 Remaining Odds & Ends

Topic source: `OVERVIEW.md` line 500
Sub-agent status: completed
Result type: per-topic research memo for nix-darwin and Home Manager

## Summary

This topic is the miscellaneous tail of the migration plan: keyboard shortcuts,
accessibility, input sources, default apps, notifications, Spotlight, power settings,
wallpaper, Time Machine, and other runtime or hardware-driven preferences that do not fit
neatly into the earlier sections.

## Current State

The explorer found almost no direct repo-backed coverage for these settings. The only clear
match was `timemachineeditor` as a package in all Brewfile variants. The installer runs
`shell/macos.sh`, but that script only covers Finder and screencapture defaults rather than
the section-16 items. No matching dotfiles were found for keyboard shortcuts, accessibility,
input sources, per-app notifications, default-app rules, Spotlight indexing, power or sleep
policy, wallpaper, printers, Bluetooth, Apple ID, iCloud, Focus, or Screen Time.

## nix-darwin Surface

The explorer confirmed useful nix-darwin coverage for the declarable subset:
`system.defaults.CustomUserPreferences`,
`system.defaults.NSGlobalDomain.AppleKeyboardUIMode`, `system.defaults.universalaccess.*`,
`power.restartAfterFreeze`, `power.restartAfterPowerFailure`, `power.sleep.*`, and
`system.defaults.LaunchServices.LSQuarantine`. It also found that the exact plan path
`system.defaults.NSGlobalDomain.NSUserKeyEquivalents` is not documented as a first-class
option in the local docs; the practical route appears to be `CustomUserPreferences` with
`NSGlobalDomain`.

## Home Manager Surface

Home Manager surfaced only one strong direct match here: macOS wallpaper via
`programs.desktoppr.*`. Beyond that, the local Home Manager docs did not expose strong
matches for the rest of the section-16 items. For most of this topic, Home Manager is
therefore either a minor helper or simply out of scope.

## Recommended Split

Use nix-darwin for the declarable OS preference subset that survives after Topic 7,
especially keyboard navigation, accessibility, quarantine, and power settings. Use Home
Manager only when a clearly user-scoped app or wallpaper setting already has a module
surface. Keep hardware, approval-gated, and account-driven state explicitly manual.

## Migration Notes

Keep Time Machine manual or package-based unless `timemachineeditor` still matters. Move
keyboard navigation, accessibility, and sleep or power settings into nix-darwin. Use
`CustomUserPreferences` for odd plist-backed settings that lack typed options. Treat
default-app associations, per-app notifications, and Spotlight tweaks as best-effort only.
If wallpaper should become declarative, use Home Manager `programs.desktoppr`.

## Supporting References

- `~/dotfiles/Brewfile` and `~/dotfiles/brewfiles/*.brewfile` for `timemachineeditor`
- `~/dotfiles/install-configs/default.conf.yaml` and `~/dotfiles/shell/macos.sh`
- `.ai/docs/nix-darwin-options.md` for `system.defaults.CustomUserPreferences`
- `.ai/docs/nix-darwin-options.md` for `system.defaults.universalaccess.*`, `power.sleep.*`,
  and `system.defaults.LaunchServices.LSQuarantine`
- `.ai/docs/home-manager-configuration-options.md` for `programs.desktoppr.*`
- `.ai/docs/home-manager-configuration-options.md` for limited Darwin defaults support
- `.ai/plan/OVERVIEW.md` lines 500 to 560
- Manual checklist items later in `OVERVIEW.md` remain part of the effective outcome for
  this topic

## Notes

The explorer result confirms that Topic 16 is mostly a boundary document, not a large body
of existing config waiting to be translated. The important output is a clear line between
declarable preferences, best-effort preferences, and truly manual system state.
