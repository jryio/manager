# 07 macOS System Defaults

Topic source: `OVERVIEW.md` line 213
Sub-agent status: completed
Result type: per-topic research memo for nix-darwin and Home Manager

## Summary

This topic is the `defaults write` surface: Finder, Dock, screenshots, NSGlobalDomain, and
other typed macOS preference keys. It is one of the places where nix-darwin has broad typed
coverage and where the current repo only captures a tiny subset of the intended state.

## Current State

The tracked repo currently encodes only four settings in `~/dotfiles/shell/macos.sh`: show
hidden files, switch Finder to column view, hide desktop icons, and change the screenshot
location to `~/Dropbox/media/screenshots`. That is much narrower than the surface listed in
the overview, which suggests the plan is documenting a target state rather than only the
current repo state.

## nix-darwin Surface

nix-darwin is the strongest owner here because it exposes many typed `system.defaults.*`
options for Finder, Dock, LaunchServices, universal access, power management, and custom
user preferences. It is the most direct replacement for imperative `defaults write` scripts
and the best place to keep machine-level macOS preference policy when the option exists.

## Home Manager Surface

Home Manager has Darwin defaults support through `targets.darwin.defaults` and
`targets.darwin.currentHostDefaults`, but the local docs expose a narrower, more user-
focused surface than nix-darwin. It can absorb a subset of the settings, especially per-user
defaults, but it is not the strongest general-purpose owner for this topic.

## Recommended Split

Prefer nix-darwin for the canonical macOS defaults policy. Use Home Manager only for
genuinely user-scoped defaults or for settings that are already being managed alongside
other user configuration. Avoid splitting a single app’s preference tree across both layers
unless there is a concrete reason to do so.

## Migration Notes

Translate the currently tracked `macos.sh` values first, because those are grounded in repo
evidence. Then decide whether the broader list in the overview reflects desired end state or
just an inventory of possible settings. If Finder or SystemUIServer restarts are needed
after activation, keep that restart logic explicit instead of relying on manual follow-up.

## Supporting References

- `~/dotfiles/shell/macos.sh`
- `.ai/docs/nix-darwin-options.md` for `system.defaults.finder.*` and related domains
- `.ai/docs/nix-darwin-options.md` for `system.defaults.CustomUserPreferences`
- `.ai/docs/home-manager-configuration-options.md` for `targets.darwin.defaults`
- `.ai/docs/home-manager-configuration-options.md` for `targets.darwin.currentHostDefaults`
- `.ai/plan/OVERVIEW.md` lines 213 to 317
- `killall Finder` or `SystemUIServer` behavior remains an activation concern, not a config
  key
- Screenshot path policy interacts with external storage assumptions such as Dropbox

## Notes

Compared to other topics, this one is straightforward technically and ambiguous
organizationally. The hard part is not finding the Nix option surface; it is deciding how
much macOS preference policy should actually be declared instead of merely documented.
