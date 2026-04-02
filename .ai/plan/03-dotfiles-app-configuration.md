# 03 Dotfiles & App Configuration

Topic source: `OVERVIEW.md` line 107
Sub-agent status: completed
Result type: per-topic design memo updated against live state, settled decisions, and
official documentation

## Summary

This topic is the user-level configuration surface under `$HOME` and `~/.config`: tmux,
Ghostty, Neovim, LunarVim, Zed, GitHub CLI tools, television, jujutsu, monitoring tools,
Vale, and the remaining Dotbot-linked app config. For this topic, Home Manager is the
default owner. nix-darwin should stay narrow and own only package installation or system
integration when a tool needs it.

The topic-level direction is now much more specific than the old memo:

- Ghostty is the only terminal config that matters for the target state. Ignore Alacritty in
  the first Topic 03 migration pass.
- Neovim and LunarVim should both be preserved for now. Do not try to replace either editor
  or redesign their runtime model in Topic 03.
- tmux should move away from TPM-managed plugin clones and into Home Manager-managed tmux
  plugins where nixpkgs already packages them.
- Zed should be seeded from the current live files once, then allowed to mutate those files
  over time instead of being forced back to a fully declarative JSON state on every
  activation.

## Confirmed Decisions

- Home Manager is the default owner for user dotfiles and per-app config in this topic.
- nix-darwin should stay narrow and should not be the main owner of ordinary user config
  files.
- Ghostty is the only terminal config that should be carried into the new-mac target for
  Topic 03.
- Alacritty is intentionally ignored in the first Topic 03 migration pass, even though it is
  still present in `~/dotfiles` and the live home directory today.
- Neovim and LunarVim both stay for now. Topic 03 should preserve them rather than replace
  them.
- Topic 03 should not migrate editor caches, session files, plugin checkouts, generated
  plugin artifacts, or other mutable runtime state into the declarative target.
- tmux should move from TPM clones under `~/.tmux/plugins` to Home Manager `programs.tmux`
  with nixpkgs tmux plugins where available.
- tmux restore state may remain local and mutable, but automatic terminal launch on boot
  should be dropped.
- Zed settings, keymaps, and tasks should be copied into place initially from the current
  live files, then left mutable. Topic 03 should not use a declarative merge mechanism that
  overwrites later user edits on every activation.
- Authentication-bearing files such as `~/.config/gh/hosts.yml` stay out of declarative
  config.

## Current State

The current state is split between:

- tracked config inside `~/dotfiles`
- Dotbot bootstrap and link behavior in `~/dotfiles/install*`
- live files in `$HOME` and `~/.config` that are not repo-backed
- substantial amounts of runtime/editor state that have drifted into the tracked Neovim and
  LunarVim trees

### Dotbot and Bootstrap Behavior

`~/dotfiles/install` runs Dotbot over `default.conf.yaml`, then optional profile configs,
then `brew.conf.yaml`. Within Topic 03 scope, the important Dotbot behavior today is:

- links `~/.tmux.conf` to `tmux/tmux.conf`
- links `~/.vale.ini` to `vale/vale.ini`
- links `~/.config/nvim` to `nvim`
- links `~/.config/lvim` to `lvim`
- links `~/.config/alacritty/alacritty.toml` to `alacritty/alacritty.toml`
- links `~/.functions` and `~/.scripts`
- links `~/.local/bin/lvim` to either `lvim/bin/lvim.personal` or `lvim/bin/lvim.work`
- installs LunarVim imperatively if `~/.local/bin/lvim` is absent
- clones Packer imperatively
- compiles the custom `xterm-256color-italic` terminfo entry
- copies Operator Mono fonts into `~/Library/Fonts`
- runs `shell/macos.sh`

Important omissions and drift:

- Dotbot does not link Ghostty at all, even though the live machine currently has
  `~/.config/ghostty/config` symlinked into `~/dotfiles/ghostty/config`.
- Dotbot does not manage any live config for Zed, `gh`, `gh-dash`, television, jujutsu,
  `btop`, or `htop`.
- The current live `~/.local/bin/lvim` is not a symlink to `~/dotfiles`. It is an
  installer-managed wrapper that differs from both tracked `lvim/bin/*` scripts.

### Live Config Inventory

Repo-backed live symlinks today:

- `~/.tmux.conf -> ~/dotfiles/tmux/tmux.conf`
- `~/.vale.ini -> ~/dotfiles/vale/vale.ini`
- `~/.config/nvim -> ~/dotfiles/nvim`
- `~/.config/lvim -> ~/dotfiles/lvim`
- `~/.config/alacritty/alacritty.toml -> ~/dotfiles/alacritty/alacritty.toml`
- `~/.config/ghostty/config -> ~/dotfiles/ghostty/config`

Live config files that are not repo-backed in `~/dotfiles`:

- `~/.config/gh/config.yml`
- `~/.config/gh/hosts.yml`
- `~/.config/gh-dash/config.yml`
- `~/.config/television/config.toml`
- `~/.config/television/default_channels.toml`
- `~/.config/jj/config.toml`
- `~/.config/zed/settings.json`
- `~/.config/zed/keymap.json`
- `~/.config/zed/tasks.json`
- `~/.config/btop/btop.conf`
- `~/.config/htop/htoprc`

Live mutable state that is intentionally not ordinary declarative config:

- `~/.tmux/plugins/*`
- `~/.tmux/resurrect/*`
- `~/.config/gh/hosts.yml`
- `~/.config/zed/conversations/*`
- `~/.config/zed/settings_backup.json`
- `~/.config/zed/keymap_backup.json`
- `~/.config/btop/btop.log`
- `~/.local/share/nvim/*`
- `~/.local/state/nvim/*`
- `~/.local/share/lunarvim/*`
- `~/.cache/lvim/*`

### tmux

The current `tmux/tmux.conf` is active via `~/.tmux.conf` and still assumes TPM:

- it ends with `run '~/.tmux/plugins/tpm/tpm'`
- it declares the following tmux-plugins plugins:
  - `tpm`
  - `tmux-yank`
  - `tmux-sessionist`
  - `tmux-resurrect`
  - `tmux-continuum`
  - `tmux-battery`
  - `tmux-online-status`
- it stores the 1Password SSH agent socket in tmux's environment
- it uses `xterm-256color-italic`
- it sets `@continuum-boot-options 'alacritty,fullscreen'`

Observed live state:

- `~/.tmux/plugins` contains actual git clones for those plugins.
- `~/.tmux/resurrect` contains restore snapshots and a `last` symlink.
- `~/.tmux-osx.conf` exists as a zero-byte file and is not referenced by the tracked tmux
  config.

### Ghostty and Alacritty

Current live state:

- Ghostty is active and symlinked to `~/dotfiles/ghostty/config`.
- The live Ghostty config matches the tracked file byte-for-byte.
- Alacritty is also still linked and tracked today, but it is intentionally out of scope for
  the target Topic 03 migration.

Ghostty-specific details that matter:

- the config depends on `OperatorMono Nerd Font Mono`
- the config sets `term = xterm-256color-italic`
- the config contains a large custom keybinding set

This makes Ghostty cross-topic with fonts and terminfo.

### Neovim and LunarVim

The current editor situation is mixed and includes both declarative config and tracked state.

Neovim:

- `nvim/init.vim` is still the active top-level config file.
- `nvim/init.vim` auto-downloads `autoload/plug.vim` if it is missing and uses `vim-plug`
  with `~/.config/nvim/plugged`.
- the tracked `nvim/` tree also contains:
  - `autoload/plug.vim`
  - `autoload/utils.vim`
  - `coc-settings.json`
  - colors and spell files
  - `plugged/` plugin checkouts
  - `session/` files
  - `tmp/undo/` state
  - `plugin/packer_compiled.lua`
  - `lazy-lock.json`
  - `config.lua`
- `nvim/config.lua` contains LunarVim-style `lvim.*` settings and is not sourced by
  `init.vim`. It is historical drift, not an active Neovim entrypoint.

LunarVim:

- `~/.config/lvim` is a symlink to `~/dotfiles/lvim`.
- the tracked `lvim/` tree contains real config such as `config.lua`, `lua/`,
  `lsp-settings/`, `plugin/`, colors, and `lazy-lock.json`.
- the tracked tree also contains `session/` state that should not be carried into the new
  declarative target.
- `lvim/bin/lvim.personal` and `lvim/bin/lvim.work` are tracked wrapper scripts, but the
  live `~/.local/bin/lvim` is an installer-managed wrapper that differs from them.
- `lvim/bin/lvim.work` hardcodes `/Users/bigbrother` and is stale for a generic Apple
  Silicon macOS target.

The important correction is that Topic 03 should preserve both editors, but it should not
pretend the entire current tracked trees are clean declarative config.

### Zed

Zed is active but completely outside `~/dotfiles` today.

Observed live files:

- `~/.config/zed/settings.json`
- `~/.config/zed/keymap.json`
- `~/.config/zed/tasks.json`
- `~/.config/zed/conversations/*`
- `~/.config/zed/settings_backup.json`
- `~/.config/zed/keymap_backup.json`

Notable hidden dependency:

- the current `tasks.json` includes a `files` task that runs `zed "$(tv files)"`, so current
  Zed tasks depend on television being present.

Important implementation consequence from the official Home Manager module:

- `programs.zed-editor.mutableUserSettings`, `mutableUserKeymaps`, and `mutableUserTasks`
  still merge the Nix-managed baseline back into the live files on every activation.
- that is not the same as "seed once, then let Zed own the files."
- for this repo's stated requirement, Topic 03 should use a one-time copy-if-missing
  activation step for the seed files rather than those mutable merge options.

### GitHub CLI, gh-dash, television, jujutsu, btop, htop, and Vale

Current live state:

- `gh` has live `config.yml` plus auth-bearing `hosts.yml`
- `gh-dash` has a live `config.yml`, but `gh-dash` is not currently on `PATH`
- television has live `config.toml` plus `default_channels.toml`
- `jj` has a small live `config.toml`
- `btop` has live `btop.conf` plus `btop.log`
- `htop` has live `htoprc`
- Vale is repo-backed today through `~/.vale.ini` and `~/.config/vale`

Important drift:

- the current Brewfiles declare `gh`, `htop`, `tmux`, `neovim`, and `vale`, but they do not
  declare Ghostty.
- the Brewfiles still declare Alacritty, which the target Topic 03 plan now ignores.
- `gh-dash` has live config but no installed binary in the observed shell environment.

## Official Surface Check

Relevant current official documentation confirms the following:

- Determinate's nix-darwin guidance still requires using the Determinate Darwin module and
  `determinateNix.enable = true` so nix-darwin does not re-own Nix configuration.
- the current nix-darwin manual still exposes the expected narrow Darwin-side surfaces for
  this topic, such as package and Homebrew ownership, rather than ordinary user dotfile
  ownership
- Home Manager has first-class modules for:
  - `programs.tmux`
  - `programs.ghostty`
  - `programs.gh`
  - `programs.gh-dash`
  - `programs.television`
  - `programs.jujutsu`
  - `programs.zed-editor`
  - `programs.btop`
  - `programs.htop`
  - `programs.neovim`
- the Home Manager tmux module supports packaged tmux plugins via `programs.tmux.plugins`
- nixpkgs currently packages the tmux plugins this config needs:
  - `battery`
  - `continuum`
  - `online-status`
  - `resurrect`
  - `sessionist`
  - `yank`

The caveat is important: module availability does not imply module suitability for every
current file. In particular:

- `programs.neovim` is not the right first-pass owner of this repo's existing Neovim and
  LunarVim config trees because the user explicitly does not want those editors replaced
  right now.
- `programs.zed-editor` is useful for package ownership and future extension management, but
  its mutable settings merge is not a true "copy once then leave mutable forever" mechanism.

## nix-darwin Surface

For Topic 03, nix-darwin should remain narrow:

- install packages or casks when Topic 01 and Topic 15 settle their ownership
- provide any machine-level system integration that a package truly needs
- do not own ordinary user config files for tmux, Ghostty, Zed, Neovim, LunarVim, `gh`, or
  the other per-user tools in this topic

With Determinate active, Topic 03 should continue to avoid reintroducing conflicting
`nix.*` ownership.

## Home Manager Surface

Home Manager is the right owner for almost all of Topic 03:

- `programs.tmux` for tmux core config and packaged plugins
- `programs.ghostty` for Ghostty config
- `programs.gh` for `gh` config, excluding `hosts.yml`
- `programs.gh-dash` for dashboard config
- `programs.television` for `config.toml` and curated custom channels
- `programs.jujutsu` for `jj` config once identity ownership is decided
- `programs.btop` and `programs.htop` for monitoring config
- `programs.zed-editor` only where its module behavior matches the intended ownership model
- `home.file` and `xdg.configFile` for copied editor trees, Vale files, one-time Zed seed
  assets, and any other config without a safe first-class module translation

## Target Ownership Split

Use Home Manager modules directly for:

- tmux
- Ghostty
- `gh`
- `gh-dash`
- television
- jujutsu
- `btop`
- `htop`

Use `home.file` or `xdg.configFile` for:

- Neovim config tree in the first pass
- LunarVim config tree in the first pass
- `.vale.ini` and `~/.config/vale`
- any compatibility shims such as a fallback `~/.tmux.conf` source file if validation shows
  it is needed
- one-time Zed seed assets and activation logic

Keep out of scope for declarative ownership in Topic 03:

- Alacritty
- `~/.config/gh/hosts.yml`
- `~/.config/zed/conversations/*`
- Zed backup files
- `~/.tmux/plugins/*`
- `~/.tmux/resurrect/*`
- editor cache/state/runtime trees under `~/.local/share`, `~/.local/state`, and `~/.cache`
- Neovim `plugged/`, session files, undo history, generated `packer_compiled.lua`, and other
  runtime artifacts
- LunarVim session files and runtime installation under `~/.local/share/lunarvim`
- the live `~/.local/bin/lvim` launcher until Topic 14 decides how LunarVim itself should be
  installed and wrapped

## Tool-by-Tool Target

### tmux

Target owner:

- `programs.tmux`

Target shape:

- translate the tracked tmux config semantically into Home Manager options plus
  `programs.tmux.extraConfig`
- replace TPM plugin cloning with `programs.tmux.plugins`
- use packaged nixpkgs tmux plugins instead of `~/.tmux/plugins/*` clones
- preserve tmux restore support through the packaged `resurrect` and `continuum` plugins
- keep restore snapshots local and mutable under `~/.tmux/resurrect`
- remove `run '~/.tmux/plugins/tpm/tpm'`
- remove `@continuum-boot-options 'alacritty,fullscreen'`

Open implementation caveat:

- Home Manager writes tmux config to `~/.config/tmux/tmux.conf`. Validation must confirm the
  target tmux build on macOS consumes that path as expected. If not, add a small managed
  `~/.tmux.conf` shim that sources the XDG path.

### Ghostty

Target owner:

- `programs.ghostty`

Target shape:

- translate the current tracked Ghostty config into `programs.ghostty.settings`
- keep Ghostty as the only terminal config in Topic 03
- do not carry Alacritty into the new target

Cross-topic dependencies:

- Topic 10 for fonts
- Topic 12 or Topic 10 for `xterm-256color-italic` terminfo handling
- Topic 01 and Topic 15 for package installation ownership
- Topic 02 if Ghostty shell integration is enabled through Home Manager

### Neovim

Target owner in the first pass:

- `xdg.configFile` or `home.file`, not `programs.neovim.plugins`

Target shape:

- preserve the current Neovim configuration style instead of translating it into Home
  Manager's Neovim plugin/module model
- copy only curated declarative config into this repo
- do not carry vendored plugin checkouts, sessions, undo history, `.DS_Store`, or generated
  artifacts into the managed target
- treat `nvim/config.lua` as historical drift unless `init.vim` is intentionally changed to
  source it later

Cross-topic dependency:

- Topic 14 owns the long-term story for Neovim runtime tooling, plugin bootstrap, and
  provider dependencies

### LunarVim

Target owner in the first pass:

- `xdg.configFile` or `home.file` for config only

Target shape:

- preserve the current LunarVim config tree
- do not declare `~/.local/share/lunarvim`
- do not declare `~/.cache/lvim`
- do not treat the current live `~/.local/bin/lvim` wrapper as settled declarative state
- do not carry stale profile-specific launchers such as `lvim/bin/lvim.work` into the
  generic target

Cross-topic dependency:

- Topic 14 owns how LunarVim itself is installed, updated, or wrapped

### Zed

Target owner:

- mixed ownership

Use Home Manager for:

- package installation later if Topic 01 chooses it
- optional future extension management if the repo decides to make extensions declarative

Do not use declarative merge ownership for the live settings files in the first pass.
Instead:

- store seed copies of the current `settings.json`, `keymap.json`, and `tasks.json` in this
  repo
- add an activation step that copies each file into place only if it does not already exist
- leave the live files mutable after that initial seed

Never declaratively manage:

- `~/.config/zed/conversations`
- Zed backup files

### GitHub CLI and gh-dash

Target owner:

- `programs.gh`
- `programs.gh-dash`

Target shape:

- declare `gh/config.yml`
- leave `gh/hosts.yml` local and unmanaged
- declare `gh-dash/config.yml`
- let Home Manager register `gh-dash` as a gh extension when package ownership is in place

### television

Target owner:

- `programs.television`

Target shape:

- declare `config.toml`
- do not blindly copy `default_channels.toml` into the target just because it exists today
- if specific custom channels are desired later, translate them deliberately into
  `programs.television.channels`

Cross-topic dependencies:

- Topic 02 for shell integration
- Topic 14 for any runtime tools those channels depend on
- Zed task seeding currently depends on the `tv files` command existing

### jujutsu

Target owner:

- `programs.jujutsu`

Target shape:

- declare `jj` config through the module once identity ownership is settled
- keep the module because it handles Darwin path differences across jj versions cleanly

Cross-topic dependency:

- Topic 04 should decide whether jj user identity is declared alongside Git identity or
  separately

### btop and htop

Target owner:

- `programs.btop`
- `programs.htop`

Target shape:

- declare the config files
- keep runtime logs out of declarative ownership

### Vale

Target owner:

- `home.file` for `~/.vale.ini`
- `xdg.configFile` for `~/.config/vale`

Target shape:

- preserve the current styles tree as config
- do not treat generated or transient files as part of the managed target

## State and Secrets Boundary

Topic 03 must distinguish sharply between config and mutable state.

Config that belongs in the repo:

- tmux commands and plugin settings
- Ghostty settings
- curated Neovim and LunarVim config files
- `gh/config.yml`
- `gh-dash/config.yml`
- television `config.toml`
- `jj/config.toml`
- Zed seed files
- `btop.conf`
- `htoprc`
- `vale.ini` and Vale rules

Mutable state that must stay out:

- auth tokens, account registrations, and other secret-bearing files
- tmux restore snapshots
- editor sessions and undo history
- plugin checkouts and editor runtime install trees
- Zed conversations and backups
- log files

## Cross-Topic Blockers

- Topic 01 and Topic 15 must settle package ownership for Ghostty, Zed, `gh-dash`,
  television, jujutsu, tmux, `btop`, `htop`, and the remaining CLI/UI tools in this topic.
- Topic 10 and Topic 12 must settle the font and terminfo story that Ghostty and tmux still
  depend on.
- Topic 14 must settle Neovim and LunarVim runtime/bootstrap ownership, including whether
  plugin bootstrap stays imperative, becomes a documented one-time step, or later becomes
  more declarative.
- Topic 04 should align jujutsu identity with Git identity so the repo does not create two
  competing user identity policies.
- Topic 11 continues to own secret-bearing or auth-bearing files such as `gh/hosts.yml`.

## Recommended Split

Use Home Manager as the default owner of app config. Prefer first-class Home Manager modules
where the module behavior matches the intended ownership model. Use `home.file` or
`xdg.configFile` where compatibility matters more than translation, especially for Neovim,
LunarVim, Vale, and the one-time Zed seed files.

Do not carry Alacritty, TPM clones, editor state directories, restore snapshots, logs,
backup files, or auth-bearing files into the new declarative target.

## Migration Notes

The first Topic 03 implementation should be compatibility-first and selective:

- bring current app config into this repo as the source of truth
- preserve Ghostty, tmux, Neovim, LunarVim, Zed, GitHub CLI tooling, television, jujutsu,
  monitoring tools, and Vale
- intentionally exclude mutable runtime state and stale tracked drift
- stop relying on Dotbot for ongoing dotfile ownership
- leave package ownership, fonts, terminfo, and deeper editor-runtime decisions to their
  corresponding topics where they are not yet settled

The important correction from the audit is that the migration target is not "copy everything
under `~/dotfiles`." It is "copy only the actual declarative config surface and explicitly
leave state, caches, bootstrap artifacts, and stale history behind."

## Supporting References

Repo and live-state references:

- `~/dotfiles/install`
- `~/dotfiles/install-configs/default.conf.yaml`
- `~/dotfiles/install-configs/personal.conf.yaml`
- `~/dotfiles/install-configs/work.conf.yaml`
- `~/dotfiles/tmux/tmux.conf`
- `~/dotfiles/ghostty/config`
- `~/dotfiles/nvim/*`
- `~/dotfiles/lvim/*`
- `~/dotfiles/vale/*`
- live files under `~/.config/{gh,gh-dash,television,jj,zed,btop,htop}`

Official documentation and primary sources:

- Determinate nix-darwin guide:
  - <https://docs.determinate.systems/guides/nix-darwin/>
- nix-darwin manual:
  - <https://nix-darwin.github.io/nix-darwin/manual/index.html>
- Home Manager module sources:
  - <https://github.com/nix-community/home-manager/blob/release-25.11/modules/programs/tmux.nix>
  - <https://github.com/nix-community/home-manager/blob/release-25.11/modules/programs/ghostty.nix>
  - <https://github.com/nix-community/home-manager/blob/release-25.11/modules/programs/gh.nix>
  - <https://github.com/nix-community/home-manager/blob/release-25.11/modules/programs/gh-dash.nix>
  - <https://github.com/nix-community/home-manager/blob/release-25.11/modules/programs/television.nix>
  - <https://github.com/nix-community/home-manager/blob/release-25.11/modules/programs/jujutsu.nix>
  - <https://github.com/nix-community/home-manager/blob/release-25.11/modules/programs/zed-editor.nix>
  - <https://github.com/nix-community/home-manager/blob/release-25.11/modules/programs/btop.nix>
  - <https://github.com/nix-community/home-manager/blob/release-25.11/modules/programs/htop.nix>
  - <https://github.com/nix-community/home-manager/blob/release-25.11/modules/programs/neovim.nix>
- nixpkgs tmux plugin set:
  - <https://github.com/NixOS/nixpkgs/blob/nixpkgs-25.11-darwin/pkgs/misc/tmux-plugins/default.nix>

## Notes

This topic has a high payoff because it removes a lot of implicit home-directory drift, but
it also has a high risk of accidental overreach. The correct first pass is not a full editor
or runtime redesign. It is a careful transfer of real configuration into Home Manager while
leaving stateful data and package/runtime policy to the topics that actually own them.
