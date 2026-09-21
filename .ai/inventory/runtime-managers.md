# Runtime manager inventory

- captured-at: 2026-05-18 (rustup section re-captured 2026-09-20 after the native arm64 reinstall)
- machine: AVA (macOS 15.5)
- captured-by: inventory-runtime agent
- target decisions: D14 (drop pyenv+rbenv from shell startup), D29 (nvm = current LTS only)

## nvm

- Install path: `~/.nvm` (cloned from upstream `nvm-sh/nvm`, see `~/.nvm/.git`,
  `~/.nvm/install.sh`, `~/.nvm/package.json`).
- Source script: `~/.nvm/nvm.sh` present? **Y** (138067 bytes, dated 2021-12-06).
- Installed versions (34 total — output of `ls ~/.nvm/versions/node/`):
  - `v4.0.0`, `v4.4.5`
  - `v5.12.0`
  - `v6.5.0`, `v6.9.4`, `v6.9.5`, `v6.10.0`, `v6.11.5`
  - `v7.1.0`, `v7.4.0`, `v7.5.0`, `v7.6.0`
  - `v8.0.0`, `v8.4.0`, `v8.9.4`, `v8.11.3`, `v8.12.0`
  - `v10.8.0`, `v10.13.0`
  - `v11.5.0`, `v11.10.1`
  - `v12.20.0`, `v12.22.6`
  - `v16.10.0`
  - `v18.16.1`, `v18.18.0`, `v18.18.2`
  - `v20.9.0`, `v20.20.0`
  - `v22.14.0`, `v22.16.0`, `v22.18.0`, `v22.19.0`, `v22.22.2`
  - (Note: ground-truth memo said 17 versions; live count is **34**. Memo is stale.)
- Default version: `22` (`cat ~/.nvm/alias/default` → `22`, which is itself an
  alias file resolving to the current `v22.22.2` install).
- Other aliases under `~/.nvm/alias/`:
  - `default` → `22`
  - `lts/*` (codename pointers: `argon`, `boron`, `carbon`, `dubnium`, `erbium`,
    `fermium`, `gallium`, `hydrogen`, `iron`, `jod`, `krypton`)
- Shell hooks: `nvm.sh` is sourced in **two** places today:
  - **Active (symlinked) dotfiles**: `~/dotfiles/shell/zshrc:337` exports
    `NVM_DIR`; `~/dotfiles/shell/zshrc:371-373` sources `nvm.sh` (and
    `bash_completion`) — *no* `--no-use`, so this resolves the default version
    eagerly on every shell start.
  - **Planned Home Manager surface (not yet active)**:
    `/Users/CASE/manager/modules/home-manager/shell/init.zsh:26-58` sources
    `nvm.sh --no-use`, registers `add-zsh-hook chpwd load-nvmrc`, and calls
    `load-nvmrc` once. The `--no-use` form is the lazy path D29 needs.
- D29 disposition: **KEEP nvm + current LTS only on first activation.** Today's
  34-version sprawl is documented above for a future retirement decision; D29
  does not require pruning the existing on-disk versions, only that the
  declarative HM module installs *only* the current LTS on a fresh box. The
  HM `init.zsh` shape (`--no-use` + chpwd hook) is already compatible.

## pyenv (D14: REMOVE FROM SHELL STARTUP)

- Install path: `/opt/homebrew/opt/pyenv` (brew formula, dependency of nothing
  on the leaves list; explicitly present in `brew leaves`). The pyenv root is
  `~/.pyenv` (versions + shims dir + `version` file).
- Versions (`ls ~/.pyenv/versions/`):
  - `3.11.11`
  - `3.12.9`
  - `3.12.10`
  - (Ground-truth memo: 3 pythons — matches.)
- Pyenv global: `~/.pyenv/version` → `3.12`.
- Shell init lines that reference pyenv (all in active `~/dotfiles/shell/zshrc`,
  none in the HM module surface):
  - L40-41: `export PYENV_ROOT="$HOME/.pyenv"` + `export PATH="$PYENV_ROOT/bin:$PATH"`
  - L77-78: `export VIRTUAL_ENV_DISABLE_PROMPT=1` (pyenv-virtualenv prompt suppression)
  - L320-321: `_evalcache pyenv init -` + `_evalcache pyenv virtualenv-init -`
    (lazy eval through oh-my-zsh `evalcache` plugin)
  - L328-334: `add-zsh-hook -D precmd _pyenv_virtualenv_hook` (precmd hook removal)
  - `/Users/CASE/manager/modules/home-manager/shell/p10k.zsh:56,920-938` —
    pyenv prompt segment present but only fires when pyenv exists in PATH, so
    p10k.zsh stays neutral if init is removed.
- D14 disposition: **REMOVE FROM SHELL STARTUP.** Drop the export/PATH/init/hook
  lines when the HM `shell` module supersedes `~/dotfiles/shell/zshrc`. The
  brew formula `pyenv` may remain installed (binary-only); decide retention in
  Topic 01 (`manager-4.5`/`manager-4.6`) as part of the brew-leaves ledger. The
  p10k pyenv segment can stay — it auto-skips when pyenv is not on PATH.

## rbenv (D14: REMOVE FROM SHELL STARTUP)

- Install path: `/opt/homebrew/opt/rbenv` (brew formula on the leaves list). The
  rbenv root is `~/.rbenv` (versions + shims + `version` file).
- Versions (`ls ~/.rbenv/versions/`):
  - `1.9.3-p551`
  - `3.2.2`
  - (Ground-truth memo: 2 rubies — matches.)
- Rbenv global: `~/.rbenv/version` → `3.2.2`.
- Shell init lines that reference rbenv (all in active `~/dotfiles/shell/zshrc`,
  none in the HM module surface):
  - L38: `export PATH=$HOME/.rbenv/bin:$PATH`
  - L397: `eval "$(rbenv init -)"` (synchronous init, not cached)
- D14 disposition: **REMOVE FROM SHELL STARTUP.** Drop the PATH/init lines when
  the HM `shell` module replaces `~/dotfiles/shell/zshrc`. Brew formula `rbenv`
  retention decided in Topic 01. p10k.zsh already has the rbenv segment
  commented out (`/Users/CASE/manager/modules/home-manager/shell/p10k.zsh:69`).

## rustup

- Install path: `~/.cargo` + `~/.rustup`. Installed via the upstream `rustup-init`
  script (not via brew or Nix — `brew leaves | grep rustup` returns nothing).
  Re-run natively on 2026-09-20 to replace the Intel-era install; the correct
  invocation on any machine is
  `rustup-init -y --no-modify-path --default-host aarch64-apple-darwin --default-toolchain stable`.
  `--no-modify-path` is mandatory: Home Manager owns `~/.zshenv`/`~/.zprofile`/
  `~/.zshrc` as read-only store symlinks, and the PATH hook already lives in
  `modules/home-manager/shell/env.zsh`.
- rustup binary: 1.29.1, `Mach-O 64-bit executable arm64` (was x86_64 under
  Rosetta until 2026-09-20). Default host tuple `aarch64-apple-darwin`
  (`~/.rustup/settings.toml`), no overrides.
- Toolchains (`rustup toolchain list`):
  - `stable-aarch64-apple-darwin` (active, default) — rustc 1.98.1
  - `nightly-aarch64-apple-darwin`
  - The six Intel toolchains (`stable`, `nightly`, `1.72.1`, `1.83`, `1.97.0`,
    `1.97.1`, all `-x86_64-apple-darwin`) were uninstalled; `~/.rustup` went
    7.7 GB → 3.4 GB. Projects pinning a channel in `rust-toolchain.toml`
    (`herdr-reviewr` 1.97.0, `hnalert` stable, `merkletreehouse` nightly) pull the
    aarch64 build automatically on first `cargo` invocation; none pins an explicit
    x86_64 triple.
- Components for stable (`rustup component list --installed`, 11 entries):
  - `cargo-aarch64-apple-darwin`
  - `clippy-aarch64-apple-darwin`
  - `rust-analyzer-aarch64-apple-darwin` (new; rustaceanvim in nvim-lazy uses it)
  - `rust-docs-aarch64-apple-darwin`
  - `rust-src`
  - `rust-std-aarch64-apple-darwin`
  - `rust-std-wasm32-unknown-unknown`
  - `rust-std-wasm32-wasip1`
  - `rust-std-x86_64-apple-darwin` (kept as a cross-compilation target)
  - `rustc-aarch64-apple-darwin`
  - `rustfmt-aarch64-apple-darwin`
- Components for nightly: default profile plus `rust-src`; targets
  `wasm32-unknown-unknown` and `x86_64-apple-darwin`.
- Shell hook: `~/.cargo/env` (prepends `~/.cargo/bin` to PATH) is sourced by the
  HM `modules/home-manager/shell/env.zsh`. The legacy home-level `~/.zshenv`
  line no longer exists; `~/.zshenv` is HM-managed.
- Cargo-installed binaries (`cargo install --list`, 15 crates), rebuilt as arm64
  on 2026-09-20 at their previously installed versions with `--locked`:
  `cargo-chef` 0.1.45, `cargo-expand` 1.0.34, `cargo-generate` 0.17.3,
  `cargo-make` 0.37.10 (`cargo-make`, `makers`), `cargo-nextest` 0.9.136,
  `cargo-pretty-test` 0.2.4, `cargo-watch` 8.4.1, `code-minimap` 0.6.8 (also
  built by the nvim-lazy minimap plugin), `cross` 0.2.5 (`cross`, `cross-util`),
  `sea-orm-cli` 0.12.10 (`sea`, `sea-orm-cli`), `sqlx-cli` 0.6.2 (`cargo-sqlx`,
  `sqlx`), `trunk` 0.17.5, `vibebox` 0.3.2 (`vibebox`, `vibebox-supervisor`),
  `worker-build` 0.7.4 (`worker-build`, `worker-codegen`).
  - `cargo-leptos` 0.0.8 is the one remaining x86_64 binary: that 2022 release
    no longer compiles on rustc 1.98 (locked: `lightningcss` E0659; unlocked:
    its own `src/run/sass.rs` E0308). It still runs under Rosetta. The only
    Leptos project (`merkletreehouse`, leptos 0.5.1) needs a current
    `cargo-leptos` anyway; upgrading is a deliberate version change, not done.
  - `fd-find` 8.5.3 was uninstalled from cargo; brew's `fd` (declared in
    `modules/darwin/homebrew.nix`) is the only `fd` on PATH.
- D14 disposition: **KEEP.** rustup stays as the rust toolchain manager, now
  arm64-native; D14 explicitly retains it. Nothing about rustup is declared in
  Nix or Homebrew — this section is the record of that mutable state.

## Bun

- Version: `1.3.1`.
- Install path: `/opt/homebrew/bin/bun` (brew formula). `brew --prefix bun`
  resolves to `/opt/homebrew/opt/bun`. `bun` is **not** on `brew leaves` — it is
  a dependency of `yt-dlp` per `brew uses --installed bun`, but is still the
  surface CLI users invoke directly.
- `~/.bun/` exists (per-user data: `~/.bun/_bun` completion file,
  `~/.bun/.bun_repl_history`, `~/.bun/bin/` containing `agent-browser` and
  `neovim-node-host`, plus `~/.bun/install/`). The repo's HM `init.zsh` uses
  `BUN_INSTALL=$HOME/.bun` and prepends `$BUN_INSTALL/bin`.
- Bun config file: `~/.bunfig.toml` present? **N** (no global bunfig today).
- Shell init: `~/dotfiles/shell/zshrc:376-380` (legacy) +
  `/Users/CASE/manager/modules/home-manager/shell/init.zsh:19-24` (planned HM).
  Both export `BUN_INSTALL`, prepend `$BUN_INSTALL/bin`, and source `_bun`.
- D14 disposition: **KEEP.** D14 explicitly retains Bun.

## Deno

- Version: `deno 2.7.5 (stable, release, aarch64-apple-darwin)`
  (v8 14.6.202.9-rusty, typescript 5.9.2).
- Install path: `/opt/homebrew/bin/deno` (brew formula). `brew --prefix deno`
  resolves to `/opt/homebrew/opt/deno`. Two formula versions are still on disk
  in the Cellar: `1.40.2` and `2.7.5` (`brew list --versions deno` output).
  Deno is not on `brew leaves` — `brew uses --installed deno` shows
  `golangci-lint` depending on it.
- Legacy `~/.deno/` exists (bin dir + hatcher subdir) but is stale from a
  2021/2023 install; the active install runs from brew.
- Shell init: `~/dotfiles/shell/zshrc:45` adds `~/.deno/bin` to PATH
  (legacy). No deno reference in the planned HM `init.zsh` /
  `profile.zsh` / `env.zsh` today.
- D14 disposition: **REVIEW.** Not explicitly mentioned in D14 ("nvm, Bun,
  rustup"). Document as **present, decision pending**: deno survives as a brew
  formula owned by golangci-lint, and may either (a) stay as a brew dep with
  no user-facing role, (b) get its own HM `home.packages` entry if used
  directly, or (c) get pruned from the legacy `~/.deno/bin` PATH line. Tee up
  the call in Topic 01 (`manager-4.5`/`manager-4.6`) / Topic 14
  (`manager-4.20`).

## Go (brew-installed)

- Version: `go version go1.26.3 darwin/arm64`.
- Install path: `/opt/homebrew/bin/go` (brew formula). `brew --prefix go` →
  `/opt/homebrew/opt/go`. Go is **not** on `brew leaves` — `brew uses
  --installed go` shows downstream deps `agent-browser`, `ccusage`,
  `gemini-cli`, `heroku`, `markdownlint-cli` (the AI-tools/heroku cluster from
  D8). Two Cellar versions on disk: `25.2.1` and `26.0.0` (`brew list
  --versions go`).
- GOPATH: `/Users/CASE/go` (set explicitly in `~/dotfiles/shell/zshrc:28` via
  `export GOPATH="$HOME/go"`).
- Shell init lines referencing go (all in `~/dotfiles/shell/zshrc`, none in
  the HM module surface):
  - L28-29: `export GOPATH="$HOME/go"` + `export GO111MODULE='auto'`
  - L53: `export PATH=$PATH:$GOPATH/bin`
- D14 disposition: **REVIEW.** D14 says nothing about Go. Topic 01
  (`manager-4.5`/`manager-4.6`) decides whether Go stays as a brew formula
  (pulled in transitively by D8 AI tools anyway) or moves to `home.packages` as
  `pkgs.go`. The `GOPATH`/`GO111MODULE`/PATH lines are currently legacy-only
  and need to migrate to the HM `env.zsh`/`profile.zsh` surface when the HM
  shell module supersedes `~/dotfiles/shell/zshrc`.

## Shell-init dependency graph

Active vs. planned ownership of runtime-manager init lines. "Active" means the
runtime is loaded today on AVA via the current zsh startup chain
(`~/.zshenv` → `~/.zprofile` → `~/.zshrc`); the symlinks resolve to
`~/dotfiles/shell/{zprofile,zshrc}`. "HM surface" means
`/Users/CASE/manager/modules/home-manager/shell/{env,profile,init,
before-compinit,p10k}.zsh` (authored but not yet `darwin-rebuild switch`-ed
because Nix is not installed on AVA — ground-truth memo confirms).

| Manager  | Active load site (today, `~/dotfiles`) | HM surface (`modules/home-manager/shell/`) | D14/D29 disposition |
| -------- | --------------------------------------- | ------------------------------------------ | ------------------- |
| nvm      | `zshrc:337,371-373` (eager, sources `nvm.sh` w/o `--no-use`) | `init.zsh:26-58` (lazy: `--no-use` + chpwd `load-nvmrc`) | KEEP — HM form already D29-compatible (lazy + LTS-only install policy enforced declaratively by the HM module that owns nvm provisioning). |
| pyenv    | `zshrc:40-41, 77, 320-321, 328-334` + `zprofile:1-2` | none (intentionally absent — see `p10k.zsh:56,920-938` for prompt-only references) | REMOVE FROM SHELL — already absent from HM init; only the prompt segment remains, and it self-skips when pyenv is missing from PATH. |
| rbenv    | `zshrc:38, 397` | none (rbenv prompt segment **commented out** at `p10k.zsh:69`) | REMOVE FROM SHELL — HM has no rbenv init lines today; the commented p10k segment confirms intent. |
| rustup   | `~/.zshenv: . "$HOME/.cargo/env"` (not a `~/dotfiles` symlink — it is a literal one-line file in `$HOME`) | none yet — HM `env.zsh` is comment-only; needs a line that sources `~/.cargo/env` or equivalent `PATH` prepend | KEEP — when HM shell supersedes legacy, the cargo env hook must move into `env.zsh` (or `profile.zsh`) to preserve PATH semantics. |
| Bun      | `zshrc:376-380` | `init.zsh:19-24` (PATH prepend + completion source) | KEEP — already in HM surface. |
| Deno     | `zshrc:45` (legacy `~/.deno/bin` PATH only) | none (no deno init in HM today) | REVIEW — decide in Topic 01 whether to drop the legacy PATH line (active deno runs from brew, `$PATH` already covers it). |
| Go       | `zshrc:28-29, 53` (GOPATH + `$GOPATH/bin` PATH) | none (no go init in HM today) | REVIEW — decide brew-vs-Nix in Topic 01; GOPATH/PATH lines need a home (HM `env.zsh` or `profile.zsh`) when legacy is retired. |

Cross-cutting observation: every runtime-manager init line that D14 wants to
keep is **already mirrored in the HM `init.zsh`** (nvm, Bun), and every
runtime-manager init line D14 wants to drop (pyenv, rbenv) is **already absent
from the HM surface**. The cutover from legacy `~/dotfiles/shell/zshrc` to the
HM shell module therefore lands D14 by construction — the work is the cutover
itself (`darwin-rebuild switch` plus removing or no longer sourcing the
`~/dotfiles/shell/*` symlinks), not editing the HM module shape. The cargo env
hook was the only HM gap at capture time; it has since been closed —
`env.zsh` sources `$HOME/.cargo/env` when present, and `~/.zshenv` is now the
HM-generated file.

## Summary

| Manager | Versions installed | Planned disposition |
| ------- | ------------------ | ------------------- |
| nvm     | 34 node versions; default `22` → `v22.22.2`; LTS aliases for argon→krypton | **KEEP** (D29: HM activation installs only current LTS; older 33 versions accumulate on demand) |
| pyenv   | 3 (`3.11.11`, `3.12.9`, `3.12.10`); global `3.12` | **REMOVE-FROM-SHELL** (D14; brew formula may stay on disk for manual invocation) |
| rbenv   | 2 (`1.9.3-p551`, `3.2.2`); global `3.2.2` | **REMOVE-FROM-SHELL** (D14; brew formula may stay on disk for manual invocation) |
| rustup  | 2 toolchains (`stable` 1.98.1 / `nightly`, both `aarch64-apple-darwin`); default host `aarch64-apple-darwin`; native arm64 rustup 1.29.1 since 2026-09-20 | **KEEP** (D14; cargo env hook lives in HM `env.zsh`) |
| Bun     | 1 (`1.3.1`, brew formula) | **KEEP** (D14; HM `init.zsh` already covers it) |
| Deno    | 1 active (`2.7.5`, brew formula); legacy `~/.deno/` stub | **REVIEW** (D14 silent; pending Topic 01 / `manager-4.5`) |
| Go      | 1 active (`go1.26.3`, brew formula); GOPATH `~/go` | **REVIEW** (D14 silent; pending Topic 01 / `manager-4.5`) |
