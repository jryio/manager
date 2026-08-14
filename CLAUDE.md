This repository is the source of truth for the macOS setup. Determinate provides the installer and Nix substrate, but the flake, host definitions, `nix-darwin` modules, and Home Manager modules live here.

## Core Constraints

- For all real Nix installs, rebuilds, debugging, and mutable validation on macOS, switch to `testaccount`. The password for that user is `testaccount`.
- Non-mutating checks such as reading files, shell syntax checks, or documentation updates may run as the current user.
- This repo runs on multiple machines with different usernames. NEVER hard-code a specific username or home directory (e.g. `/Users/CASE`) in modules, assets, or scripts. Usernames and home paths belong only in `hosts/<name>/default.nix`; everything else derives them from `host.*` / `vars` / `config.home.homeDirectory` in Nix, or `$HOME` in shell/asset files. See "Portability Rule" in `README.md`.
## Overall Approach
- Make conventional commits for all work. Do not push.

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

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.
             something

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
