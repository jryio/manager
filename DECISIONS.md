## Intro (append to this file)

- [task name or branch name]: concise decision summary
  - 1-2 bullet points of detail (reference files)
  - be extremely terse, reference tickets, plans, etc. focus on the post important takeaway so other readers can distill information quickly and efficienty.

## Decisions
- [manager-4]: rebased the migration backlog around actual repo state
  - Closed stale `manager-1`/`manager-2`/`manager-3` after confirming bootstrap and Topic 02 shell work are already implemented; Topic 03 planning is complete in `.ai/plan/03-dotfiles-app-configuration*.md`.
  - Created epic `manager-4` plus ordered child issues for Topics 13, 15, 01, 10, and 03 so future work starts with control-plane and package ownership instead of skipping ahead to app-config modules.
- [manager-4.1]: turned Topic 13 into a real policy epic with a gated child backlog
  - Recast `manager-4.1` as an epic focused on Determinate-backed Nix control-plane policy, using current repo state from `flake.nix`, `modules/darwin/base.nix`, `README.md`, and `.ai/plan/13-nix-infrastructure.md`.
  - Added `manager-4.1.1` through `manager-4.1.5` to sequence Determinate-boundary research, host/profile split research, trust/cache/registry policy, nixpkgs/overlay policy, and the final `manager-4.2` implementation handoff.
- [manager-4.2]: split Topic 13 implementation into a real execution epic
  - Converted `manager-4.2` from a single feature stub into an implementation epic tied to the current repo surfaces in `flake.nix`, `modules/darwin/base.nix`, `modules/darwin/homebrew.nix`, `modules/darwin/packages.nix`, `modules/home-manager/base.nix`, `README.md`, and `.ai/plan/13-nix-infrastructure.md`.
  - Added `manager-4.2.1` through `manager-4.2.4` for module seams, machine-level Determinate-compatible policy, package-set/Home Manager Nix ergonomics, and docs plus validation closeout, with dependencies routed through `manager-4.1.5`.
- [manager-4.3]: turned Topic 15 into a real Homebrew policy epic
  - Recast `manager-4.3` as an epic grounded in current repo state: `modules/darwin/homebrew.nix` is still disabled, `modules/home-manager/shell/profile.zsh` still expects Homebrew, and the legacy Brewfiles referenced in `.ai/plan/15-homebrew-itself.md` / `.ai/plan/01-packages-applications.md` do not exist in this repo.
  - Added `manager-4.3.1` through `manager-4.3.4` to sequence missing-manifest research, official Homebrew bridge-boundary research, policy synthesis, and the final `manager-4.4` handoff so Topic 15 implementation does not invent inventory truth or bridge behavior on the fly.
- [manager-4.4]: turned Topic 15 implementation into a gated Homebrew bridge epic
  - Recast `manager-4.4` as an implementation epic that explicitly depends on `manager-4.3.4`, preserves the Determinate-backed Darwin architecture, and makes shell/docs alignment plus `testaccount` validation part of the phase contract instead of optional cleanup.
  - Added `manager-4.4.1` through `manager-4.4.4` for bridge structure, authoritative inventory encoding, shell/bootstrap/operator workflow alignment, and validation closeout so `manager-4.5` inherits a stable implementation boundary rather than reopening Topic 15 policy.
- [manager-4.5]: turned Topic 01 into a real package-classification epic with an explicit handoff
  - Recast `manager-4.5` as an epic grounded in actual repo state: package modules are still empty, Topic 15 now owns Homebrew bridge policy/implementation separately, and the Brewfiles still referenced in `.ai/plan/01-packages-applications.md` / `.ai/plan/15-homebrew-itself.md` do not exist in this repo.
  - Added `manager-4.5.1` through `manager-4.5.5` to sequence inventory-truth research, ownership-boundary research, canonical ledger construction, final ownership freezing, and the downstream handoff to `manager-4.6` / `manager-4.7` so Topic 01 implementation does not invent package ownership on the fly.
