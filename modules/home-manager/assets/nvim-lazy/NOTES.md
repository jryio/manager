# Migration notes — LunarVim → LazyVim

Findings that contradict the migration plan, discovered by dumping real keymap
state (`tests/baseline/*.json`, captured Phase 0 against LazyVim 16.0.0).
Later phases should trust this file over the original plan.

## Corrections to the plan

- **`nvim -l` skips the user config.** Every test must run as
  `nvim --headless -c "luafile tests/<t>.lua" -c qa`. Under `-l`, LazyVim is
  never loaded and all assertions pass vacuously.
- **LazyVim's keymaps load on `User VeryLazy`**, which never fires headlessly
  (146 → 239 normal-mode maps once raised). `helpers.settle()` raises it.
- **`<A-j>` and `<M-j>` are the same key.** Neovim canonicalises both to
  `<M-j>`. LazyVim's move-line maps are therefore already on `<M-j>`/`<M-k>` in
  normal, insert and visual modes. Jacob's normal-mode resize maps override the
  normal ones by assignment; insert and visual need an explicit delete.
- **`<C-h/j/k/l>` window navigation is NOT a LazyVim 16 default** (the plan
  marked it ✔). It must be added, in normal and terminal modes both.
- **Visual `<` → `<gv` is not a default** either; only `>` → `>gv` ships.
- **LazyVim 16's default explorer is snacks, not neo-tree.** `<leader>e` maps to
  `<leader>fe` (Explorer Snacks). Decision 4 assumed neo-tree was the default —
  needs Jacob's call at Phase 5.
- **Grep is `<leader>sg`, not `<leader>st`** (`<leader>st` is Todo). Affects the
  Phase 2 rationale for putting comment-toggle on `<leader>/`.
- **`<leader>L` is already taken** (LazyVim Changelog), so moving Lazy from
  `<leader>l` to `<leader>L` displaces it.
- **`<leader>n` is Notification History** in LazyVim, colliding with the planned
  `+NvimTree` group (Phase 5).
- **LunarVim's leader maps never become real keymaps** — which-key holds them in
  its own tables, so `tests/baseline/lvim-keymaps.json` contains none of them.
  `assets/lvim/config.lua` is the only authority for leader bindings.

## Options (phase 1)

- **LazyVim has no formatoptions autocmd.** It assigns `opt.formatoptions` once,
  so the planned `nvim_del_augroup_by_name` counterpart to LunarVim's
  `_format_options` deletion is unnecessary.
- **Filetype plugins amend formatoptions per buffer, under lvim too.** In a Lua
  buffer lvim lands on `vjncroql`, because `ftplugin/lua.vim` drops `t` and adds
  `o` — his configured `qcrntjlv` is the global default, not what he types
  against. Forcing the set per buffer would be a behaviour *change*, so the
  global is set and the test asserts both values.
- **`LazyVim.set_default` cannot see user options.** It records its baseline
  after `lua/config/options.lua` runs, so `foldmethod = "manual"` is
  indistinguishable from LazyVim's own default and gets overwritten to `expr`
  once treesitter attaches. This surfaced as a flaky test — it only fires once
  the parser is installed. Fixed by disabling the fold features themselves in
  `lua/plugins/folds.lua`; treesitter reads `folds.enable`, the LSP spec reads
  `folds.enabled`.
- **Buffer-local `foldexpr` is nvim's, not LazyVim's.** `ftplugin/lua.lua`
  installs `v:lua.vim.treesitter.foldexpr()`; lvim shows exactly the same value,
  and it is inert under `foldmethod=manual`. Only the global is asserted.
- **lvim never set `spellfile`** — the legacy config did, so words added with
  `zg` in lvim go nowhere today. Phase 1 restores it, and the dictionary moved
  to `spell/dictionary.utf-8.add` beside the config, where Phase 9's
  `mkOutOfStoreSymlink` keeps it writable.
- **`spelllang` needs no action**: lvim resolves to `en`, same as LazyVim.
- LazyVim soft-wraps prose filetypes via its `lazyvim_wrap_spell` augroup;
  neither lvim nor the legacy config wrapped. Replaced with a spell-only
  autocmd, which is what the legacy config had for markdown.

## Flagged for Jacob (out of scope for the behaviour-preserving migration)

- `assets/lvim/config.lua`'s avante block references 1Password vault
  `ifpq6udm2wag2mo3ipcoiu666e`, which no longer exists — capturing the lvim
  baseline printed `isn't a vault in this account`. The Claude API key lookup in
  today's lvim is already broken. Needs a current vault ID at Phase 8.
- avante's pinned model `claude-3-5-sonnet-20241022` is long superseded.
- avante in lvim also warns that its whole `claude = { ... }` block moved under
  `providers.claude`, with `temperature` and `max_tokens` under
  `providers.claude.extra_request_body`. Porting the spec verbatim at Phase 8
  carries these deprecations across; migrating the schema is a separate call.
