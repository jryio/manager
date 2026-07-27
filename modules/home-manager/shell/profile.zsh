# .zprofile — login-shell setup.
#
# mise shims for non-interactive/login contexts (scripts, GUI editors launched
# from a login shell). The full per-directory activation lives in
# shell/mise.zsh (.zshrc). Guarded so a pre-brew fresh machine is a no-op.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh --shims)"
fi
