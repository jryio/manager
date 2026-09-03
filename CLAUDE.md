This repository is the source of truth for the macOS setup. Determinate provides the installer and Nix substrate, but the flake, host definitions, `nix-darwin` modules, and Home Manager modules live here.

## Core Constraints

- For all real Nix installs, rebuilds, debugging, and mutable validation on macOS, switch to `testaccount`. The password for that user is `testaccount`.
- Non-mutating checks such as reading files, shell syntax checks, or documentation updates may run as the current user.
- This repo runs on multiple machines with different usernames. NEVER hard-code a specific username or home directory (e.g. `/Users/CASE`) in modules, assets, or scripts. Usernames and home paths belong only in `hosts/<name>/default.nix`; everything else derives them from `host.*` / `vars` / `config.home.homeDirectory` in Nix, or `$HOME` in shell/asset files. See "Portability Rule" in `README.md`.
## Overall Approach
- Make conventional commits for all work. Do not push.

- Treat `.ai/plan/` as the full migration surface. Bootstrap is only the entrypoint, not the whole design.
- Keep `AGENTS.md` and `CLAUDE.md` focused on cross-cutting rules that will still matter later. Keep topic-specific decisions in `.ai/plan/`, `README.md`, module files, and code comments where appropriate.
- For each topic, do a deep dive into the existing state, synthesize what is intentional versus stale, and ask the user direct questions in chat when intent is unclear before hard-coding behavior.
- Consult the latest official documentation for Determinate, Nix, `nix-darwin`, and Home Manager before making design decisions.

## Bootstrap Baseline

- The supported first-install path is Determinate Systems only.
- The intended entrypoint is this repo’s local `./install` wrapper, which bootstraps this repo’s flake.
- Do not treat the Determinate repository as configuration state. It is an upstream dependency, not the user’s system definition.

## Determinate + nix-darwin Rule

- When using Determinate with `nix-darwin`, include Determinate’s Darwin module and set `determinateNix.enable = true`.
- Do not build the base system around `nix-darwin`’s normal `nix.*` ownership model when Determinate is active.
- If custom Nix daemon settings are needed later, prefer Determinate’s configuration surface such as `determinateNix.customSettings` rather than reintroducing conflicting `nix-darwin` ownership.

## Validation Standard

- Validate the bootstrap path on a clean macOS install before relying on higher-level modules.
- If Nix is not yet installed on the active machine, expect validation to be limited to static checks until a real install is performed under `testaccount`.

## Decision Log

There exists @DECISIONS.md which you must use upon completing work. What were the major changes that others should know about. What worked? What did not work? Why did it not work? What should others know about your attempt and what should they do differently. You MUST add to this at the end of every single completed session.

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.
             something

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

## Session Log

- [pocket-tts-speak-2026-08-16]: added the managed Gum interface for Kyutai Pocket TTS
  - `speak` owns the complete Pocket CLI surface: speech generation/playback, persistent settings, local server, and voice export. It runs `uvx pocket-tts` internally; user shells never invoke `uvx` directly.
  - `scripts/test-speak.sh`, Zsh syntax checks, and AVA/GROT evaluations pass. Testaccount activation did not run: this CASE session cannot authenticate as `testaccount` (`su` rejects the supplied credential); run `darwin-rebuild switch --flake .#AVA` from an authorized testaccount terminal before using `speak`.
- [pocket-tts-defaults-fix-2026-08-16]: repaired unsafe stale Pocket generation overrides
  - `speak` v1 forced values that no longer match Pocket’s upstream defaults: most critically `--max-tokens 300` versus Pocket’s 50-token limit, which can emit skipped/mumbled text; EOS, noise-clamp, decode-step, and post-EOS overrides were also stale.
  - The wrapper now omits all generation tuning flags unless explicitly configured, so Pocket owns its current defaults. It migrates every v1 settings file by resetting only generation tuning and recording `settings_version=2`; voice, model, device, quantization, and server settings remain intact.
- [pocket-tts-streaming-input-2026-08-16]: `speak < file` now avoids shell argument limits
  - Piped and redirected text is forwarded to Pocket as `--text -`, rather than read into Zsh and copied into an argument; this preserves the CLI’s stdin path for arbitrarily large source files.
  - Pocket still holds the full input then splits it into independent ≤50-token sentence chunks. This avoids `ARG_MAX`, not the upstream long-document prosody limitation.
- [kyutai-tts-speak-2026-08-16]: replaced Pocket TTS with Kyutai TTS 1.6B on MLX; long-form output is machine-verified, never trusted by ear
  - `speak` now wraps `modules/home-manager/assets/speak/kyutai-tts.py` (PEP 723, `uv run --script`, `moshi_mlx==0.2.12` on Python 3.12) deployed to `~/.config/speak/`. Backend choice: Python moshi-mlx over moshi-swift — the Swift repo is an explicitly experimental iOS PoC; the MLX Python path is the maintained one. `kyutai/tts-1.6b-en_fr` bf16; quantization off by default because on M4 Max q8 measured the SAME throughput as bf16 (per-step cost is depformer-launch-bound, not bandwidth-bound), so quantizing only costs quality. Sustained ~1.1x real time.
  - **Long text cannot derail generation by construction.** The model attends over a 500-step (40 s) window and every backend degrades past ~5 min of continuous generation (kyutai-labs/delayed-streams-modeling#106; at exactly 5:27 the MLX ring-KV-cache bug garbles output — 4096 frames @ 12.5 Hz). The script normalizes text (markdown stripped, numbers/currency/times expanded to words), packs sentences into ≤50-word chunks, and generates each chunk with fully reset state and a hard step budget inside the window. Chunks that miss the budget or land outside 0.8–5.0 words/sec retry with a new seed (3 attempts), then abort — garbage is never emitted silently.
  - **Three upstream bugs are encoded in the script, do not "simplify" them away**: (1) `lm_config.transformer.max_seq_len = context` — ring-cache workaround for moshi_mlx ≤ 0.3.0 (DSM PR #108); (2) per-chunk decode uses non-streaming `Mimi.decode`, NEVER `decode_step`, because `reset_state` misses `StreamingAdd` buffers and distorts every generation after the first (kyutai-labs/moshi#407); (3) transformer KV caches are reset explicitly per chunk — 0.2.12's `TTSModel.generate` does not do it. Also avoided: `tts_mlx_streaming.py` chops words (DSM #170); `tts-0.75b-en-public` does not load in moshi_mlx (moshi#422).
  - **Output is verified without listening**: `speak verify` (and `assets/speak/speak-verify.py`) round-trips the WAV through Whisper large-v3-turbo (MLX) and fails on WER > 0.08, degeneration loops, coverage drift, or dead air. Reference proof on the 8,990-word test.txt: 280 chunks, 69.4 min audio, zero chunk retries, WER 0.040, zero loops, zero long silences, speech rate 1.44–3.20 wps, chunk RMS stdev 0.011 (no volume collapse). Every large diff region was ASR orthography ("on site"/"onsite"); the one suspicious 24-word deletion re-transcribed word-perfect in isolation — a known Whisper long-file window artifact, not a speech defect. When a long-file WER looks bad, re-transcribe the flagged window before blaming the TTS.
  - Settings moved to `settings_version=3` (voice + quantize only; Pocket v1/v2 files are reset, not mapped). Curated voice list validated against the live `kyutai/tts-voices` tree. Pocket's `serve`/`export-voice` have no Kyutai-MLX equivalent and were dropped. The two normalizer copies (generator ref-side, verifier hyp-side) MUST stay expansion-identical or WER inflates. First `speak` run downloads ~4 GB of weights.
  - Validated: `scripts/test-speak.sh` PASS; `zsh -n`; AVA + GROT `nix eval` clean; real end-to-end `speak verify` through the shipped wrapper (WER 0.000 on a numbers-heavy sentence) and a real `speak` playback via afplay (exit 0). Testaccount switch not run from this session; artifacts and the 69-min proof WAV live in `~/tmp/kyutai-lab/`.
- [nvim-explorer-visibility-2026-08-17]: Snacks Explorer now opens with hidden and Git-ignored paths visible
  - `modules/home-manager/assets/nvim-lazy/lua/plugins/picker.lua` sets the Explorer source's `hidden` and `ignored` defaults to `true`; `nvim --headless` verified both effective values.
- [cmd-s-save-2026-08-18]: cmd+s now saves in LazyVim; a terminal cannot carry the super key, so Ghostty re-encodes it
  - `assets/ghostty/config` binds `keybind = cmd+s=text:\x1bs` (ESC s = `<M-s>`, the same passthrough pattern as the existing alt+hjkl entries); `nvim-lazy/lua/config/keymaps.lua` maps `<M-s>` to `<cmd>w<cr><esc>` in n/i/x/s, mirroring LazyVim's own `<C-s>`. The user's "same as `<leader>s`" was a misremembering: save is `,s`; `<leader>s` heads the search group (visual `<leader>s` is sort).
  - Ghostty has no default super+s binding (`ghostty +list-keybinds` proves it) and unbound cmd keys never reach the pty as a mappable key; the explicit bind makes delivery deterministic. The nvim half is live instantly (out-of-store symlink); the Ghostty half needs a switch (done — live store copy md5-identical to the repo file) plus `super+shift+,` or a new window in already-running Ghostty instances.
  - Suite: keymaps 296→304, behaviour 16→19 (new checks drive a real `:w` through `<M-s>` from normal and insert, asserting file contents and resulting mode). AVA + GROT eval clean; testaccount-driven switch clean (178 brew deps, HM activation for CASE clean).
  - Gotcha: the harness's `bash` shadows shell `grep` with REGEX semantics — pattern `cmd+s` silently means `cm` + `d+` + `s` and never matches the literal string. Escape it (`cmd\+s`) or use the grep tool when checking literal config lines from the shell.
- [openlogi-cask-2026-08-19]: declared the openlogi cask
  - `modules/darwin/homebrew.nix` adds `openlogi` (cask 0.7.1, auto_updates) to the base casks list — a local-first Logi Options+ alternative for HID++ devices. Placed in the base list, not the `guiAppCasks` optionals: openlogi is already brew-managed on AVA (`brew install --cask` on request today), so there is no manual-.app collision, and it stays tracked on a fresh AVA/GROT. `logi-options-plus` left untouched in the guiAppCasks optionals. Validated: `nix eval` of `config.homebrew.casks` contains `"openlogi"` for both AVA and GROT; `nixfmt --check` clean. Committed; not pushed per the "Do not push" rule.
- [gls-signed-log-2026-08-19]: added the `gls` signed-log function and a tig signature binding
  - `gls` (`shell/init.zsh`) prints a tig-style one-line log — date, author, signature badge, I/M/o marker, refs, subject — color-coded from `%G?`: green `✓` (G), yellow `✓` (U/untrusted), red `✗` (N/unsigned), plus bad/expired/revoked/uncheckable states. Merge/initial markers derived from `%p`. Pages via `less -FRX` only on a tty; passes args through to `git log`.
  - `modules/home-manager/tig.nix` (new, imported in `base.nix`) writes `~/.config/tig/config` binding `V` in the main view to `sh -c 'git verify-commit "$1" 2>&1 && echo SIGNED || echo UNSIGNED …' sh %(commit)`. tig's main view has no signature column (only author/date/commit-title/id/line-number/ref), so on-demand display is the tig-native option. `verify-commit` (exit 0 ⇔ good signature) is used instead of `git show --show-signature`, which just omits the signature block on unsigned commits without an explicit marker.
  - Validated: `zsh -n` + end-to-end `gls` run (signed ✓, unsigned ✗, merge M, initial I markers); `nixfmt --check` clean; AVA + GROT eval render the tig config; expect-driven tig run confirms `V` reports SIGNED on a signed commit and UNSIGNED on an unsigned commit. Static change only; no switch run.
- [herdr-conversation-title-2026-08-20]: conversation titles already drive Herdr pane headers through terminal OSC titles
  - OMP automatic replan renamed this session to `Set herder conversation name as pane name`; Herdr's live `terminal_title_stripped` changed to the same title (apart from its `π` activity prefix). Live Claude and Codex panes expose equivalent stripped terminal titles.
  - Do not call `pane rename` for this: it is a static layout label. A harness that does not emit OSC 0/2 must instead publish its native title through `pane report-metadata --title` with a stable source and agent guard; the existing official integrations only report lifecycle/session identity.
- [herdr-omp-metadata-title-2026-08-20]: OMP conversation names now populate Herdr’s actual pane `title`
  - Corrects the prior terminal-title-only assessment: `terminal_title_stripped` tracks OMP conversation names, but the presentation title remained absent and Herdr named the pane `omp`.
  - `herdr.nix` deploys `herdr-omp-conversation-title.ts` beside Herdr’s managed OMP integration. It polls OMP’s `getSessionName()` (no public title-change event) and reports metadata with `agent=omp` plus `applies_to_source=herdr:omp`; a fresh OMP pane reached `title="Herdr metadata title test"` after a real testaccount switch.
- [editor-lazyvim-2026-08-20]: make the managed LazyVim instance the default editor
  - `shell/init.zsh` exports `EDITOR=nvim` unconditionally. `nvim` is the executable that loads the managed LazyVim configuration; exporting the interactive-only `lazyvim` alias would break non-interactive consumers such as Git.
  - Validated with `zsh -n` and a clean Zsh sourcing assertion.
- [tdna-ssh-routing-2026-08-20]: TDNA GitHub transport now selects the Tech DNA agent key
  - `gitego status` was correct about commit identity, but gitego does not manage SSH transport selection. Git connected as `jryio` because the 1Password agent offered `id_rsa` first, which GitHub accepted before `Tech DNA SSH Key`; `techdna/tdd-toolbox` then correctly rejected that account.
  - `lib/vars.nix` adds the TDNA public-key selector and `git.nix` renders `core.sshCommand = ssh -o IdentitiesOnly=yes -i ~/.ssh/tdna.pub` in TDNA's generated profile fragment. `git pull --dry-run` succeeds with that command. AVA/GROT eval pass; the available `nixfmt` version would reformat pre-existing `git.nix`, so it was not applied. Testaccount activation was not run because `su - testaccount` rejected its credential.
- [lazyvim-vim-banner-2026-08-22]: replace the inherited LunarVim dashboard art with a VIM wordmark
  - `modules/home-manager/assets/nvim-lazy/lua/plugins/dashboard.lua` now renders the same block-style `VIM` banner at every terminal height; no LunarVim landing art remains.
  - Validated with `task test`: boot 60, options 28, keymaps 304, behaviour 19, LSP 12, format 7, and startup 35.465ms (within the 2904.9ms budget).
- [lazyvim-inline-blame-2026-08-22]: show every tracked line’s Git attribution as muted virtual text
  - Gitsigns only supports current-line blame. `FabijanZulj/blame.nvim` supplies the every-line virtual view; `git.lua` opens it only after Gitsigns attaches to the active tracked buffer, switches it across buffers, and renders date + subject in the palette’s Comment colour.
  - `verify_inline_blame.lua` guards the contract by requiring one blame extmark per file line. Full `task test` passes: boot 61, options 28, keymaps 304, behaviour 19, LSP 12, format 7, inline blame 2, startup 29.433ms; bare `stylua` is not on PATH, so use the managed Mason binary.
- [lazyvim-current-line-blame-2026-08-22]: corrected inline blame to follow only the cursor line
  - The all-line `blame.nvim` view consumed the right side of the editor and did not match the requested interaction. Removed its spec, lock pin, test, and local plugin clone; configured Gitsigns’ native `current_line_blame` instead.
  - Gitsigns now appends muted virtual text at the active line’s EOL after 250ms. `verify_current_line_blame.lua` requires exactly one `eol` extmark at the cursor; `task test` passes with boot 60, options 28, keymaps 304, behaviour 19, LSP 12, format 7, current-line blame 3, startup 24.821ms.
- [git-lazyvim-editor-2026-08-23]: Git commit and interactive rebase editing now always use managed LazyVim
  - Root cause: `modules/home-manager/git.nix` explicitly declared `core.editor = "zed --wait"`. Git therefore launched Zed for commit-message editing and, through its fallback chain, interactive rebase todo editing.
  - `core.editor` and `sequence.editor` now use `nvim`; `shell/init.zsh` also exports `EDITOR`, `VISUAL`, `GIT_EDITOR`, and `GIT_SEQUENCE_EDITOR` as `nvim` so inherited automation values such as `true` cannot suppress or supersede the managed editor in an interactive shell.
  - Testaccount-driven AVA switch succeeded. A fresh login Zsh resolves all four variables plus Git's `GIT_EDITOR` and `GIT_SEQUENCE_EDITOR` to `nvim`; `zsh -n` and AVA/GROT editor evaluations pass. Current nixfmt reformats pre-existing `git.nix` layout, so that unrelated drift was left untouched.
- [grbsign-auto-2026-08-28]: added a non-interactive signed rebase alias
  - `grbsign_auto` runs `LEFTHOOK=0 git rebase --gpg-sign --update-refs`; Git signs each rewritten commit without `-i` or `--exec`, so it does not open a sequence or commit editor.
  - AVA and GROT evaluations render the exact alias. An isolated signed rebase succeeded with both editor commands set to fail, then produced a signed commit atop its new base. The required testaccount switch could not start because `su testaccount` rejected its configured credential; the operator must run the switch from an authorized terminal.
- [omp-mutable-config-2026-08-28]: OMP agent configuration is now user-owned with explicit repo import
  - `omp.nix` seeds `~/.omp/agent/config.yml` only when absent and removes only the old Nix-store symlink. Home Manager no longer backs up or replaces a live OMP edit, so the existing `.hm-backup` collision cannot recur.
  - `omp-config-import [--yes] [repo-path]` shows the live-to-repo diff, then copies the approved live file into `modules/home-manager/assets/omp/config.yml`. No other module pulls application changes back automatically: Neovim writes directly through its out-of-store link, Zed seeds once, and Herdr overwrites its config each switch.
  - `zsh -n`, an isolated import with changed YAML, and AVA/GROT activation-script evaluations pass. The privileged switch remains operator-run.
- [markdown-table-only-2026-08-28]: Markdown stays raw except for rendered pipe tables
  - `render-markdown.nvim` now disables every non-table renderer and anti-conceal, so source markup never changes on hover; `pipe_table` remains full-width rendered. Markdown buffers also always set local `wrap`.
  - `verify_markdown.lua` asserts all 18 component, anti-conceal, and wrap invariants; the full LazyVim suite passes (boot 60, options 28, keymaps 304, behaviour 19, LSP 12, format 7, blame 3, Markdown 18, startup 28.461ms).
- [omp-commit-wrapper-2026-09-03]: added `ompcommit` for policy-bound OMP commits
  - `modules/home-manager/shell/omp-commit.zsh` calls `omp commit` with `--push`, `--no-changelog`, and the supplied conventional-commit context. It accepts no user flags, so real invocations cannot disable those defaults.
  - The function uses Bash-compatible syntax inside the managed Zsh startup. Syntax and mocked argument forwarding pass. Home Manager activation was not run.
- [git-auto-setup-remote-2026-09-03]: declare automatic upstream setup for first pushes
  - `git.nix` sets `push.autoSetupRemote = true` with the existing `push.default = "simple"`, so `git push` on a new branch creates the `origin/<branch>` tracking upstream.
  - The rendered AVA setting evaluates to `true`. Home Manager activation was not run.
- [omp-commit-name-2026-09-03]: renamed the OMP commit wrapper to `commit`
  - The managed shell function is now `commit`, replacing `ompcommit`; it keeps the same forced `--push`, `--no-changelog`, and commit-policy context.
  - Bash and Zsh syntax checks pass. A mocked OMP invocation receives the required arguments.
