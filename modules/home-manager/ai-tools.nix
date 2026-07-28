{ config, lib, ... }:
{
  # Claude Code: install-if-missing via the official native installer.
  # Native installs self-update in place (the brew cask disables self-update
  # and pins a version), which fits tools that ship weekly. Existing installs
  # are never touched, and ~/.claude / ~/.claude.json stay unmanaged.
  home.activation.claudeCode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -x "${config.home.homeDirectory}/.local/bin/claude" ] && ! command -v claude >/dev/null 2>&1; then
      # /usr/bin/curl: HM activation runs with a Nix-only PATH (no /usr/bin).
      run bash -c '/usr/bin/curl -fsSL https://claude.ai/install.sh | bash' \
        || echo "claude-code native install failed (offline?); re-run a switch when online"
    fi
  '';
}
