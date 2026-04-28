This repository is the source of truth for the macOS setup. Determinate provides the installer and Nix substrate, but the flake, host definitions, `nix-darwin` modules, and Home Manager modules live here.

## Core Constraints

- For all real Nix installs, rebuilds, debugging, and mutable validation on macOS, switch to `testaccount`. The password for that user is `testaccount`.
- Non-mutating checks such as reading files, shell syntax checks, or documentation updates may run as the current user.
- Make conventional commits for all work. Do not push.

## Overall Approach

- Treat `.ai/plan/` as the full migration surface. Bootstrap is only the entrypoint, not the whole design.
- Keep `AGENTS.md` and `CLAUDE.md` focused on cross-cutting rules that will still matter later. Keep topic-specific decisions in `.ai/plan/`, `README.md`, module files, and code comments where appropriate.
- For each topic, do a deep dive into the existing state, synthesize what is intentional versus stale, and ask the user direct questions in chat when intent is unclear before hard-coding behavior.
- Consult the latest official documentation for Determinate, Nix, `nix-darwin`, and Home Manager before making design decisions.

## Bootstrap Baseline

- The supported first-install path is Determinate Systems only.
- The intended entrypoint is this repo’s local `./install` wrapper, which bootstraps this repo’s flake.
- Do not treat the Determinate repository as configuration state. It is an upstream dependency, not the user’s system definition.

## Determinate + nix-darwin Rule

- When using Determinate with `nix-darwin`, include Determinate’s Darwin module and set `determinateNix.enable = true`.
- Do not build the base system around `nix-darwin`’s normal `nix.*` ownership model when Determinate is active.
- If custom Nix daemon settings are needed later, prefer Determinate’s configuration surface such as `determinateNix.customSettings` rather than reintroducing conflicting `nix-darwin` ownership.

## Validation Standard

- Validate the bootstrap path on a clean macOS install before relying on higher-level modules.
- If Nix is not yet installed on the active machine, expect validation to be limited to static checks until a real install is performed under `testaccount`.

## Decision Log

There exists @DECISIONS.md which you must use upon completing work. What were the major changes that others should know about. What worked? What did not work? Why did it not work? What should others know about your attempt and what should they do differently. You MUST add to this at the end of every single completed session.

## Issue Tracking

This project uses `bd` (beads) for issue tracking.

- Run `bd prime` for workflow context at session start.
- Use `bd` for strategic work that may span sessions.
- Run `bd sync --flush-only` before ending the session.
