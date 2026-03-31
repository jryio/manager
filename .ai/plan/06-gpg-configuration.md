# 06 GPG Configuration

Topic source: `OVERVIEW.md` line 199
Sub-agent status: completed
Result type: per-topic research memo for nix-darwin and Home Manager

## Summary

This topic covers GPG signing, `gpg-agent`, shell integration, and any interaction between
GPG and SSH authentication. The repo shows signs of GPG-based commit signing, but not a
tracked `~/.gnupg` configuration tree.

## Current State

The current repo installs `gnupg` via Homebrew with `link: false`, adds
`/usr/local/MacGPG2/bin` to PATH, and exports `GPG_TTY=$(tty)` in `zshrc`. Git is configured
for GPG signing, but no repo-backed `~/.gnupg` files were found. The remaining shape of the
GPG setup therefore likely lives in live user state rather than in tracked dotfiles.

## nix-darwin Surface

nix-darwin exposes `programs.gnupg.agent.enable` and
`programs.gnupg.agent.enableSSHSupport`, which makes it capable of owning machine-level gpg-
agent behavior when that is desirable. It is a reasonable place to install GPG packages and
set a single system-level agent policy, but it should not be used to embed private key
material or secret files.

## Home Manager Surface

Home Manager exposes a richer user-space surface through `services.gpg-agent.*`, including
`enable`, `enableSshSupport`, `extraConfig`, `pinentry.*`, and SSH key-related fields. That
makes Home Manager the better fit for declaratively managing the user’s GPG preferences,
while still keeping the key material itself outside the store.

## Recommended Split

Choose one agent owner. If the end state uses 1Password for SSH and GPG only for commit
signing, keep the GPG config user-scoped in Home Manager and leave SSH ownership elsewhere.
If `gpg-agent` is meant to own SSH too, make that decision explicit and avoid running a
second competing agent in parallel.

## Migration Notes

Audit the live `~/.gnupg` directory first so the migration does not accidentally drop
critical pinentry, keygrip, or smartcard behavior. Then declaratively model the non-secret
preferences, verify Git signing still works, and only after that decide whether SSH support
should stay with 1Password or move into `gpg-agent`.

## Supporting References

- `~/dotfiles/git/gitconfig`
- `~/dotfiles/Brewfile`
- `~/dotfiles/shell/zshrc`
- `.ai/docs/nix-darwin-options.md` for `programs.gnupg.agent.*`
- `.ai/docs/home-manager-configuration-options.md` for `services.gpg-agent.*`
- `.ai/docs/home-manager-manual.md` for Darwin integration behavior
- `~/dotfiles/examples/edeneast-nyx/home/modules/shell/gnupg.nix` as a nearby example only
- `.ai/plan/OVERVIEW.md` lines 199 to 212

## Notes

The GPG topic is mostly a live-state discovery problem. The declarative module surfaces
exist, but the tracked repo does not yet show the real `~/.gnupg` source of truth that those
modules would need to preserve.
