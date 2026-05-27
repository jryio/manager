# macOS Bootstrap

This repository is the declarative bootstrap entrypoint for a new macOS machine.

The first pass is intentionally narrow:

- install Determinate Nix on stock macOS,
- generate a tracked host definition,
- activate `nix-darwin`,
- embed Home Manager as a `nix-darwin` module,
- leave package inventory mostly empty until the later plan topics fill it in.

## Background

The goal is a single source of truth for a macOS setup: Determinate provides the installer and Nix substrate, while the flake, host definitions, `nix-darwin` modules, and Home Manager modules all live in this repo. Machine-level facts are owned by `nix-darwin`; the user environment is owned by Home Manager. Anything that cannot yet be declared is recorded under `.ai/inventory/` so the full system state stays auditable.

## What Is Managed

| Area | Owner | Notes |
| --- | --- | --- |
| Nix substrate | Determinate | Daemon settings via `determinateNix.*`, not `nix.*` |
| Packages / casks / MAS apps / taps | `nix-darwin` (Homebrew bridge) | Install-only; `cleanup = "none"` |
| Shell (zsh, starship) | Home Manager | Interactive behavior, aliases, prompt |
| Fonts | Home Manager | Vendored and copied into `~/Library/Fonts` |
| Git / GPG / SSH | Home Manager | gitego identities, signing key, 1Password SSH agent |
| CLI app config | Home Manager | tmux, ghostty, gh, jujutsu, television, btop/htop, vale |
| Editors | Home Manager | Neovim, LunarVim, Zed (copy-once seed) |
| `/etc/hosts` blocklist | `nix-darwin` | Managed block via activation script |
| macOS defaults / launchd | `nix-darwin` | System preferences and agents |

## Current Bootstrap Command

From a checkout of this repository, run:

```sh
./install
```

That command:

1. installs Determinate Nix if `nix` is not already present,
2. creates `hosts/<LocalHostName>/default.nix` if it does not exist,
3. creates `flake.lock` if it does not exist,
4. runs the first `darwin-rebuild switch`.

## Host Layout

Each machine lives under `hosts/<config-name>/`:

- `default.nix`: generated machine metadata and bootstrap defaults
- `darwin.nix`: optional host-specific `nix-darwin` overrides
- `home.nix`: optional host-specific Home Manager overrides

The bootstrap currently uses the machine `LocalHostName` as the default config name.

## Notes

- The installer path is Determinate Nix only.
- `nix-darwin` uses Determinate's Darwin module, so the initial framework does not manage `nix.*` directly.
- Homebrew is required as a manual prerequisite before `darwin-rebuild switch` on a clean machine; `./install` does not install Homebrew. The `nix-darwin` bridge (`modules/darwin/homebrew.nix`) then takes over taps, brews, casks, and MAS apps once Homebrew is present at `/opt/homebrew`.
- The bridge runs with `onActivation.cleanup = "none"`, `autoUpdate = false`, `upgrade = false`. `darwin-rebuild switch` installs anything in the ledger that is missing but never uninstalls anything, even if the ledger drifts from `brew leaves`. Drift cleanup is a deliberate, manual action.
- Manual `brew install`, `brew bundle --file=<path>`, and `brew uninstall` continue to work for debugging or ad-hoc work; they are not the supported sync path.
- If you want to suppress Determinate installer diagnostics, export `NIX_INSTALLER_DIAGNOSTIC_ENDPOINT=""` before running `./install`.

## Shell Environment

The shell migration keeps ownership split deliberately:

- `nix-darwin` owns machine-level zsh facts, including enabling zsh and keeping the login shell at `/bin/zsh`.
- Home Manager owns the user zsh files and interactive behavior.

The temporary local-only shell hook is:

```sh
~/.config/links/zsh-local
```

If that file exists, interactive zsh will source it. It is intentionally outside tracked declarative state so local secrets and machine-only shell tweaks do not end up in the Nix store.

Existing `~/.zshenv`, `~/.zprofile`, `~/.zshrc`, and `~/.p10k.zsh` files on a machine are not treated as disposable state. During the first Home Manager activation, any conflicting file is moved aside with the `.hm-backup` suffix rather than being overwritten in place.
