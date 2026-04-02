# Hosts

Machine-specific configuration lives here.

The bootstrap command creates `hosts/<config-name>/default.nix` automatically on first run.

Optional files per host:

- `default.nix`: required machine metadata
- `darwin.nix`: extra `nix-darwin` configuration for this host
- `home.nix`: extra Home Manager configuration for this host
