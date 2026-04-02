# 02 Shell Environment Implementation Plan

This file turns the settled shell-environment design into an execution plan for the repo.

## Goal

Implement a generic Apple Silicon macOS zsh environment that:

- uses `/bin/zsh` as the declarative login shell
- moves user shell ownership into Home Manager
- preserves Oh My Zsh, Powerlevel10k, 1Password, `nvm`, and Bun behavior in the first pass
- removes `pyenv`, `rbenv`, cargo bootstrap, stale arm64 relaunch logic, and hardcoded
  project paths from the base shell
- starts cleanly on a fresh Mac even when optional runtime tools are not installed yet

## Preconditions

- The repo continues to use Determinate's Darwin module with `determinateNix.enable = true`.
- Real rebuilds and mutable validation on macOS must run as `testaccount`.
- Topic 02 does not solve secret provisioning. It only defines the temporary local shell hook
  `~/.config/links/zsh-local`.
- Topic 02 does not model project-specific anchors such as `tdna` or Android SDK. Those are
  deferred to later host/profile work.

## Planned Repo Layout

Add or update these files:

- `modules/darwin/shell.nix`
- `modules/home-manager/shell.nix`
- `modules/home-manager/shell/p10k.zsh`
- `modules/darwin/base.nix`
- `modules/home-manager/base.nix`

Expected import wiring:

- `modules/darwin/base.nix` imports `./shell.nix`
- `modules/home-manager/base.nix` imports `./shell.nix`

Notes on assets:

- Keep `p10k` configuration as a managed file asset, not as an inline Nix string unless the
  file becomes intentionally edited into Nix text later.
- Do not add any tracked file containing the contents of `zsh-local` or `op.sh`.

## Phase 1: Scaffold Shell Modules

Create `modules/darwin/shell.nix` with only machine-level shell facts:

- enable zsh support
- set `users.users.${host.username}.shell = "/bin/zsh"`
- do not add a Nix-store zsh package as the login shell
- do not add user prompt, aliases, or runtime hooks here

Create `modules/home-manager/shell.nix` as the owner of all user zsh behavior:

- enable `programs.zsh`
- set `programs.zsh.dotDir = config.home.homeDirectory`
- add `.p10k.zsh` via `home.file`

## Phase 2: Define Startup File Responsibilities

Model zsh startup files explicitly instead of translating the old files mechanically.

`.zshenv`

- keep minimal
- no cargo bootstrap
- no project paths
- no prompt logic
- no secrets

`.zprofile`

- keep guarded `brew shellenv`
- no `pyenv`
- no project-specific path additions

`.zlogin`

- leave empty or omit entirely unless a true login-only need remains

`.zshrc`

- own interactive shell behavior
- load Oh My Zsh through Home Manager
- source `.p10k.zsh`
- declare user aliases and helper functions that are still valid
- export 1Password `SSH_AUTH_SOCK`
- add guarded runtime hooks for `nvm`
- add guarded runtime hooks for Bun
- set guarded `GPG_TTY`
- source `~/.config/links/zsh-local` if present

## Phase 3: Translate Preserved Behavior

Keep these behaviors in the first pass:

- Oh My Zsh
- Powerlevel10k
- the current core plugin behavior from `git` and `common-aliases`
- autosuggestion behavior
- `fzf-tab` behavior and its existing `zstyle` configuration if the plugin remains
- current `nvm` auto-switch semantics based on `.nvmrc`
- Bun path and completion behavior, but only when Bun exists
- 1Password SSH agent socket export

Translate with these rules:

- move `nvm` auto-switch hook out of the old `.zlogin` pattern and into interactive zsh init
- guard every optional runtime tool with existence checks
- use Home Manager's `programs.zsh.oh-my-zsh.*` for Oh My Zsh core plugins
- use `programs.zsh.plugins` or other Home Manager-native surfaces for non-core plugins such
  as `fzf-tab` and `evalcache`
- use Home Manager's autosuggestion support or a packaged equivalent instead of the old
  imperative plugin clone
- preserve the existing `fzf-tab` `zstyle` behavior if the plugin remains
- preserve user-visible prompt behavior, not the exact old file structure

## Phase 4: Remove Legacy Carry-Over

Do not port the following into the new shell module:

- `pyenv` shell init
- `rbenv` shell init
- `~/.cargo/env`
- the arm64 relaunch block
- Bash startup file management
- hardcoded `tdna` paths
- hardcoded Android SDK paths
- repeated manual `/opt/homebrew/bin` appends in `.zshrc`
- `/etc/paths.d`-derived paths copied into declarative shell config

Also fix the current shell-quality issues instead of preserving them:

- no malformed `/$HOME/...` path entries
- no repeated duplicate PATH mutations across startup files
- no unguarded `GPG_TTY=$(tty)` in contexts where there is no terminal

## Phase 5: Introduce the Local Anchor Contract

Document and implement the temporary local shell extension point:

- `~/.config/links/zsh-local`

Rules:

- source only if the path exists
- source only from interactive zsh init
- do not add `~/.config/links` to PATH
- do not auto-discover arbitrary files in `~/.config/links`
- do not track the contents in git

This is the short-term compatibility answer for the old `op.sh` workflow until Topic 11
defines a better secret-management path.

## Phase 6: Validation

Static validation in the repo:

- confirm new shell modules are imported by the existing base modules
- run formatting on changed Nix files
- evaluate the flake enough to confirm the shell modules compose cleanly

Mutable validation on macOS, under `testaccount`:

1. Run the rebuilt configuration from the repo checkout as `testaccount`.
2. Verify `dscl . -read /Users/testaccount UserShell` still reports `/bin/zsh`.
3. Open a fresh login shell and a fresh interactive non-login shell.
4. Confirm the shell starts cleanly when `nvm`, Bun, and `zsh-local` are absent.
5. Confirm `brew` appears via guarded `brew shellenv` when Homebrew is installed.
6. Confirm `SSH_AUTH_SOCK` points to the 1Password agent socket.
7. Confirm there is no `pyenv`, `rbenv`, or cargo bootstrap in the generated shell files.
8. Confirm PATH has no malformed `//Users/...` entry and no repeated manual brew/path churn
   from the old config.

## Acceptance Criteria

The implementation is complete when all of the following are true:

- nix-darwin declaratively keeps the macOS login shell at `/bin/zsh`
- Home Manager owns the user zsh files
- Oh My Zsh and Powerlevel10k still work
- `nvm` auto-switch still works when `nvm` is installed
- Bun path and completion still work when Bun is installed
- the shell starts cleanly when optional runtime components are missing
- 1Password remains the SSH agent authority
- `zsh-local` is optional and local-only
- `pyenv`, `rbenv`, cargo bootstrap, arm64 relaunch logic, and project-specific PATH edits
  are gone from the base shell

## Deferred Work

These are intentionally not part of this implementation:

- project-specific anchors such as `tdna`
- Android SDK path modeling
- secret provisioning beyond the temporary `zsh-local` hook
- migration of `~/dotfiles/functions` into this repo or another managed helper-bin location,
  unless a specific helper is found to be required by shell startup itself
- deeper SSH and tmux coordination beyond keeping 1Password as the SSH agent owner
- GPG agent ownership decisions beyond keeping `GPG_TTY` as guarded runtime shell behavior
- broader dev-environment tooling choices that belong to Topic 14

## Suggested Commit Breakdown

If implemented incrementally, use small commits in this order:

1. add darwin and Home Manager shell module scaffolding
2. move zsh ownership into Home Manager and add prompt asset management
3. translate preserved interactive behavior
4. remove legacy shell carry-over and clean PATH handling
5. add docs for `zsh-local` and validation notes
