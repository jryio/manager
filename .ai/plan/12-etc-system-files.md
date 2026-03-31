# 12 /etc System Files

Topic source: `OVERVIEW.md` line 412
Sub-agent status: completed
Result type: per-topic research memo for nix-darwin and Home Manager

## Summary

This topic covers privileged `/etc`-owned state such as `/etc/shells`, `/etc/nix/nix.conf`,
`/etc/zshrc`, `/etc/zprofile`, `/etc/hosts`, PAM configuration, and sudo policy. The
overview already treats it as primarily a nix-darwin concern.

## Current State

No repo-backed `/etc` files were found under `~/dotfiles`. The current repo only links user
shell files into `$HOME` and changes the default shell imperatively with `chsh`. The only
adjacent system-like script is `shell/macos.sh`, which manages defaults rather than `/etc`
state. That means the current repo offers almost no direct declarative source of truth for
actual `/etc` ownership.

## nix-darwin Surface

nix-darwin is the right owner for this topic. The local docs expose `environment.etc.*`,
`environment.shells`, `users.users.<name>.shell`, `nix.settings`, `programs.zsh.*`,
`environment.*ShellInit`, `security.pam.services.sudo_local.*`, and
`security.sudo.extraConfig`. Those options line up directly with the overview’s `/etc`
surface, with the important nuance that PAM support is documented for `sudo_local` rather
than for editing the base `sudo` file.

## Home Manager Surface

Home Manager is not the primary owner for `/etc`. It manages home-directory files through
`home.file` and `xdg.configFile`, and it can own the user shell files such as `.zshrc`,
`.zprofile`, and `.zlogin`. Its activation logic and collision handling make it a poor fit
for privileged `/etc` paths even though it integrates cleanly into nix-darwin.

## Recommended Split

Keep `/etc` ownership in nix-darwin. Move the current repo-backed shell dotfiles into Home
Manager, and let nix-darwin only manage the system shell registration, `nix.conf`, and other
true `/etc` files. That preserves a clean line between privileged machine state and user
shell customization.

## Migration Notes

Replace the imperative `chsh` step with declarative `environment.shells` plus
`users.users.<name>.shell`. Move `/etc/nix/nix.conf` concerns into `nix.settings`, use
`security.pam.services.sudo_local.touchIdAuth` or related PAM options for Touch ID sudo, and
keep sudoers edits minimal because the documented support is append-only. Translate the
current zsh files semantically into Home Manager after the `/etc` owners are settled.

## Supporting References

- `~/dotfiles/install-configs/default.conf.yaml`
- `~/dotfiles/shell/zprofile`
- `~/dotfiles/shell/zlogin`
- `~/dotfiles/shell/zshrc`
- `.ai/docs/nix-darwin-options.md` for `environment.etc.*`, `environment.shells`, and PAM
  options
- `.ai/docs/home-manager-configuration-options.md` for `home.file`, `xdg.configFile`, and
  `programs.zsh.*`
- `.ai/docs/home-manager-manual.md` for collision behavior and Darwin integration
- `.ai/plan/OVERVIEW.md` lines 412 to 431

## Notes

This is one of the clearest ownership boundaries in the whole plan. The main migration work
is not deciding where `/etc` belongs; it is discovering the live machine state that the repo
does not currently track and keeping it separate from ordinary user shell dotfiles.
