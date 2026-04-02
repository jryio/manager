# 03 Dotfiles & App Configuration Implementation Plan

This file turns the settled Topic 03 design into an execution plan for the repo.

## Goal

Implement a generic Apple Silicon macOS Home Manager layer that:

- makes this repo the source of truth for user app configuration
- preserves Ghostty, tmux, Neovim, LunarVim, Zed, GitHub CLI tooling, television, jujutsu,
  monitoring tools, and Vale
- ignores Alacritty in the first pass
- replaces Dotbot-owned ongoing dotfile links with Home Manager ownership
- keeps mutable state, caches, restore snapshots, auth files, and editor runtime installs out
  of declarative control

## Preconditions

- Determinate remains the nix-darwin Nix owner via `inputs.determinate.darwinModules.default`
  and `determinateNix.enable = true`.
- Real rebuilds and mutable validation on macOS must run as `testaccount`.
- Topic 02 shell decisions remain authoritative.
- Topic 01 and Topic 15 have not yet fully settled package ownership, so Topic 03 must be
  able to describe config ownership without assuming every binary is already installed by its
  final mechanism.
- Topic 10 and Topic 12 still own the final font and terminfo story.
- Topic 14 still owns long-term Neovim and LunarVim runtime/bootstrap policy.

## Planned Repo Layout

Add or update these files:

- `modules/home-manager/base.nix`
- `modules/home-manager/tmux.nix`
- `modules/home-manager/ghostty.nix`
- `modules/home-manager/github.nix`
- `modules/home-manager/television.nix`
- `modules/home-manager/jujutsu.nix`
- `modules/home-manager/monitoring.nix`
- `modules/home-manager/vale.nix`
- `modules/home-manager/editors.nix`
- `modules/home-manager/zed.nix`

Add managed assets under this repo for copied config:

- `modules/home-manager/assets/nvim/`
- `modules/home-manager/assets/lvim/`
- `modules/home-manager/assets/zed/settings.json`
- `modules/home-manager/assets/zed/keymap.json`
- `modules/home-manager/assets/zed/tasks.json`
- optional helper files such as a tmux compatibility shim if validation requires one

Expected import wiring:

- `modules/home-manager/base.nix` imports the new Topic 03 modules

## Phase 1: Curate the Real Config Surface

Before writing Nix modules, copy only the declarative config that should survive.

Neovim asset rules:

- keep `init.vim`
- keep `autoload/plug.vim` and other real config helpers if Neovim still depends on them
- keep user config such as colors, spell dictionaries, and `coc-settings.json` when still in
  active use
- do not copy `plugged/`
- do not copy `session/`
- do not copy `tmp/undo/`
- do not copy `.DS_Store`
- do not copy generated `plugin/packer_compiled.lua`
- do not make `nvim/config.lua` part of the active target unless Neovim is intentionally
  changed to source it

LunarVim asset rules:

- keep `config.lua`
- keep `lua/`, `plugin/`, colors, `lsp-settings/`, and other real config files
- keep `lazy-lock.json` only if it is intentionally part of the preserved runtime story
- do not copy `session/`
- do not copy `.DS_Store`
- do not copy stale profile-specific wrappers such as `lvim/bin/lvim.work`
- do not copy runtime install trees from `~/.local/share/lunarvim`

Other asset rules:

- copy the current Ghostty config source
- copy the current Vale files
- copy raw Zed seed files exactly as they exist today
- do not copy `gh/hosts.yml`
- do not copy `btop.log`
- do not copy Zed conversation or backup files

## Phase 2: Replace Dotbot Ownership with Home Manager Ownership

Implement Home Manager modules that become the long-term owner of ongoing config.

tmux:

- enable `programs.tmux`
- translate the current tmux behavior into a combination of module options and
  `programs.tmux.extraConfig`
- move plugin ownership to `programs.tmux.plugins`
- use nixpkgs tmux plugins for `yank`, `sessionist`, `resurrect`, `continuum`, `battery`,
  and `online-status`
- remove TPM bootstrap and any `run '~/.tmux/plugins/tpm/tpm'` line
- preserve restore behavior but drop terminal auto-launch on boot

Ghostty:

- enable `programs.ghostty`
- translate the current config into `programs.ghostty.settings`
- leave Alacritty out of the first pass

GitHub CLI and dashboard:

- enable `programs.gh`
- declare `programs.gh.settings`
- keep `hosts.yml` local-only
- enable `programs.gh-dash` when package ownership is available

television:

- enable `programs.television`
- declare `settings`
- translate custom channels only if they are intentionally curated, not just because
  `default_channels.toml` exists today

jujutsu:

- enable `programs.jujutsu`
- declare settings after identity ownership is aligned with Topic 04

monitoring tools:

- use `programs.btop.settings`
- use `programs.htop.settings`
- do not manage runtime logs

Vale:

- manage `.vale.ini` via `home.file`
- manage `~/.config/vale` via `xdg.configFile`

## Phase 3: Preserve Editors Without Replacing Them

Topic 03 should preserve current editor config rather than redesign it.

Neovim:

- declare the curated `nvim/` tree with `xdg.configFile`
- do not migrate to `programs.neovim.plugins` in the first pass
- do not try to replace `vim-plug` yet

LunarVim:

- declare the curated `lvim/` tree with `xdg.configFile`
- do not manage `~/.local/share/lunarvim`
- do not manage `~/.cache/lvim`
- do not take ownership of the live `~/.local/bin/lvim` launcher in Topic 03

This keeps Topic 03 scoped to configuration and avoids prematurely solving Topic 14.

## Phase 4: Seed Zed Once, Then Leave It Mutable

Do not model Zed settings as a permanently merged declarative JSON baseline.

Instead:

- store seed copies of `settings.json`, `keymap.json`, and `tasks.json` in this repo
- add Home Manager activation steps that copy each file into place only when the target file
  does not already exist
- leave subsequent edits to Zed itself

Do not manage:

- `~/.config/zed/conversations`
- Zed backup files

Optional later work:

- use `programs.zed-editor` for package ownership and extension installation once Topic 01
  settles package policy

## Phase 5: Handle tmux Compatibility Carefully

Home Manager's tmux module writes `~/.config/tmux/tmux.conf`.

Implementation rule:

- validate whether the target tmux build on macOS consumes that XDG path directly
- if it does, keep the Home Manager default
- if it does not, add a minimal managed `~/.tmux.conf` that sources
  `~/.config/tmux/tmux.conf`

Do not keep the old full `~/.tmux.conf` as the canonical handwritten config once the module
translation is complete.

## Phase 6: Remove Dotbot Carry-Over for This Topic

Once Home Manager replacements are in place, Topic 03 should no longer depend on Dotbot for:

- `~/.tmux.conf`
- `~/.vale.ini`
- `~/.config/nvim`
- `~/.config/lvim`
- any ongoing app-config symlink ownership that Home Manager now replaces

Do not let Topic 03 implementation silently preserve Dotbot as a second owner of the same
files.

## Validation

Static validation in the repo:

- confirm new Home Manager modules are imported by `modules/home-manager/base.nix`
- confirm there is no attempt to manage auth files, logs, restore snapshots, or editor cache
  trees
- confirm the curated editor assets exclude stateful directories such as `plugged/`,
  `session/`, `tmp/undo/`, and `~/.local/share/lunarvim`
- run `git diff --check`
- run a flake evaluation that confirms the new Home Manager modules compose cleanly

Mutable validation on macOS, under `testaccount`:

1. Run the rebuilt configuration from this repo checkout as `testaccount`.
2. Confirm Ghostty config is installed under the expected XDG path and validates cleanly.
3. Confirm tmux starts without any dependency on `~/.tmux/plugins/tpm`.
4. Confirm tmux packaged plugins load and statusline behavior still works.
5. Confirm tmux restore data remains local under `~/.tmux/resurrect`.
6. Confirm no terminal auto-launch-on-boot behavior remains.
7. Confirm `gh/config.yml` is managed while `gh/hosts.yml` is untouched.
8. Confirm Zed seed files are copied on first activation when absent.
9. Confirm a second activation does not overwrite later user edits to those Zed files.
10. Confirm Neovim and LunarVim config trees exist without dragging in runtime state
    directories.
11. Confirm Vale, `btop`, `htop`, and television config files land in the expected paths.
12. Confirm no Topic 03 module writes secret-bearing files or app history/conversation data.

## Acceptance Criteria

The Topic 03 implementation is complete when all of the following are true:

- Home Manager owns the intended ongoing app-config surface
- Ghostty is the terminal config carried into the target state
- Alacritty is not part of the first-pass Topic 03 target
- tmux no longer depends on TPM clones under `~/.tmux/plugins`
- tmux packaged plugins replace the current cloned plugin set where nixpkgs already provides
  them
- tmux restore support remains available without terminal boot auto-launch
- Neovim and LunarVim are preserved without being redesigned
- editor state, caches, and runtime installs are not checked into the declarative target
- `gh/hosts.yml` remains local-only
- Zed settings, keymaps, and tasks are seeded once and remain user-mutable afterward
- this repo, not `~/dotfiles`, is the source of truth for the managed Topic 03 config

## Deferred Work

These items are explicitly not part of the first Topic 03 implementation:

- replacing Neovim or LunarVim with a different editor stack
- translating Neovim into Home Manager's Neovim plugin model
- taking ownership of the live LunarVim launcher under `~/.local/bin/lvim`
- carrying Alacritty into the new target
- managing Zed conversations or backup files
- declaring `gh/hosts.yml`
- declaring tmux restore snapshots
- deciding the final package source for Ghostty, Zed, `gh-dash`, television, jujutsu, tmux,
  `btop`, and `htop`
- solving fonts or terminfo beyond documenting the dependency

## Suggested Commit Breakdown

If Topic 03 is implemented incrementally, use small commits in this order:

1. add Topic 03 Home Manager module scaffolding and imports
2. curate and add copied config assets for Ghostty, editors, Vale, and Zed seed files
3. implement tmux translation with packaged plugins and no TPM dependency
4. add GitHub CLI, television, monitoring, and Vale modules
5. add one-time Zed seeding and final validation
