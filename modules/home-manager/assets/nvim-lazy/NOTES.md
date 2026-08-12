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
  `lua/plugins/parity.lua`; treesitter reads `folds.enable`, the LSP spec reads
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

## Keymaps (phase 2)

- **`c` was dead in lvim.** lvim maps `c` to `<NOP>`, so `c`, `cw`, `ciw` and
  `cc` do nothing at all today. The legacy config used register x. Both were
  reaching for "change without clobbering the yank", so `c` is now `"_c`.
- **`cw` needs the black hole spelled out.** Non-recursive plain `ce` clobbers
  the register that `c` exists to protect — a functional test caught it, the
  mapping assertion did not. Phase 3 settles on `"_ce`; see below for why
  recursion is not the answer. `dw` stays non-recursive, matching lvim.
- **Treesitter indent broke `S` parity.** LazyVim's treesitter indent reindents
  the new line, so `S` on `abcdef` left `abc` / `  def` where lvim leaves
  `abc` / `def`. The same gap would show on every `o`, `O` and `=`, so
  `lua/plugins/parity.lua` turns treesitter indent off and lvim's classic
  ftplugin indent stands.
- **Visual `L` is `$`, not `g_`.** lvim and the legacy config disagree here, and
  decision 5 gives it to lvim. The plan's table noted the legacy `g_` in
  passing; changing it is a one-line edit if he misses it.
- Keys removed through plugin specs rather than `vim.keymap.del`, because that is
  where they are defined: bufferline's `<S-h>`/`<S-l>`, flash's `S`, snacks'
  `<leader>S`. `[b` and `]b` still cycle buffers.

### Legacy bindings found but not ported

Present in `assets/nvim/init.vim`, absent from both lvim and the plan's table.
Listed so the decision is Jacob's rather than an oversight:

- `i_CTRL-U` uppercase the current word (`<Esc>mzgUiw`za`) — note this shadows
  vim's own "delete to start of line" in insert mode.
- `i_CTRL-S` fix the last spelling mistake (`<C-g>u<Esc>[s1z=`]a<C-g>u`).
- visual `zf` staying put after creating a fold (`mzzf`zzz`).
- `<Space>?` repeating the last search backwards. `<Space>/` went to comment
  toggle, per lvim.
- terminal `,<Esc>` sending a literal escape through to the program.
- `[f`/`]f` and `[l`/`]l` quickfix and location-list navigation from vim-qf.
  `[q`/`]q` are LazyVim defaults and Trouble-aware.
- `<C-w>z` in *insert* mode, which inserted `:MaximizerToggle<CR>` as text.
  Left out deliberately: it never worked.

Superseded rather than dropped: the coc completion keys (`<Tab>`, `<CR>`,
`<C-j>`/`<C-k>` in insert) now belong to blink.cmp, and the vim-plug bindings
`<leader>p{i,u,U,c}` have no meaning under lazy.nvim, like the `<F5>` reload.

## Editing plugins (phase 3)

- **LazyVim 16 ships no surround plugin**, so tpope's vim-surround lands
  unopposed and `ys`/`cs`/`ds` keep working.
- **vim-expand-region went in verbatim.** The plan preferred treesitter
  incremental selection, but nvim-treesitter's main branch — the one LazyVim 16
  uses — dropped that module, and `v`/`<C-v>` are what his fingers know.
- **`cw` spells out the black hole: `"_ce`.** Recursive onto the `c` mapping, it
  also picks up CamelCaseMotion's `e`, which sits one short under an operator and
  leaves the last letter behind. The legacy config had that quirk. Being
  explicit gets both intents — no register clobber, whole word gone — and keeps
  `cw` symmetric with `dw`.
- `<leader>Ts` uses `Snacks.picker.todo_comments()`. lvim's `TodoTelescope` has
  no telescope to call here.
- LazyVim's own todo bindings stay: `]t`, `[t`, `<leader>st`, `<leader>x{t,T}`.

## UI (phase 4)

- **LunarVim's lualine components do not exist here.** `lvim.core.lualine.*`
  went with LunarVim, so the seven he uses are rebuilt from lualine builtins
  with the icons, colours and `hide_in_width` condition read out of the
  installed LunarVim tree. `process_sections`, the scrollbar, the search counter
  and the `+` modified flag are his own code, carried across as written.
- **A loaded statusline is not a rendered one.** None of the custom components
  run until a line is drawn, so `verify_boot.lua` now calls
  `require("lualine").statusline()` from phase 4 on.
- **`romgrk/nvim-treesitter-context` is stale**; the maintained plugin is
  `nvim-treesitter/nvim-treesitter-context`. Its `patterns` option is gone —
  class, function and method are what it matches by default now — so the port
  keeps `max_lines = 0` and drops the pattern table.
- **`simrat39/symbols-outline.nvim` is archived**, so `<leader>o` opens
  `outline.nvim` and the command becomes `:Outline`. Width 45, as lvim set it.
- Indent-guide exclusions moved to snacks indent's `filter`, LazyVim 16 having
  no indent-blankline.
- Trouble v3 renamed the lot: `lsp_document_diagnostics` is now
  `diagnostics filter.buf=0`, `lsp_workspace_diagnostics` is `diagnostics`, and
  `quickfix` is `qflist`. LazyVim's own `<leader>x` group stays.

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
