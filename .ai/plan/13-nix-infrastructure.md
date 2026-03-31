# 13 Nix Infrastructure Itself

Topic source: `OVERVIEW.md` line 432
Sub-agent status: completed
Result type: per-topic research memo for nix-darwin and Home Manager

## Summary

This topic is the Nix control plane on macOS: daemon settings, GC, binary caches, trusted
users, flake registry pinning, store optimization, overlays, and `nixpkgs.config`. It is
mostly system policy rather than user dotfile management.

## Current State

No `flake.nix`, `flake.lock`, or other Nix entrypoint exists in `~/dotfiles` today. The
current bootstrap is Dotbot plus Homebrew, with profile-specific Brewfiles and an
inconsistent install flow where the personal profile runs `brew bundle`, the work profile
comments it out, and `brew.conf.yaml` is empty. Shell startup still assumes Homebrew and
multiple non-Nix version managers, so the current environment is pre-Nix rather than
partially Nix-managed.

## nix-darwin Surface

nix-darwin is the correct primary owner here. The local docs expose `nix.settings`,
`nix.extraOptions`, `nix.gc.*`, `nix.optimise.*`, `nix.registry.*`,
`nixpkgs.flake.setFlakeRegistry`, `nixpkgs.flake.setNixPath`, `nixpkgs.config`, and
`nixpkgs.overlays`. Those are the system-level mechanisms that correspond directly to the
overview’s Topic 13 rows.

## Home Manager Surface

Home Manager exposes user-scoped `nix.package`, `nix.settings`, `nix.gc.*`, `nix.registry`,
`nix.nixPath`, `nixpkgs.config`, and `nixpkgs.overlays`, but the docs make clear that these
are user-local and not full substitutes for the Darwin-level control plane. They are useful
for user experience and consistency, not for replacing the machine-wide daemon and trust
settings.

## Recommended Split

Put Topic 13 primarily in nix-darwin. Use Home Manager only for user-level Nix ergonomics
that must exist inside the home environment. Avoid defining the same registry, GC policy, or
package-set settings in both places unless the split is intentional and documented.

## Migration Notes

Create the Darwin flake entrypoint first, because the current repo has none. Then establish
daemon settings, caches, trusted users, and GC policy in nix-darwin before touching higher
level topics. Only after the Nix control plane is stable should the Brew-era shell and
runtime assumptions start to be removed.

## Supporting References

- `~/dotfiles/README.md`
- `~/dotfiles/install`
- `~/dotfiles/install-configs/default.conf.yaml`
- `~/dotfiles/install-configs/personal.conf.yaml` and `work.conf.yaml`
- `.ai/docs/nix-darwin-options.md` for `nix.settings`, `nix.gc.*`, `nix.optimise.*`, and
  registry options
- `.ai/docs/home-manager-configuration-options.md` for user-level Nix options
- `.ai/docs/home-manager-manual.md` for the Darwin module integration path
- `.ai/plan/OVERVIEW.md` lines 432 to 453

## Notes

Topic 13 is foundational. A weak or ambiguous Nix control-plane design will leak complexity
into every later topic, especially package ownership, Homebrew bridging, and per-project
development environments.
