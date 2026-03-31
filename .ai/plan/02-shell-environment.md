# 02 Shell Environment

Topic source: `OVERVIEW.md` line 73
Sub-agent status: completed
Result type: per-topic research memo for nix-darwin and Home Manager

## Summary

This topic is the interactive shell stack: default shell choice, login initialization, PATH
construction, prompt/theme, aliases, completions, version-manager hooks, and agent-related
env vars. The existing repo has a large zsh setup, but the system and user responsibilities
are not separated yet.

## Current State

The repo-backed shell files are `~/dotfiles/shell/zprofile`, `zlogin`, `zshrc`, and
`p10k.zsh`. `zprofile` initializes Homebrew and `PYENV_ROOT`; `zlogin` handles `nvm` and
directory-sensitive Node switching; `zshrc` contains PATH edits, Oh My Zsh, Powerlevel10k,
plugin assumptions, 1Password SSH socket wiring, pyenv, nvm, Bun, rbenv, an arm64 relaunch,
and `GPG_TTY=$(tty)`. There is no repo-backed `.zshenv`, `.bashrc`, or `.bash_profile`.

## nix-darwin Surface

nix-darwin should own the machine-level shell facts: `environment.shells`,
`users.users.<name>.shell`, and any global shell init that must exist before Home Manager
activates. The local option docs also expose `programs.zsh.enable`,
`programs.zsh.loginShellInit`, `programs.zsh.interactiveShellInit`, and generic
`environment.*ShellInit` hooks. That makes nix-darwin the right layer for login shell
selection, but not for carrying a large mutable user prompt and alias file.

## Home Manager Surface

Home Manager is the natural owner for the actual zsh content. It can generate `.zshrc`,
`.zprofile`, and `.zlogin` via `programs.zsh.*`, manage session variables, and own prompt
assets such as `.p10k.zsh` through `home.file`. It is also the right place to keep shell
plugins and user-facing aliases as long as secret material is kept out of the Nix store.

## Recommended Split

Use nix-darwin for the shell binary and system-level login shell registration. Use Home
Manager for the user shell files, prompt, aliases, plugin setup, and most env vars. Keep
dynamic values such as `GPG_TTY=$(tty)` and secret-bearing `op.sh` logic in runtime shell
code instead of baking them into static declarative env-variable options.

## Migration Notes

The safe path is to move the existing zsh files under Home Manager with minimal semantic
change, then prune legacy behavior once parity is established. After that, remove the
imperative `chsh` step from Dotbot, decide whether the long-term shell is `/bin/zsh` or a
Nix-managed zsh, and only then simplify version-manager and plugin assumptions.

## Supporting References

- `~/dotfiles/shell/zprofile`
- `~/dotfiles/shell/zlogin`
- `~/dotfiles/shell/zshrc`
- `~/dotfiles/shell/p10k.zsh`
- `~/dotfiles/shell/op.sh` as a secret-bearing local file
- `.ai/docs/nix-darwin-options.md` for `environment.shells`, `users.users.*.shell`, and
  `programs.zsh.*`
- `.ai/docs/home-manager-configuration-options.md` for `programs.zsh.*` and
  `home.sessionVariables`
- `.ai/plan/OVERVIEW.md` lines 73 to 106

## Notes

The shell topic is the main compatibility layer for the rest of the migration. Packages,
Git, SSH, GPG, and development workflows all currently depend on the startup order and PATH
behavior encoded in `zshrc`, so shell changes should follow package normalization rather
than precede it.
