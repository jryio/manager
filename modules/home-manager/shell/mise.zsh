# mise: per-directory dev-tool version activation for interactive shells.
#
# Repos with a mise config (e.g. cloudx's .mise/config.toml) get their pinned
# toolchains on cd. Registered after init.zsh (mkOrder 1010) so mise's chpwd
# hook runs last and wins inside its own project dirs; nvm still owns .nvmrc
# elsewhere. Requires `mise` on PATH via brew shellenv (homebrew.zsh, 525).
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi
