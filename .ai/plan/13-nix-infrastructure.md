# 13 Nix Infrastructure Itself

Topic source: `OVERVIEW.md` line 432
Sub-agent status: completed
Result type: Topic 13 boundary memo for Determinate, nix-darwin, and Home Manager

## Summary

This topic is the machine-level Nix control plane on macOS: CLI and daemon settings, caches,
trust, flake resolution, lifecycle policy, and package-set defaults. In this repo, the
critical question is not "should nix-darwin own Nix?" but "which surfaces still exist once
Determinate owns the base installation?"

## Current State

The repo already has the Determinate-first bootstrap shape:

- [`flake.nix`](../../flake.nix) imports `inputs.determinate.darwinModules.default` and
  `home-manager.darwinModules.home-manager`.
- [`modules/darwin/base.nix`](../../modules/darwin/base.nix) sets
  `determinateNix.enable = true`.
- [`flake.nix`](../../flake.nix) also sets `home-manager.useGlobalPkgs = true`, so
  Home Manager `nixpkgs.*` options are disabled in this repo.

The stale part is the planning language: Topic 13 and the overview examples still read as if
`nix-darwin` owns `/etc/nix/nix.conf`. The latest official Determinate guide and the current
`nix-darwin` sources make that assumption false.

## Repo Boundary Matrix

| Concern | Valid surface in this repo | Boundary |
| --- | --- | --- |
| Base `/etc/nix/nix.conf` ownership | Determinate installer | Do not manage this with `nix-darwin`. The official Determinate docs say not to edit the generated `nix.conf`, and enabling `determinateNix.enable = true` disables nix-darwin's built-in Nix configuration. |
| Extra Nix CLI settings | `determinateNix.customSettings` | Use this for settings that would normally live in `nix.conf`, such as `trusted-users`, `allowed-users`, `substituters`, `trusted-substituters`, `trusted-public-keys`, `sandbox`, or `flake-registry`. These are written to `/etc/nix/nix.custom.conf`. |
| Determinate Nixd behavior | `determinateNix.determinateNixd` | Use this for `/etc/determinate/config.json`, including `garbageCollector.strategy`, `authentication.additionalNetrcSources`, and Linux-builder controls such as `builder.state`, `builder.memoryBytes`, and `builder.cpuCount`. |
| `nix.settings` / `nix.extraOptions` | Out of bounds | These are part of nix-darwin's managed Nix installation and should not be used while Determinate is active. |
| `nix.gc.*` and `nix.optimise.*` | Out of bounds under current Determinate setup | Current nix-darwin service modules assert `config.nix.enable`; they are not compatible with the `determinateNix.enable` ownership model. Lifecycle policy must therefore choose Determinate Nixd defaults or a later non-`nix.*` launchd implementation. |
| `nix.registry.*` | Treat as unavailable under current Determinate setup | The system registry file is emitted by nix-darwin's managed `nix` module, so it does not survive the `nix.enable = false` boundary that Determinate establishes. |
| `nixpkgs.flake.setFlakeRegistry` / `nixpkgs.flake.setNixPath` | Out of bounds under current Determinate setup | Current nix-darwin sources assert both options require `nix.enable = true`. They are not safe defaults in this repo while Determinate owns the Nix installation. |
| System package-set policy | Darwin-level `nixpkgs.config` and repo-owned overlays | `nixpkgs.config` remains valid because it configures package evaluation, not Determinate's base installation. This is the correct home for `allowUnfree` and later package-set policy. |
| User-level Nix ergonomics | Home Manager only when explicitly user-scoped | Home Manager `nix.settings` and `nix.registry` remain user-local only. They must not replace machine policy. Because this repo sets `home-manager.useGlobalPkgs = true`, Home Manager `nixpkgs.*` is disabled and should not be used for Topic 13 package-set policy. |

## Practical Split

- Machine-level Nix CLI policy belongs in `determinateNix.customSettings`.
- Machine-level Determinate daemon policy belongs in `determinateNix.determinateNixd`.
- Package evaluation defaults belong in Darwin-level `nixpkgs.config` and, if later needed,
  repo-owned overlays.
- Home Manager is only for explicit per-user ergonomics, not for the machine control plane.

Inference from the official nix-darwin sources: if this repo later wants a pinned system flake
registry or explicit GC/optimise cadence while keeping Determinate active, it will need a
non-`nix.*` implementation surface such as generic `environment.etc` and/or generic
`launchd.daemons`, because the dedicated nix-darwin helpers are gated behind `nix.enable`.

## Migration Notes

The next Topic 13 tasks should assume the bootstrap architecture is already chosen:

- `manager-4.1.2` decides host/profile override boundaries on top of the existing flake.
- `manager-4.1.3` chooses the first-pass machine policy for trust, caches, registry posture,
  and lifecycle behavior using only Determinate-compatible surfaces.
- `manager-4.1.4` chooses the package-set and overlay policy using Darwin-level
  `nixpkgs.config` plus repo-owned overlays, not Home Manager `nixpkgs.*`.

Real rebuild and mutable validation remain out of scope for this research memo and must happen
later under `testaccount`.

## Supporting References

- [`flake.nix`](../../flake.nix)
- [`modules/darwin/base.nix`](../../modules/darwin/base.nix)
- [`modules/home-manager/base.nix`](../../modules/home-manager/base.nix)
- `.ai/plan/OVERVIEW.md` lines 432 to 453 for the stale Topic 13 inventory rows
- Official Determinate docs:
  - "Use Determinate with nix-darwin"
  - "Determinate Nix"
- Official nix-darwin docs and source:
  - `modules/nix/default.nix`
  - `modules/nix/nixpkgs-flake.nix`
  - `modules/services/nix-gc/default.nix`
  - `modules/services/nix-optimise/default.nix`
- Official Home Manager manual:
  - user-level `nix.*` options
  - `home-manager.useGlobalPkgs`

## Notes

Topic 13 is still foundational, but the main correction is precise: this repo is not deciding
whether to let nix-darwin manage Nix. It already decided not to. Every downstream policy task
must start from the Determinate ownership boundary above instead of reopening generic
`nix-darwin` examples from the overview.
