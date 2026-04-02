# macOS Bootstrap

This repository is the declarative bootstrap entrypoint for a new macOS machine.

The first pass is intentionally narrow:

- install Determinate Nix on stock macOS,
- generate a tracked host definition,
- activate `nix-darwin`,
- embed Home Manager as a `nix-darwin` module,
- leave package inventory mostly empty until the later plan topics fill it in.

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
- Homebrew is scaffolded but disabled until the Homebrew migration topic is implemented.
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

Existing `~/.zshenv`, `~/.zprofile`, `~/.zshrc`, and `~/.p10k.zsh` files on a machine are not treated as disposable state. If those files already exist during the first Home Manager activation, move or back them up before switching so they are preserved explicitly rather than overwritten.
