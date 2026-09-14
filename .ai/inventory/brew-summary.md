# Brew Inventory Summary

- captured-at: 2026-09-14
- machine: AVA (macOS 15.5, Homebrew 7.0.1 at /opt/homebrew)
- captured-by: Homebrew v7 synchronization
- source artifacts: `brew-leaves.txt`, `brew-casks.txt`, `brew-taps.txt`, `brew-formula-full.txt`

## Current inventory

| Artifact | Count |
| -------- | ----: |
| `brew leaves` | 121 |
| `brew list --cask` | 21 |
| `brew tap` | 17 |
| `brew list --formula` | 317 |

The captured state is authoritative. The 2026-05-18 migration counts are historical.

## Intentional bridge exceptions

- The eight D5 Home Manager formulas, `btop`, `gh`, `git`, `htop`, `jj`, `television`, `tmux`, and `vale`, remain installed because Homebrew cleanup is `none`. They are not declared in `modules/darwin/homebrew.nix`.
- The old `powershell` cask remains installed on AVA. Homebrew removed the cask. The declared `powershell` formula provides `pwsh`.
- The deprecated `steveyegge/beads/bd` shim remains installed. It depends on the supported core `beads` formula. Do not add the shim to a new host.
