# 10 Fonts

Topic source: `OVERVIEW.md` line 375
Sub-agent status: completed
Result type: per-topic research memo for nix-darwin and Home Manager

## Summary

This topic is the font inventory, font installation path, and the way terminals and other
apps consume those fonts. It mixes machine-visible resources, per-user font directories, and
app configuration that references specific font names.

## Current State

The repo vendors around twenty Operator Mono `.otf` files and installs them imperatively
into `~/Library/Fonts`. The README describes Operator Mono as the main development font, and
the terminal configs reference `OperatorMono Nerd Font Mono`. That means the current setup
depends both on raw font files and on terminal config that assumes those exact names exist.

## nix-darwin Surface

nix-darwin can manage machine-visible fonts through `fonts.packages`, and it also exposes
adjacent options such as `system.defaults.NSGlobalDomain.AppleFontSmoothing` and Homebrew
cask font directory arguments. It is the stronger owner when the fonts must be visible to
the whole system or to non-Home-Manager apps.

## Home Manager Surface

Home Manager can manage font consumption and user-side font configuration through
`fonts.fontconfig.*`, `home.packages`, and program modules such as `programs.alacritty` and
`programs.ghostty`. It can also place files directly or use activation hooks for user fonts.
That makes it a strong owner for terminal font settings even when the font installation
itself is handled elsewhere.

## Recommended Split

Use nix-darwin or a declared Homebrew font path when the font binaries must be visible
system-wide. Use Home Manager for the application configs that consume those fonts. If the
current paid Operator Mono files stay in use, keep the actual font assets out of the public
store path and focus on declaratively modeling the destination and consumer settings.

## Migration Notes

First decide whether Operator Mono remains the target or whether a Nix-packaged replacement
is acceptable. Then move the terminal font settings into their Home Manager modules and make
sure the installed font names line up. Only after that should the imperative font-copy step
be replaced or removed.

## Supporting References

- `~/dotfiles/fonts/operator-mono*`
- `~/dotfiles/README.md`
- `~/dotfiles/alacritty/alacritty.toml`
- `~/dotfiles/ghostty/config`
- `.ai/docs/nix-darwin-options.md` for `fonts.packages` and `AppleFontSmoothing`
- `.ai/docs/home-manager-configuration-options.md` for `fonts.fontconfig.*`
- `.ai/docs/nix-darwin-options.md` for `homebrew.caskArgs.fontdir`
- `.ai/plan/OVERVIEW.md` lines 375 to 389

## Notes

Fonts are deceptively cross-cutting because they touch both installation policy and
downstream app config. The actual migration risk is not the module availability; it is
preserving the current font names and visual expectations while changing the install
mechanism.
