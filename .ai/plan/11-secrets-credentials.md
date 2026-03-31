# 11 Secrets & Credentials

Topic source: `OVERVIEW.md` line 390
Sub-agent status: completed
Result type: per-topic research memo for nix-darwin and Home Manager

## Summary

This topic covers secret-bearing material and secret-adjacent tooling: SSH private keys, GPG
private keys, API tokens, `.env` files, macOS Keychain state, 1Password, and cloud
credentials. The plan already assumes a split between declarative consumers and externally
provisioned secret values.

## Current State

The repo currently hardwires the 1Password SSH agent socket in both `zshrc` and `tmux.conf`,
sets `GPG_TTY` dynamically in `zshrc`, sources a local secret-bearing `shell/op.sh`, and
uses Git with GPG signing plus an external credential helper and out-of-band profile
fragments. The dotfiles also ignore `*.env`, and at least one script sources a local
`notify.env`. That means the configuration expects local secret injection today rather than
a declarative secret manager.

## nix-darwin Surface

nix-darwin exposes the most relevant installation and system-wiring surfaces:
`programs._1password.enable`, `programs._1password-gui.enable`,
`programs.gnupg.agent.enable`, `programs.gnupg.agent.enableSSHSupport`, `programs.ssh.*`,
`environment.variables`, and `launchd.user.agents`. The main caveat is that these options
are for tooling and wiring, not for storing secret values themselves.

## Home Manager Surface

Home Manager is strong for user-space consumers and config stubs: `home.file`,
`xdg.configFile`, `home.sessionVariables`, `programs.git.*`, `programs.ssh.*`,
`services.gpg-agent.*`, `launchd.agents`, and `home.activation`. It can cleanly manage the
non-secret configuration around secrets, but it should not be used to embed tokens, private
keys, or Keychain state in plain declarative text.

## Recommended Split

Use nix-darwin for 1Password installation and any global Darwin wiring, and use Home Manager
for user-space Git, SSH, and GPG consumer configuration. Keep the secret material itself out
of the store. If encrypted secret provisioning is adopted later, it should feed these
consumer configs rather than replace them.

## Migration Notes

Model the consumers first: Git signing settings, SSH host config, identity-agent references,
and any GPG agent preferences. Then decide on the runtime secret injection mechanism,
whether that is `sops-nix`, `agenix`, `op run`, or a local-only file pattern. Do not move
`op.sh` or other raw secrets into declarative text, and keep terminal-dependent values such
as `GPG_TTY` as runtime shell behavior.

## Supporting References

- `~/dotfiles/shell/zshrc`
- `~/dotfiles/tmux/tmux.conf`
- `~/dotfiles/shell/op.sh` as a local ignored secret file
- `~/dotfiles/git/gitconfig`
- `~/dotfiles/git/gitignore` and `~/dotfiles/scripts/notify-ios.sh`
- `.ai/docs/nix-darwin-options.md` for 1Password, GPG agent, SSH, and launchd options
- `.ai/docs/home-manager-configuration-options.md` for Git, SSH, GPG agent, and file
  management
- `.ai/plan/OVERVIEW.md` lines 390 to 411

## Notes

This topic is mostly about boundary discipline. The module surfaces for consumers are clear,
but the migration should avoid the common mistake of moving working secret material into the
world-readable Nix store just because the surrounding config has become declarative.
