# 05 SSH Configuration

Topic source: `OVERVIEW.md` line 180
Sub-agent status: completed
Result type: per-topic research memo for nix-darwin and Home Manager

## Summary

This topic covers SSH host configuration, agent wiring, key discovery, signing support, and
known-host behavior. The configuration surface exists mostly in the user environment, while
the secret key material must stay outside the store.

## Current State

No tracked `~/.ssh` files were found in the repo. Instead, the current state is mostly
encoded through environment wiring: `zshrc` and `tmux.conf` point to the 1Password SSH agent
socket, and an older `scripts/ssh-find-agent.sh` remains in the repo as a fallback discovery
script. The real host aliases and identity files likely live in untracked `~/.ssh` state.

## nix-darwin Surface

nix-darwin can manage system-scoped SSH behavior through `programs.ssh.extraConfig` and
`programs.ssh.knownHosts`, and it can also create supporting user LaunchAgents if the agent
owner needs machine-level wiring. That makes Darwin useful for policy that should exist for
the whole machine, but still not a good place to store user secret material.

## Home Manager Surface

Home Manager is the stronger fit for the actual SSH client config. The local docs expose
`programs.ssh.includes`, `programs.ssh.extraConfig`, per-host attributes such as
`identityAgent` and `identityFile`, and generic file management for `allowed_signers` or
other supporting files under `$HOME`. This is the correct layer for `~/.ssh/config` itself.

## Recommended Split

Put `~/.ssh/config` and other user SSH config under Home Manager. Keep actual private keys
outside Nix. If 1Password remains the SSH agent owner, declaratively reference its socket
and related host settings rather than enabling a second competing SSH agent module.

## Migration Notes

First capture the live `~/.ssh/config` and any host aliases that Git depends on. Then model
that in Home Manager using host blocks and `identityAgent`, and only after parity is
confirmed should the old fallback scripts and manual socket logic be removed. Known-host
management can then be decided separately at user or system scope.

## Supporting References

- `~/dotfiles/shell/zshrc`
- `~/dotfiles/tmux/tmux.conf`
- `~/dotfiles/scripts/ssh-find-agent.sh`
- `~/dotfiles/install-configs/personal.conf.yaml`
- `~/dotfiles/install-configs/work.conf.yaml`
- `.ai/docs/home-manager-configuration-options.md` for `programs.ssh.*`
- `.ai/docs/nix-darwin-options.md` for `programs.ssh.*` and `launchd.user.agents`
- `.ai/plan/OVERVIEW.md` lines 180 to 198

## Notes

SSH is blocked less by the available Nix module surface than by missing source material. The
tracked repo shows how the agent is wired into the shell, but not the actual host map that
the new config would need to reproduce.
