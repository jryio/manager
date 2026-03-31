# 14 Development Environment

Topic source: `OVERVIEW.md` line 454
Sub-agent status: completed
Result type: per-topic research memo for nix-darwin and Home Manager

## Summary

This topic is the per-project developer workflow layer: toolchains, runtime selection,
direnv, dev shells, editor support packages, container tooling, formatters, linters, and
related developer UX. The overview points toward flake-based `devShell`s, but the current
repo is still largely imperative and global.

## Current State

The current state is driven by Homebrew plus shell startup scripts. `zprofile` runs `brew
shellenv`; the shell stack loads `pyenv`, `rbenv`, `nvm`, Bun, Deno, and Go tooling; and
`zlogin` auto-switches Node versions from `.nvmrc`. `direnv` is not configured. Editor
config assumes external tools already exist, including `gopls`, `ccls`, `purescript-
language-server`, `blackd-client`, `vale`, and Rust tooling under `~/.rustup`. Dotbot also
installs LunarVim and Packer imperatively. `docker-slim` is declared, but Docker Desktop and
`pre-commit` are not present in the checked dotfiles.

## nix-darwin Surface

The matching Darwin-side surfaces found by the explorer are `homebrew.enable`,
`homebrew.enableZshIntegration`, `homebrew.brews`, `homebrew.casks`, `homebrew.taps`,
`homebrew.onActivation.autoUpdate`, `homebrew.onActivation.cleanup`,
`homebrew.onActivation.upgrade`, `environment.systemPackages`, `environment.variables`,
`environment.loginShellInit`, and `environment.shellInit`. These cover the current Brew
layer, the manual `brew shellenv` behavior, and any remaining machine-wide installs such as
Docker Desktop if it stays on the Homebrew bridge.

## Home Manager Surface

The explorer found strong Home Manager support for the target direction:
`programs.direnv.enable`, `programs.direnv.enableZshIntegration`, `programs.direnv.nix-
direnv.enable`, `home.packages`, `home.sessionPath`, `home.sessionVariables`,
`programs.zsh.envExtra`, `programs.zsh.profileExtra`, `programs.zsh.loginExtra`,
`programs.zsh.initContent`, `programs.zsh.sessionVariables`,
`programs.neovim.extraPackages`, `programs.neovim.extraWrapperArgs`, and the Node, Python,
and Ruby wrappers for Neovim. `programs.mise.*` also exists, but that is a different
migration path from the overview’s flake-plus-direnv target.

## Recommended Split

Use per-project flakes and `nix develop` as the end-state owner of project toolchains. Use
Home Manager for `direnv` plus `nix-direnv`, shell integration, and editor-side support
packages. Keep nix-darwin for the machine-level package bridge and any GUI developer apps
that still need Homebrew-backed installation.

## Migration Notes

Section 14 does not match the current dotfiles state yet, so the clean migration is
additive. Enable Home Manager `direnv` plus `nix-direnv` first. Move real projects to flake
devShells. Keep only truly global editor helpers in `home.packages` or
`programs.neovim.extraPackages`. If Docker Desktop is still needed, keep it in `nix-
darwin.homebrew.casks`. Once project shells exist, trim `pyenv`, `rbenv`, and `nvm` from
shell startup.

## Supporting References

- `~/dotfiles/shell/zprofile`
- `~/dotfiles/shell/zlogin`
- `~/dotfiles/shell/zshrc`
- `~/dotfiles/install-configs/default.conf.yaml` for LunarVim and Packer bootstrap
- `~/dotfiles/nvim/*` and `~/dotfiles/lvim/*`
- `.ai/docs/nix-darwin-options.md` for `homebrew.*`, `environment.*`, and
  `programs.direnv.*`
- `.ai/docs/home-manager-configuration-options.md` for `programs.direnv.*` and
  `programs.neovim.*`
- `.ai/plan/OVERVIEW.md` lines 454 to 473

## Notes

The useful correction from the explorer is that the plan describes the desired end state,
not the current one. That means the first successful migration step is not deleting the old
toolchain managers; it is making the new `direnv` plus devShell workflow viable alongside
them.
