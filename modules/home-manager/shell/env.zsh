# Keep .zshenv intentionally minimal.
#
# Machine-level PATH setup comes from macOS, nix-darwin, Nix profiles, and
# Home Manager session variables. Interactive behavior belongs in .zshrc.

# Collapse duplicate PATH entries. Home Manager's session-var file is guarded
# by an exported __HM_SESS_VARS_SOURCED, so a parent that rebuilds PATH can
# strip ~/go/bin while keeping the guard set; with this in place, re-prepending
# the dirs (see init.zsh) is free of duplication.
typeset -U path PATH

# rustup-managed cargo binaries (per MIGRATION.md D14)
if [[ -f "$HOME/.cargo/env" ]]; then
  . "$HOME/.cargo/env"
fi
