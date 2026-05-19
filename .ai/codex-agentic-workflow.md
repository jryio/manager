You are operating in the macOS declarative setup repo at `/Users/CASE/manager`.

Session header:

- RUN_MODE: <solo | lead | builder>
- SESSION_SLICE: <auto | substrate | app-config>
- TARGET_TICKET: <auto | manager-4.x[.y]>
- WRITE_SCOPE: <auto | explicit paths or modules>

Project rules you must honor:

- The source of truth is this repo plus `bd` plus `.ai/plan/*` plus `DECISIONS.md`.
- Use `bd prime` at session start.
- Respect the execution program order:
  1. Topic 13 policy and implementation: `manager-4.1` -> `manager-4.2`
  2. Topic 15 policy and implementation: `manager-4.3` -> `manager-4.4`
  3. Topic 01 classification and implementation: `manager-4.5` -> `manager-4.6`
  4. Ghostty/tmux prerequisites: `manager-4.7`
  5. Topic 03 asset curation: `manager-4.8`
  6. Topic 03 non-editor modules: `manager-4.9`
  7. Topic 03 editor and Zed modules: `manager-4.10`
- Do not trust `bd ready` alone. Obey the phase gates above even if downstream seam tickets look
  ready.
- For real rebuilds, mutable validation, and debugging on macOS, switch to `testaccount`.
- Do not push.

Role rules:

- `lead` owns `bd` coordination, ticket claiming, ticket closeout, `.ai/plan/*`, `README.md`,
  `DECISIONS.md`, `flake.nix`, `modules/darwin/base.nix`, `modules/home-manager/base.nix`, and
  any other shared files.
- `builder` owns isolated leaf implementation work only. Do not edit shared files unless
  `WRITE_SCOPE` explicitly assigns them to you.
- If a task would require editing a shared file that another session may also touch, stop and
  report instead of guessing.

Session-slice rules:

- `substrate` means only `manager-4.1.*` through `manager-4.6.*`.
- `app-config` means only `manager-4.7.*` through `manager-4.10.*`.
- `auto` means infer the slice from `TARGET_TICKET`, otherwise choose the earliest eligible phase.

Ticket selection rules:

1. Run `bd prime`, `git status --short`, and inspect the current board with `bd ready`.
2. If `TARGET_TICKET` is explicit:
   - inspect it with `bd show <ticket>`
   - inspect its blockers/dependents
   - claim it with `bd update <ticket> --claim`
3. If `TARGET_TICKET=auto`:
   - choose the earliest eligible ticket in the current `SESSION_SLICE`
   - if `RUN_MODE=lead`, prefer research, policy, handoff, docs, validation, and shared-seam tickets
   - if `RUN_MODE=builder`, prefer isolated implementation tickets with non-overlapping write scopes
   - claim with `bd update <ticket> --claim`
   - if claim fails, select the next eligible ticket
4. If no safe eligible ticket exists for your role, stop and report the exact blocker.

Context-loading rules:

- For `manager-4.1` or `manager-4.2`:
  - load `.ai/plan/13-nix-infrastructure.md`, `.ai/plan/OVERVIEW.md`, `README.md`, `flake.nix`,
    `modules/darwin/base.nix`, `modules/home-manager/base.nix`
- For `manager-4.3` or `manager-4.4`:
  - load `.ai/plan/15-homebrew-itself.md`, `.ai/plan/01-packages-applications.md`,
    `.ai/plan/OVERVIEW.md`, `README.md`, `modules/darwin/homebrew.nix`,
    `modules/home-manager/shell/profile.zsh`
- For `manager-4.5` or `manager-4.6`:
  - load `.ai/plan/01-packages-applications.md`, `.ai/plan/14-development-environment.md`,
    `.ai/plan/OVERVIEW.md`, `README.md`, `modules/darwin/packages.nix`,
    `modules/home-manager/packages.nix`, `modules/darwin/homebrew.nix`
- For `manager-4.7`:
  - load `.ai/plan/10-fonts.md`, `.ai/plan/03-dotfiles-app-configuration.md`,
    `.ai/plan/03-dotfiles-app-configuration-implementation.md`, `.ai/plan/unknowns.md`, `README.md`
- For `manager-4.8`:
  - load `.ai/plan/03-dotfiles-app-configuration.md`,
    `.ai/plan/03-dotfiles-app-configuration-implementation.md`, `.ai/plan/unknowns.md`, `README.md`,
    `modules/home-manager/base.nix`
- For `manager-4.9`:
  - load `.ai/plan/03-dotfiles-app-configuration.md`,
    `.ai/plan/03-dotfiles-app-configuration-implementation.md`, `.ai/plan/10-fonts.md`, `README.md`,
    `modules/home-manager/base.nix`
- For `manager-4.10`:
  - load `.ai/plan/03-dotfiles-app-configuration.md`,
    `.ai/plan/03-dotfiles-app-configuration-implementation.md`, `.ai/plan/14-development-environment.md`,
    `README.md`, `modules/home-manager/base.nix`

Execution rules:

- Before editing, state:
  - selected ticket
  - selected phase
  - why it is eligible now
  - planned write scope
- Fully execute the selected ticket, not just analyze it.
- If the selected ticket is a research ticket, its outputs must include:
  - small updates to the relevant `.ai/plan/*.md` files
  - unblocking downstream engineering tasks
  - updating dependent engineering ticket descriptions with findings
  - an entry in `DECISIONS.md`
- If the selected ticket is an implementation ticket, run the relevant static checks and document
  any required `testaccount` mutable validation steps or blockers.

Closeout rules:

- Update the claimed bead with notes if needed.
- Add a concise `DECISIONS.md` entry.
- Make a conventional commit if tracked files changed.
- Run `bd sync --flush-only`.
- Report:
  - what ticket was completed or advanced
  - what files changed
  - what validation ran
  - what the next unblocked ticket should be
