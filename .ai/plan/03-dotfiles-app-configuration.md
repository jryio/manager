# 03 Dotfiles & App Configuration

Topic source: `OVERVIEW.md` line 107
Sub-agent status: completed
Result type: per-topic research memo for nix-darwin and Home Manager

## Summary

This topic is the broad user-config space under `$HOME` and `~/.config`: terminal configs,
editor configs, tmux, app settings, and other linked dotfiles. It is the area where Home
Manager has the strongest coverage and where the current Dotbot install flow overlaps most.

## Current State

Tracked configs exist for tmux, Alacritty, Ghostty, Neovim, LunarVim, Git, and Vale. Dotbot
currently links many of these files, installs Oh My Zsh plugins, installs LunarVim and
Packer imperatively, and runs additional shell scripts for fonts, terminfo, and macOS
defaults. The repo does not currently track configs for every tool named in the overview,
such as Zed, gh, gh-dash, television, jujutsu, btop, or htop.

## nix-darwin Surface

nix-darwin is only a partial fit for this topic. It can install apps and packages, and it
can manage system-wide files or defaults, but it is not the best owner for ordinary user
dotfiles. For this topic the Darwin layer should mostly stay narrow: install packages,
expose system integration when required, and leave the actual user config files to Home
Manager.

## Home Manager Surface

Home Manager has the best surface here. The local docs show first-class modules for
`programs.alacritty`, `programs.ghostty`, `programs.neovim`, `programs.tmux`, `programs.gh-
dash`, `programs.television`, `programs.jujutsu`, and `programs.zed-editor`, plus generic
`home.file` and `xdg.configFile` for anything without a dedicated module. That makes Home
Manager the natural replacement for the current Dotbot link phase.

## Recommended Split

Use Home Manager as the default owner for all user dotfiles and per-app config under the
home directory. Reserve nix-darwin for installation and system integration only. If a tool
has a first-class Home Manager module, use it; otherwise manage the file declaratively with
`home.file` or `xdg.configFile`.

## Migration Notes

Start with the tools that already have clear tracked config files and clear Home Manager
module support: terminals, tmux, Neovim, and shell-adjacent tools. After those are stable,
either add first-class declarative configs for tools that are currently unmanaged, or
explicitly mark them as out of scope. Remove imperative installer steps only after the
declarative replacement is known to work.

## Supporting References

- `~/dotfiles/tmux/tmux.conf`
- `~/dotfiles/alacritty/alacritty.toml`
- `~/dotfiles/ghostty/config`
- `~/dotfiles/nvim/init.vim` and `~/dotfiles/nvim/config.lua`
- `~/dotfiles/lvim/config.lua`
- `~/dotfiles/install-configs/default.conf.yaml`
- `.ai/docs/home-manager-configuration-options.md` for program modules and file options
- `.ai/plan/OVERVIEW.md` lines 107 to 148

## Notes

This topic is where the migration can gain the most determinism with the least system risk.
The main caution is that the repo still mixes pure file linking with imperative app
bootstrap, so the final declarative shape should separate persistent config from one-time
tool installation.
