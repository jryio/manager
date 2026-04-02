# 02 Shell Environment

Topic source: `OVERVIEW.md` line 73
Sub-agent status: completed
Result type: per-topic design memo updated against live state and explicit policy decisions

## Summary

This topic is the interactive shell stack: login shell selection, zsh startup file ownership,
PATH construction, prompt and plugin setup, shell aliases and functions, version-manager
hooks, and runtime shell environment for tools such as 1Password and GPG.

The topic-level design is now settled. The long-term macOS shell is `/bin/zsh` on Apple
Silicon. Bash is legacy and out of scope. nix-darwin should own only the machine-level shell
facts, while Home Manager should own the user zsh files and interactive behavior.

## Confirmed Decisions

- The long-term login shell on macOS is `/bin/zsh`, not a Nix-store zsh path.
- Apple Silicon macOS is the only target for this topic. Intel-specific compromises are out
  of scope.
- Bash startup files on macOS are legacy and should not be migrated into the declarative
  target state.
- The first migration pass keeps Oh My Zsh and Powerlevel10k for compatibility.
- Of the current runtime managers, only `nvm` and Bun survive the first pass.
- `pyenv`, `rbenv`, and Rust shell bootstrap should not be migrated into the new base shell.
- 1Password remains the required SSH agent authority and cannot be replaced.
- `brew shellenv` should remain in the login path for now.
- The current `shell/op.sh` flow has no replacement yet, so the short-term declarative design
  must leave it as local-only runtime state.
- The temporary local-shell contract is `~/.config/links/zsh-local`, sourced only if it
  exists.
- Project-specific anchors such as `tdna` and Android SDK paths are deferred to later
  host/profile work and should not appear in the first-pass generic shell.

## Current State

The current shell state is split between repo-backed dotfiles and live home-directory state.

Repo-backed shell files in `~/dotfiles`:

- `shell/zprofile` exports `PYENV_ROOT`, prepends `$HOME/.pyenv/bin`, and runs
  `brew shellenv`.
- `shell/zlogin` loads `nvm` and installs a `chpwd` hook that switches Node versions based
  on `.nvmrc`.
- `shell/zshrc` contains repeated PATH edits, Oh My Zsh, Powerlevel10k, 1Password SSH agent
  wiring, `pyenv`, `nvm`, Bun, `rbenv`, an arm64 relaunch block, aliases, helper functions,
  and `GPG_TTY=$(tty)`.
- `shell/p10k.zsh` is the prompt configuration.
- `shell/op.sh` exists as a local ignored secret-bearing file and currently exports a literal
  1Password service account token. It must never be moved into Nix-managed text.

Live home-directory shell state that is not repo-backed in `~/dotfiles`:

- `~/.zshenv` currently sources `"$HOME/.cargo/env"`.
- `~/.bashrc` and `~/.bash_profile` still exist but are legacy.
- `~/.zshrc`, `~/.zprofile`, `~/.zlogin`, and `~/.p10k.zsh` are symlinks into `~/dotfiles`.

Observed behavior and risks:

- The current shell for both `CASE` and `testaccount` is already `/bin/zsh`.
- The current PATH is assembled from multiple competing owners: macOS `path_helper`,
  `/etc/paths.d`, Homebrew, shell dotfiles, version managers, and ad hoc local additions.
- Several current PATH entries are provided by `/etc/paths.d` on this machine, such as
  MacGPG, TeX, Wireshark, and Little Snitch. These should not be copied into the generic
  shell just because they appear in the live PATH.
- The current shell config introduces duplicate PATH entries and at least one malformed path
  segment from `export PATH=$PATH:/$HOME/.local/bin`.
- The current `GPG_TTY=$(tty)` export is unguarded and can resolve to `not a tty` in
  non-terminal contexts.
- The arm64 relaunch block in the old `zshrc` is stale as a base-shell design. The topic
  target is already Apple Silicon only, so the shell should not relaunch itself to force
  arm64.

## nix-darwin Surface

nix-darwin should own only machine-level shell facts:

- `users.users.<name>.shell`
- `programs.zsh.enable`
- `environment.shells` only if a non-default shell must be added to `/etc/shells`
- minimal shell-independent init hooks only if absolutely required before Home Manager
  activation

For this topic, the right nix-darwin behavior is narrow:

- enable zsh support so nix-darwin sets up the normal Nix-aware zsh integration
- declaratively set the login shell to `/bin/zsh`
- do not use nix-darwin as the home for prompt, aliases, plugins, version-manager hooks, or
  secret-adjacent runtime shell logic

Because `/bin/zsh` is already a permitted shell on macOS, `environment.shells` does not need
to add anything for the settled target state.

With Determinate active, nix-darwin must continue to leave Nix ownership to Determinate. The
shell topic must not reintroduce conflicting `nix.*` settings.

## Home Manager Surface

Home Manager is the correct owner for the user shell files and interactive zsh behavior:

- `programs.zsh.enable`
- `programs.zsh.dotDir`
- `programs.zsh.envExtra`
- `programs.zsh.profileExtra`
- `programs.zsh.loginExtra`
- `programs.zsh.initContent`
- `programs.zsh.shellAliases`
- `programs.zsh.oh-my-zsh.*`
- `home.sessionVariables`
- `home.sessionPath`
- `home.sessionSearchVariables`
- `home.file` for `.p10k.zsh` and any other prompt assets

The important implementation detail is to set `programs.zsh.dotDir =
config.home.homeDirectory;` explicitly. Home Manager's default `dotDir` behavior changes for
newer state versions, and this repo should lock in home-directory zsh files deliberately
instead of inheriting a future default change by accident.

## Target Ownership Split

Use nix-darwin for:

- login shell registration as `/bin/zsh`
- machine-level zsh enablement
- no more than the minimum shell plumbing required for the system

Use Home Manager for:

- `.zshenv`
- `.zprofile`
- `.zshrc`
- `.zlogin` only if a real login-only need remains after translation
- `.p10k.zsh`
- Oh My Zsh configuration
- aliases and helper functions
- runtime hooks for `nvm`, Bun, 1Password, and guarded `GPG_TTY`

Do not migrate Bash into the new declarative target on macOS.

## Startup File Policy

The target file responsibilities should be simpler than the current split:

- `.zshenv`: minimal early shell environment only. No project paths, no prompt logic, no
  secrets, and no Rust bootstrap from `~/.cargo/env`.
- `.zprofile`: login-only bootstrap. For now this includes guarded `brew shellenv`.
- `.zlogin`: avoid by default. The current `nvm` auto-switch hook is interactive behavior and
  belongs in `.zshrc`, not in a separate login-only file.
- `.zshrc`: all interactive behavior, including Oh My Zsh, Powerlevel10k, shell aliases and
  functions, 1Password socket wiring, guarded `nvm`, guarded Bun, guarded `GPG_TTY`, and the
  optional local fragment.

This is intentionally different from the old `~/dotfiles` split. The goal is not to preserve
every legacy file boundary. The goal is to preserve behavior while making the new shell
generic and understandable.

## PATH and Environment Policy

PATH ownership must be normalized.

Base rules:

- Let macOS `path_helper`, nix-darwin zsh integration, Nix profiles, and guarded
  `brew shellenv` establish the machine baseline.
- Use `home.sessionPath` only for stable user-level additions that truly belong in the global
  interactive environment.
- Do not re-add paths that already come from `brew shellenv` or `/etc/paths.d`.
- Do not keep repeated `export PATH=...` mutations in `zshrc`.
- Do not keep malformed path additions such as `/$HOME/.local/bin`.
- Do not keep project-specific paths in the generic shell.

Specific consequences for the first pass:

- Keep guarded `brew shellenv` in login init.
- Drop `pyenv` and `rbenv` PATH setup.
- Drop Rust cargo bootstrap from `.zshenv`.
- Preserve only `nvm` and Bun runtime behavior, and guard both so startup still succeeds when
  they are not installed yet.
- Leave project-specific anchors such as `tdna` and Android SDK paths for later
  host/profile-specific work.

## Prompt, Plugins, and Interactive Behavior

The compatibility target for the first pass is:

- Oh My Zsh stays
- Powerlevel10k stays
- the current plugin-driven behavior stays where it is still justified, including `git`,
  `common-aliases`, autosuggestion behavior, and the existing `fzf-tab` workflow
- current user-facing aliases and small helper functions can stay if they do not encode
  machine-specific assumptions

Home Manager should own Oh My Zsh through `programs.zsh.oh-my-zsh.*` instead of imperative
clones. Non-core plugins such as `fzf-tab` and `evalcache` should be modeled through
`programs.zsh.plugins` or other Home Manager-native surfaces rather than `ZSH_CUSTOM` git
clones under `~/.oh-my-zsh/custom`. `.p10k.zsh` should remain a managed asset file.

The current `fzf-tab` `zstyle` configuration should be preserved if `fzf-tab` remains in the
first pass. The old plugin bootstrap mechanism should not.

The old arm64 relaunch block should not be migrated.

## Secrets and Local Runtime Hooks

The old `shell/op.sh` pattern cannot be made declarative safely because the file contains
secret material. The short-term replacement contract is:

- a local, ignored, optional file behind the stable anchor `~/.config/links/zsh-local`
- sourced only if present
- sourced from interactive zsh init, not from `.zshenv`

This keeps the current local-secret workflow possible without putting the contents in the Nix
store.

The shell must not scan `~/.config/links` generically or add that directory to PATH. Named
anchors are allowed; directory-wide magic is not.

## SSH and GPG Runtime Policy

1Password is the required SSH agent owner for this repo. The shell should continue to export
the 1Password agent socket explicitly in the first pass.

`GPG_TTY` should remain runtime shell code, but it must be guarded so non-terminal contexts
do not produce `not a tty`. This is still shell-owned runtime behavior, while longer-term GPG
agent policy remains part of Topic 06.

## Recommended Split

Use nix-darwin for `/bin/zsh` registration and base zsh enablement. Use Home Manager for all
user zsh files and interactive shell behavior. Keep `brew shellenv` in login init for now.
Retain Oh My Zsh, Powerlevel10k, `nvm`, Bun, and 1Password compatibility in the first pass.
Do not migrate Bash, `pyenv`, `rbenv`, Rust cargo bootstrap, the arm64 relaunch block, or
project-specific path additions into the new generic shell.

Use `~/.config/links/zsh-local` as the temporary local-only replacement contract for
`shell/op.sh`. Source it only if present, and keep its contents out of tracked declarative
files.

## Migration Notes

The migration should be compatibility-first but not byte-for-byte.

Safe first-pass goals:

- move zsh ownership into Home Manager
- simplify startup-file responsibilities
- normalize PATH ownership
- keep the current prompt and plugin UX
- keep 1Password, `nvm`, and Bun working if installed
- allow the shell to start cleanly on a fresh Apple Silicon Mac where optional runtime tools
  are not installed yet

Things that should be removed during the first pass instead of copied forward:

- `pyenv` shell init
- `rbenv` shell init
- cargo bootstrap in `.zshenv`
- the arm64 relaunch block
- Bash migration work
- hardcoded project and SDK paths

## Cross-Topic Dependencies

This topic depends on and constrains several other topics:

- Topic 01 Packages: package ownership must explain where `nvm`, Bun, and shell tools come
  from, but the shell can already be written to tolerate their absence.
- Topic 05 SSH: the 1Password socket path remains a shell and tmux dependency.
- Topic 06 GPG: `GPG_TTY` stays runtime shell code until broader GPG agent policy is settled.
- Topic 11 Secrets: `zsh-local` is a temporary local-only secret hook, not the long-term
  secret-management answer.
- Topic 14 Development Environment: `pyenv` and `rbenv` are intentionally not carried
  forward, and project-specific runtime paths are deferred.

## Supporting References

- `~/dotfiles/shell/zprofile`
- `~/dotfiles/shell/zlogin`
- `~/dotfiles/shell/zshrc`
- `~/dotfiles/shell/p10k.zsh`
- `~/dotfiles/shell/op.sh`
- `~/dotfiles/functions/*`
- `~/.zshenv`
- `~/.bashrc`
- `~/.bash_profile`
- `~/dotfiles/tmux/tmux.conf`
- `/etc/zprofile`
- `/etc/zshrc`
- `/etc/paths`
- `/etc/paths.d/*`
- `.ai/docs/nix-darwin-options.md`
- `.ai/docs/home-manager-configuration-options.md`
- `.ai/plan/OVERVIEW.md` lines 73 to 106
- Determinate official guide: <https://docs.determinate.systems/guides/nix-darwin/>
- Home Manager zsh module source:
  <https://raw.githubusercontent.com/nix-community/home-manager/master/modules/programs/zsh/default.nix>
- Home Manager Oh My Zsh module source:
  <https://raw.githubusercontent.com/nix-community/home-manager/master/modules/programs/zsh/plugins/oh-my-zsh.nix>
- nix-darwin users module source:
  <https://raw.githubusercontent.com/nix-darwin/nix-darwin/master/modules/users/default.nix>
- nix-darwin shells module source:
  <https://raw.githubusercontent.com/nix-darwin/nix-darwin/master/modules/system/shells.nix>
- Nix environment/PATH guidance:
  <https://raw.githubusercontent.com/NixOS/nix/master/doc/manual/source/installation/env-variables.md>

## Notes

The shell topic remains the main compatibility layer for the rest of the migration. The
important correction is that the old shell files are not a generic design to preserve; they
are a compatibility source to translate selectively.

There are no remaining topic-level policy questions for Section 02. The remaining work is
implementation sequencing and validation.
