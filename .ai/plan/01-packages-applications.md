# 01 Packages & Applications

Topic source: `OVERVIEW.md` line 37
Sub-agent status: completed
Result type: per-topic research memo for nix-darwin and Home Manager

## Summary

This topic covers the package and application inventory that is currently spread across
Homebrew formulae, casks, manual Mac App Store installs, commercial GUI apps, language
runtimes, and legacy version managers. The practical goal is to decide which inventory
belongs in nix-darwin, which belongs in Home Manager, and which still has to remain manual
on macOS.

## Current State

The current source material is still Brewfile-centric rather than Nix-centric. The root
`~/dotfiles/Brewfile` contains 9 taps, 80 brews, and 14 casks; the personal profile brewfile
contains 7 taps, 102 brews, and 13 casks; the work profile brewfile contains 6 taps, 58
brews, and 12 casks. Shell startup still expects Homebrew, `pyenv`, `rbenv`, `nvm`, Bun, and
direct PATH edits, so the package layer and the shell layer are currently coupled.

## nix-darwin Surface

nix-darwin is the best owner for machine-wide package policy, especially when the result
needs sudo, `/Applications`, Homebrew bundle bridging, or Mac App Store support. The
relevant surfaces are `environment.systemPackages`, `homebrew.brews`, `homebrew.casks`,
`homebrew.masApps`, and related Homebrew activation options. A key caveat from the earlier
research is that `homebrew.enable` manages Homebrew declaratively but does not bootstrap the
Homebrew installation itself.

## Home Manager Surface

Home Manager is strong for user-level package ownership and per-app configuration, not for
whole machine app installation policy. The main surfaces here are `home.packages` plus
first-class modules such as `programs.alacritty`, `programs.ghostty`, `programs.pyenv`,
`programs.rbenv`, and `programs.direnv`. Home Manager is also the more natural place to keep
user-facing config for tools that live under `$HOME` or `~/.config` even when the binary
itself is installed elsewhere.

## Recommended Split

The clean split is to let nix-darwin own machine-level install intent and any remaining
Homebrew bridge, while Home Manager owns user package augmentations and tool configuration.
GUI apps, MAS apps, and commercial software without good Nix packaging belong on the nix-
darwin side. User CLI tools can live in either layer, but mixing them arbitrarily will make
rebuilds and PATH resolution harder to reason about.

## Migration Notes

Start by freezing the package inventory and choosing one authoritative manifest instead of
keeping three partially overlapping Brewfiles. Then move the obvious CLI tools to Nix, keep
GUI stragglers on the nix-darwin Homebrew bridge, and defer Xcode to the manual prerequisite
list. Only after the runtime and package inventory is stable should the old version-manager
assumptions be trimmed from the shell startup files.

## Supporting References

- `~/dotfiles/Brewfile`
- `~/dotfiles/brewfiles/personal.brewfile`
- `~/dotfiles/brewfiles/work.brewfile`
- `~/dotfiles/shell/zprofile`
- `~/dotfiles/shell/zshrc`
- `.ai/docs/nix-darwin-options.md` for `environment.systemPackages` and `homebrew.*`
- `.ai/docs/home-manager-configuration-options.md` for `home.packages` and program modules
- `.ai/plan/OVERVIEW.md` lines 37 to 72

## Notes

The overview is broader than the currently encoded dotfiles inventory, so this topic is part
migration design and part inventory cleanup. That mismatch is important: if the package
surface is not normalized first, later topics such as shell startup, fonts, and development
toolchains will inherit unstable assumptions from Brew-era state.
