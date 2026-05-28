# Homebrew environment.
#
# Sourced from .zshrc (interactive shells) rather than .zprofile (login only)
# so nested non-login shells still resolve brew-managed binaries (e.g. hx).
# Runs before compinit so brew's site-functions land in fpath.
# `typeset -U path` (env.zsh) dedups the re-prepend on nested shells.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
fi
