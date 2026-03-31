# 15 Homebrew Itself

Topic source: `OVERVIEW.md` line 474
Sub-agent status: completed
Result type: per-topic research memo for nix-darwin and Home Manager

## Summary

This topic is about Homebrew as a managed substrate, not package-by-package migration. The
key question is how Homebrew itself is bootstrapped and then brought under nix-darwin
control as a declarative bridge for remaining formulas, casks, and MAS apps.

## Current State

Homebrew is bootstrapped imperatively through the official install script in
`~/dotfiles/install-configs/default.conf.yaml`. The install flow runs the default config,
then a profile config, then `brew.conf.yaml`, but `brew.conf.yaml` is empty. Personal links
`~/.Brewfile` to `brewfiles/personal.brewfile` and runs Dotbot `brew bundle` with `no-
upgrade: true`; work links `~/.Brewfile` to `brewfiles/work.brewfile`, but its `brewfile`
step is commented out. There are therefore three Brewfiles in play, and none currently
declare MAS apps.

## nix-darwin Surface

The explorer confirmed the relevant nix-darwin surface: `homebrew.enable`, `homebrew.taps`,
`homebrew.brews`, `homebrew.casks`, `homebrew.masApps`, `homebrew.onActivation.*`,
`homebrew.global.brewfile`, `homebrew.prefix`, and `homebrew.user`. It also confirmed the
key correction that `homebrew.enable` manages Homebrew content via a generated Brewfile but
does not install Homebrew itself. The default activation behavior in the local docs is
conservative and idempotent rather than destructive.

## Home Manager Surface

The explorer found no direct Home Manager options for `homebrew`, `brewfile`, or `mas`. Home
Manager participates only indirectly through its integration as a nix-darwin module via
`home-manager.users.*`, `home-manager.useGlobalPkgs`, and `home-manager.useUserPackages`.
That is user-environment integration, not Homebrew bootstrap or Homebrew state management.

## Recommended Split

Use nix-darwin as the single declarative owner of Homebrew itself. Home Manager should not
also try to model Homebrew taps, formulas, casks, or MAS apps. Instead, Home Manager can
reduce the Homebrew footprint over time by owning more user-space packages and config
directly.

## Migration Notes

Treat this as two separate concerns: one-time Homebrew installation and ongoing declarative
Homebrew management. The local docs only cover the second. For parity with the current
dotfiles, start closer to today’s behavior than to the aggressive example in the overview:
`upgrade = false` and `cleanup = "none"` match the present non-destructive flow better than
`upgrade = true` and `cleanup = "zap"`. Pick one Brew source of truth, translate it into
`homebrew.*`, and optionally enable `homebrew.global.brewfile = true` if manual `brew
bundle` remains useful.

## Supporting References

- `~/dotfiles/install`
- `~/dotfiles/install-configs/default.conf.yaml`
- `~/dotfiles/install-configs/personal.conf.yaml`
- `~/dotfiles/install-configs/work.conf.yaml`
- `~/dotfiles/Brewfile` and `~/dotfiles/brewfiles/*.brewfile`
- `.ai/docs/nix-darwin-options.md` for `homebrew.enable`, `homebrew.global.brewfile`, and
  `homebrew.onActivation.*`
- `.ai/docs/home-manager-manual.md` for nix-darwin integration only
- `.ai/plan/OVERVIEW.md` lines 474 to 499

## Notes

The late explorer result sharpened the most important point in Topic 15: bootstrap and
declarative management are separate problems. The nix-darwin Homebrew module is a strong
bridge once Homebrew exists, but it does not eliminate the need for a first-install story.
