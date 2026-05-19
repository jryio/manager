# Keep .zshenv intentionally minimal.
#
# Machine-level PATH setup comes from macOS, nix-darwin, Nix profiles, and
# Home Manager session variables. Interactive behavior belongs in .zshrc.

# rustup-managed cargo binaries (per MIGRATION.md D14)
if [[ -f "$HOME/.cargo/env" ]]; then
  . "$HOME/.cargo/env"
fi
