# Migration Master Plan

Source-of-truth overlay that consolidates the 16 topic memos with the May 2026
interview decisions. Where this doc disagrees with `01-16-*.md`, this doc wins
and the topic memo will be edited to match in its respective beads ticket.

## Ground Truth (as of 2026-05-18)

- Nix is **not installed** on AVA. `flake.nix`, `modules/darwin/base.nix`, and
  `modules/home-manager/{base,packages,shell,shell/*}.nix` are authored but no
  `darwin-rebuild switch` has ever run on this machine.
- `~/dotfiles` is the de-facto active config: symlinks own `~/.tmux.conf`,
  `~/.vale.ini`, `~/.gitconfig`, `~/.functions`, `~/.scripts`, `~/.config/nvim`,
  `~/.config/lvim`, `~/.config/vale`, `~/.config/ghostty/config`,
  `~/.config/zed/{settings,keymap,tasks}.json`, `~/.p10k.zsh`, `~/.Brewfile`.
- Homebrew: `/opt/homebrew`, 107 leaves, 294 total formulas, 16 casks, 12 taps.
  Live inventory drifts from every Brewfile in `~/dotfiles`.
- /Applications: 141 entries. MAS-installed apps present; `mas` CLI not installed.
- Fonts: 230 user fonts including paid Operator Mono Nerd Font Complete variants.
- Launchd: 27 user agents + 27 system daemons + 14 system LaunchAgents; large
  fraction obviously stale (mysql@5.6, postgresql@9.6, mailspring, virtualbox,
  mega, skype, etc.).
- Runtime managers active: nvm (17 node versions), pyenv (3 pythons), rbenv (2
  rubies), rustup, bun, deno, brew-installed go.
- gitego owns 5 path-based identities (jry/inf/tdna/zigg/keybase) with
  per-profile SSH keys; `~/.gitego/config.yaml` is the rule table.
- 1Password is the SSH agent (`~/.ssh/1password-agent.sock`).
- GPG Suite installed, gpg-agent active, signing key `715CED2327899E28`.
- FileVault on; firewall off; auto-update off; Touch ID sudo not configured.
- `/etc/hosts` blocks 14 facebook domains.
- `testaccount` user exists with `/bin/zsh`.

## Decisions Recorded This Session

| # | Decision | Source |
| - | -------- | ------ |
| D1 | First real switch runs as `testaccount` on AVA; CASE migrates in-place via hm-backup once parity confirmed. | Interview R1 Q1 |
| D2 | Live machine state (brew leaves+casks+mas+fonts+defaults+launchd snapshot) is authoritative for the declarative ledger. Brewfiles in `~/dotfiles` are historical. | Interview R1 Q2 |
| D3 | `homebrew.onActivation.cleanup = "none"` forever. Drift accumulates; manual cleanup only. | Interview R1 Q3 |
| D4 | Single `darwinConfigurations.AVA`. No personal/work profile split. | Interview R1 Q4 |
| D5 | All Nix-packaged CLIs move to Home Manager. Homebrew bridge holds GUI casks + Brew-only formulas (gpg-suite, pinentry-mac, mas, mactex, wireshark-app, xquartz, etc.). | Interview R2 Q1 |
| D6 | Existing `/opt/homebrew` is shared between CASE and testaccount. No isolated brew prefix. | Interview R2 Q2 |
| D7 | Install `mas` now, snapshot installed App Store apps, declare via `homebrew.masApps`. | Interview R2 Q3 |
| D8 | All AI tools declarative (gemini-cli, codex, crush, agent-browser, ccusage, beads/bd, harper, etc. all pinned). | Interview R2 Q4 |
| D9 | Zed uses copy-once seed activation (`home.activation` copies `assets/zed/*.json` only when target absent). Subsequent UI edits persist. | Interview R3 Q1 |
| D10 | 1Password owns SSH only. GPG owns commit/tag signing only. `services.gpg-agent.enableSshSupport = false`. | Interview R3 Q2 |
| D11 | Vendor **all** non-native fonts in the repo, including Operator Mono. The actual on-disk family name is `Operator Mono * Nerd Font Complete`, not `OperatorMono Nerd Font Mono` as the older plan text says. | Interview R3 Q3 |
| D12 | Secret model: `op run --env-file` at runtime for everything. Maintain a tracked registry of "needs op but currently doesn't" inside `.ai/secrets-registry.md`. No sops/agenix. | Interview R3 Q4 |
| D13 | Editor stack: Zed primary. Preserve `nvim/` and `lvim/` config trees as-is via `xdg.configFile`. No editor redesign in this migration. | Interview R4 Q1 |
| D14 | Runtime managers: drop pyenv+rbenv from shell startup; keep nvm, Bun, rustup for now. Per-project devShells adopted gradually. | Interview R4 Q2 |
| D15 | Launchd hygiene: inventory all live plists; declare desired ones via `launchd.{agents,daemons,user.agents}`; actively remove stale plists during migration (mysql@5.6, postgresql@9.6, mailspring, virtualbox, mega, skype, keybase.kbfs.devel, etc.). | Interview R4 Q3 |
| D16 | Defaults: declare only intentionally-set values per topic walk-through, not a comprehensive snapshot. Skip `system.defaults.alf.*` and Touch ID sudo per D27. | Interview R4 Q4 |
| D17 | After migration, `~/dotfiles` stays in place untouched. Migrate content into `modules/home-manager/assets/`; do not delete or archive the legacy tree. | Interview R5 Q1 |
| D18 | SSH key cleanup: move every private key into the 1Password vault; only `~/.ssh/allowed_signers` remains on disk. Per-host blocks use `IdentityAgent` pointing at the 1Password socket. | Interview R5 Q2 |
| D19 | TCC permissions: guided post-activation checklist script (opens each Settings pane, prints the per-pane app list). No MDM. | Interview R5 Q3 |
| D20 | Validate via `darwin-rebuild switch` under testaccount after every meaningful module addition. Smoke tests scripted per topic. | Interview R5 Q4 |
| D21 | Keep existing beads epics; extend the backlog with new tickets for Topics 04, 05, 06, 07, 08, 09, 10, 11, 12, 14, 16, plus new font/secret/security/launchd epics. | Interview R6 Q1 |
| D22 | Aggressive agent fan-out: per-topic researcher + independent reviewer agent for cross-verification. | Interview R6 Q2 |
| D23 | Try to map every manual `/Applications` entry to a brew cask first; document the unmappable ones in README "manual install" list. | Interview R6 Q3 |
| D24 | Use `/adr` (JSONL) for fine-grained decisions; DECISIONS.md keeps tranche-level summaries per `CLAUDE.md`. | Interview R6 Q4 |
| D25 | Keep gitego. Generate `~/.gitego/config.yaml` and the gitconfig credential-helper + includeIf rules declaratively from Home Manager. | Interview R7 Q1 |
| D26 | Declare current `/etc/hosts` facebook block list via `networking.hosts`. Open to extending with a maintained tracker list later. | Interview R7 Q2 |
| D27 | Skip Topic 09 (networking/firewall) and Topic 12 (/etc/PAM/Touch ID sudo) entirely for now. No firewall enable; no Touch ID for sudo. | Interview R7 Q3 |
| D28 | `testaccount` persists indefinitely as the validation user. Future-change validation always runs there first. | Interview R7 Q4 |
| D29 | Nvm: install only current LTS on first activation; older versions accumulate on demand (no curated set). | Interview R8 Q1 |
| D30 | Legacy `~/dotfiles` tree strict whitelist to `modules/home-manager/assets/`: `nvim/`, `lvim/`, `vale/`, `ghostty/config`, `tmux/tmux.conf`, `zed/{settings,keymap,tasks}.json`, `shell/p10k.zsh`, `git/{gitconfig,gitignore}` (translated), `functions/` (audited file-by-file), `fonts/operator-mono*`. Drop everything else (examples/, dotbot/, dotbot-brewfile/, zsh-theme/, oh-my-zsh/, Session.vim, commits.md). | Interview R8 Q2 |
| D31 | Time Machine: declare nothing host-specific. ECHELON destination remains manual. `timemachineeditor` cask declared; backup destination not in declarative scope. | Interview R8 Q3 |

## Architecture (frozen)

```
flake.nix
├── inputs: nixpkgs (25.11-darwin), nix-darwin (25.11), home-manager (25.11),
│           determinate (flakehub v3)
│
└── darwinConfigurations.AVA
    ├── inputs.determinate.darwinModules.default  (owns /etc/nix/nix.conf)
    ├── modules/darwin/
    │   ├── base.nix          determinateNix.enable=true; hostName; primaryUser
    │   ├── packages.nix      system-wide CLI (sparse — most goes to HM)
    │   ├── shell.nix         users.users.CASE.shell=/bin/zsh; programs.zsh.enable
    │   ├── homebrew.nix      bridge: enable=true; cleanup="none"; brews/casks/masApps
    │   ├── fonts.nix         system fonts.packages + vendored asset paths
    │   ├── launchd.nix       declared daemons + removal of stale plists
    │   ├── hosts.nix         networking.hosts facebook block list
    │   └── defaults.nix      system.defaults.* intentional values only
    │
    └── home-manager.users.CASE  (useGlobalPkgs=true; backupFileExtension="hm-backup")
        ├── inputs.determinate.homeManagerModules.default
        ├── modules/home-manager/
        │   ├── base.nix      home.username/homeDirectory/stateVersion
        │   ├── packages.nix  home.packages (Nix-packaged CLIs from D5)
        │   ├── shell.nix     programs.zsh + assets + nvm/Bun guards
        │   ├── shell/        env.zsh, profile.zsh, init.zsh, p10k.zsh, before-compinit.zsh
        │   ├── tmux.nix      programs.tmux + packaged plugins (no TPM)
        │   ├── ghostty.nix   programs.ghostty.settings
        │   ├── git.nix       programs.git + includeIf + gitego config generation (D25)
        │   ├── gpg.nix       services.gpg-agent (no SSH); gpg.conf
        │   ├── ssh.nix       programs.ssh: matchBlocks IdentityAgent → 1Password (D18)
        │   ├── github.nix    programs.gh + programs.gh-dash
        │   ├── television.nix
        │   ├── jujutsu.nix
        │   ├── monitoring.nix programs.btop + programs.htop
        │   ├── vale.nix
        │   ├── fonts.nix     home.file for vendored fonts (per-user) — D11
        │   ├── editors.nix   xdg.configFile for nvim + lvim trees (D13)
        │   ├── zed.nix       home.activation copy-once for settings/keymap/tasks (D9)
        │   └── assets/       vendored config + font assets
        │       ├── nvim/     curated whitelist (D30)
        │       ├── lvim/     curated whitelist (D30)
        │       ├── vale/
        │       ├── tmux/
        │       ├── ghostty/
        │       ├── zed/      seed files
        │       ├── shell/    p10k, functions (audited)
        │       └── fonts/    Operator Mono Nerd Font Complete *.otf + others (D11)
        └── ...
```

## Execution Order (revised tranches)

**Tranche A — Foundation closeout** (existing beads work)
- `manager-4.4` Homebrew bridge implementation (per D3, D5, D6, D8).
- `manager-4.5`/`manager-4.6` Topic 01 package ownership (per D2, D5, D8, D23).

**Tranche B — Identity & shared infra** (new tickets needed)
- Topic 10 fonts — vendor assets per D11/D30 (`manager-4.11`).
- Topic 11 secrets — `op run` integration + secrets registry per D12 (`manager-4.12`).
- Topic 04 git — declarative gitego config per D25 (`manager-4.13`).
- Topic 06 gpg — signing-only mode per D10 (`manager-4.14`).
- Topic 05 ssh — config + 1Password agent matchBlocks per D18 (`manager-4.15`).

**Tranche C — App configuration** (existing beads work, after Tranche A/B)
- `manager-4.7` Ghostty/tmux prerequisite freeze.
- `manager-4.8` asset curation per D30.
- `manager-4.9` core app-config modules.
- `manager-4.10` editor + Zed copy-once per D9, D13.

**Tranche D — System state** (new tickets needed)
- Topic 08 launchd hygiene per D15 (`manager-4.16`).
- Topic 07 macOS defaults per D16 (`manager-4.17`).
- `/etc/hosts` per D26 (`manager-4.18`).
- Topic 16 odds & ends per D23 manual-app mapping (`manager-4.19`).
- Topic 14 dev environment per D14 (`manager-4.20`).

**Tranche E — Operator UX**
- TCC checklist script per D19 (`manager-4.21`).
- Validation harness — automated testaccount smoke per D20/D28 (`manager-4.22`).

Topic 09 (firewall) and Topic 12 (/etc PAM) explicitly deferred per D27.

## Inventory Capture Plan (live-state research, runs first)

The next step after this plan lands is parallel agent fan-out (D22) to capture
live state. Each agent produces a tracked artifact under
`.ai/inventory/`:

| Artifact | Source command | Owner agent |
| -------- | -------------- | ----------- |
| `brew-leaves.txt` | `brew leaves` | inventory-brew |
| `brew-casks.txt` | `brew list --cask` | inventory-brew |
| `brew-taps.txt` | `brew tap` | inventory-brew |
| `brew-formula-full.txt` | `brew list --formula` (all installed, incl. deps) | inventory-brew |
| `mas-apps.txt` | install `mas`, then `mas list` | inventory-mas |
| `applications-manual.txt` | walk `/Applications` minus brew/MAS, map to cask candidates | inventory-apps |
| `launchd-user.txt` | `ls ~/Library/LaunchAgents` + classification (keep/remove) | inventory-launchd |
| `launchd-system.txt` | `ls /Library/Launch{Agents,Daemons}` + classification | inventory-launchd |
| `defaults-intentional.txt` | per-topic `defaults read` of the ~20 settings you actually care about | inventory-defaults |
| `fonts-vendored.txt` | `ls ~/Library/Fonts` snapshot + dedupe with system fonts | inventory-fonts |
| `ssh-keys-inventory.md` | per-key disposition (move to 1Password vault / delete) | inventory-ssh |
| `gpg-keys.txt` | `gpg --list-keys` + `gpg --list-secret-keys` (no key export) | inventory-gpg |
| `gitego-config.yaml` | snapshot of `~/.gitego/config.yaml` | inventory-git |
| `etc-hosts-blocks.txt` | non-default `/etc/hosts` entries | inventory-network |
| `runtime-managers.md` | nvm/pyenv/rbenv/rustup/bun/deno disposition | inventory-runtime |

Each capture is followed by an independent reviewer agent (D22) that re-derives
the same artifact from primary sources and flags discrepancies.

## Acceptance — what "deterministic" means here

The migration is considered complete when:

1. A fresh macOS install can run `./install` (Determinate bootstrap) and a
   single `darwin-rebuild switch --flake .#AVA` to reproduce: all CLI tools,
   GUI casks, MAS apps, fonts, vendored app config, shell environment, Zed
   seed files, /etc/hosts blocks, declared launchd jobs, intentional macOS
   defaults, and gitego identity.
2. Out of scope (explicitly manual, per decisions): TCC permissions (D19),
   App-internal login (1Password unlock, iCloud, Dropbox, Backblaze, Slack,
   etc.), Time Machine destination (D31), firewall enable (D27), Touch ID
   sudo (D27), individual project devShells (D14).
3. testaccount can run the same switch end-to-end without errors as the
   permanent validation surface (D28).
4. `~/dotfiles` remains on disk untouched (D17) but no Home Manager output
   references it.

## Open Items (deferred but tracked)

- Decision whether to enable firewall + Touch ID sudo later (revisit after
  Tranche D is done).
- Whether to extend `/etc/hosts` with a tracker block list (currently just
  facebook).
- Whether nvm survives long-term once devShells are widely adopted.
- Whether AI-tool churn (gemini-cli, codex, crush, etc.) merits a separate
  `unstable` flake input.
- Whether to register `homebrew/cask-versions` tap (already in live taps, may
  be deprecated by Homebrew).
- Operator Mono license posture if the repo ever goes public (currently
  private; vendoring is safe today per D11).
