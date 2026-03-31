# 09 Networking & Security

Topic source: `OVERVIEW.md` line 343
Sub-agent status: completed
Result type: per-topic research memo for nix-darwin and Home Manager

## Summary

This topic covers machine-level network and security policy such as firewall state, host
entries, proxy settings, VPN clients, trusted certificates, and security-relevant user
tooling. It spans both system policy and user-facing helper apps, but the repo currently
only captures a small fraction of that surface.

## Current State

The tracked repo mostly captures SSH and GPG behavior, not global networking state.
Tailscale appears only as a shell alias to the app bundle path, and no tracked configs were
found for Mullvad, Little Snitch, custom proxy settings, or `/etc/hosts`. This topic is
therefore mostly a planning exercise until the live machine state is inventoried.

## nix-darwin Surface

nix-darwin is the obvious owner for machine networking and security policy, including
firewall settings and `/etc`-level config. The local docs use
`networking.applicationFirewall.*` rather than the overview’s older `system.defaults.alf.*`
framing, and they also expose adjacent security and PAM surfaces. This is the layer to use
for real OS policy, not Home Manager.

## Home Manager Surface

Home Manager plays a supporting role here rather than being the primary owner. It can manage
user-level helper app config, SSH client settings, optional tailscale systray integration,
and other home-directory state, but it is not a substitute for macOS network and firewall
policy. Treat it as the owner of user-space consumers, not of the network stack itself.

## Recommended Split

Use nix-darwin for firewall, host files, proxies, and other machine security policy. Use
Home Manager only for user-level config that supports those tools, such as SSH client config
or lightweight app settings. Keep runtime state, approvals, and sensitive certificate or key
material outside static declarative text unless a dedicated secret workflow is adopted.

## Migration Notes

Begin by inventorying the live machine: firewall mode, VPN clients, trusted certs, proxy
settings, and any unmanaged `/etc` changes. Then align the plan with the option names
actually present in the local docs before writing config. After the system policy is clear,
attach any user-level helper settings on the Home Manager side.

## Supporting References

- `~/dotfiles/shell/zshrc` for the Tailscale alias
- `~/dotfiles/scripts/ssh-find-agent.sh` as adjacent security tooling
- `.ai/docs/nix-darwin-options.md` for `networking.applicationFirewall.*`
- `.ai/docs/nix-darwin-options.md` for PAM and related security surfaces
- `.ai/docs/home-manager-configuration-options.md` for `services.tailscale-systray.enable`
- `.ai/docs/home-manager-configuration-options.md` for `programs.ssh.*`
- `.ai/plan/OVERVIEW.md` lines 343 to 374
- The overview terminology needs reconciliation with the actual local option dump

This topic has the highest ratio of potential surface area to tracked evidence. The plan
should treat it as inventory first, implementation second, otherwise the declarative config
will risk encoding guesses rather than observed machine policy.
