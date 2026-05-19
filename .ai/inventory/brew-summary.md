# Brew Inventory Summary

- captured-at: 2026-05-18
- machine: AVA (macOS 15.5, brew at /opt/homebrew, Homebrew 5.1.11)
- captured-by: inventory-brew agent
- source artifacts: `brew-leaves.txt`, `brew-casks.txt`, `brew-taps.txt`, `brew-formula-full.txt`

## Counts vs MIGRATION.md Ground Truth

| Artifact | Captured | MIGRATION.md ground truth | Drift |
| -------- | -------: | ------------------------: | ----- |
| `brew leaves` | 107 | 107 | none |
| `brew list --cask` | 16 | 16 | none |
| `brew tap` | 12 | 12 | none |
| `brew list --formula` (full) | 294 | 294 | none |

No drift. The numbers in `MIGRATION.md` "Ground Truth (as of 2026-05-18)" match the
captured artifacts exactly. D2 still holds: live state is authoritative; Brewfiles
in `~/dotfiles` are historical.

## Nix-packageable CLIs already in `brew leaves` (D5 starting set)

These are the obvious nixpkgs equivalents from the hint set, restricted to entries
the user has actually requested (i.e., present in `brew leaves`). They are the
first wave of Brew→Nix migration into `modules/home-manager/packages.nix`:

- `bat`
- `btop`
- `fontforge`
- `fzf`
- `gh`
- `htop`
- `hyperfine`
- `jj`
- `jq`
- `lazygit`
- `neovim`
- `oven-sh/bun/bun` (tap-qualified — nixpkgs `bun` is direct)
- `sevenzip`
- `television`
- `tmux`
- `tree`
- `uv`
- `vale`

Count: 18 leaves that map directly to nixpkgs.

### Hint-set CLIs that are NOT in `brew leaves`

These appear in `brew-formula-full.txt` as transitive dependencies of other
leaves (i.e., not user-requested today, so D5 migration does not need to "remove"
them — they will be pulled in by whichever leaf currently depends on them, or
they go to HM Nix directly):

- `ripgrep` (dep only)
- `deno` (dep only — likely pulled by a charmbracelet/agent tool)
- `go` (dep only — pulled by goreleaser/agent-browser/etc.)

Note: the hint set also lists `bun`. `bun` appears in `brew leaves` only via the
tap-qualified form `oven-sh/bun/bun`. The bare `bun` token also appears in the
full formula list. Treat as a single leaf.

## D5 Brew-only formulas — presence check

D5 calls out these as Brew-only (no Nix equivalent on Darwin) — they stay on the
Homebrew bridge. Present on AVA today:

| Formula/cask | Present? | Where |
| ------------ | -------- | ----- |
| `gpg-suite` | yes | cask (`brew-casks.txt`) |
| `pinentry-mac` | yes | leaf (`brew-leaves.txt`) |
| `mas` | **no** | matches MIGRATION ground truth — `mas` CLI not installed; D7 will install it |
| `mactex` | **no** | not currently installed; declare on bridge if/when needed |
| `wireshark-app` | yes | cask (`brew-casks.txt`) |
| `xquartz` | yes | cask (`brew-casks.txt`) |

## Observations and Anomalies

- `homebrew/cask-versions` tap is still present in `brew-taps.txt`. Per
  MIGRATION.md "Open Items", this tap "may be deprecated by Homebrew" — flag for
  D5/D23 owner before re-declaring in the bridge.
- `imagemagick` and `imagemagick@6` are both in `brew leaves` — versioned slot
  is intentional and should be preserved on the bridge if a downstream tool
  pins to v6.
- Three Python slots in leaves: `python@3.9` (leaf, explicit) plus
  `python@3.12`, `python@3.13`, `python@3.14` as deps. Only `python@3.9` is
  user-requested today.
- `pyenv` and `rbenv` are leaves but D14 drops them from shell startup. They
  remain installable on the bridge; only the shell init wiring changes.
- `mysql` and `postgresql@14` are leaves on the formula side — corresponds to
  the stale `mysql@5.6`/`postgresql@9.6` launchd plists flagged in D15. The
  current-version formulas may still be needed; the *plists* are what get
  removed in Topic 08.
- `cask` appears as both a leaf and a formula (`cask` formula, distinct from
  `--cask` listing). It is the cask formula dependency for older cask tooling;
  not the same as a GUI cask.
- Tap-qualified leaves (`charmbracelet/tap/crush`, `charmbracelet/tap/freeze`,
  `oven-sh/bun/bun`, `steveyegge/beads/bd`, `stripe/stripe-cli/stripe`) require
  the corresponding tap to remain declared in the bridge.
- No casks from the D8 AI-tool set (`gemini-cli`, `codex`, `crush`,
  `agent-browser`, `ccusage`, `bd`, `harper`) are casks — they are all
  formulas, six of them already in `brew leaves` (`agent-browser`, `ccusage`,
  `gemini-cli`, `harper`, plus tap-qualified `crush` and `bd`). `codex` is the
  exception: it is in `brew-casks.txt` (a GUI cask, not a formula).
