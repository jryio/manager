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

## Picker and explorer (phase 5)

Jacob chose the snacks explorer over the neo-tree of decision 4, once it turned
out neo-tree is not a LazyVim 16 default. So both picker and tree are snacks,
and nothing extra gets installed.

- Snacks explorer already matches most of his nvim-tree and Zed habits: `h` and
  `l` collapse and expand, `a` adds, `d` deletes, `r` renames, `c` copies, `p`
  pastes. Only three gaps needed filling — `A` as an add alias, `x` to cut
  (snacks calls it `explorer_move`) and `Y` for a *relative* path, which snacks
  has no action for, since its `y` yanks absolute paths.
- **`<leader>sr` was a silent loss.** LazyVim gives it to grug-far's search and
  replace, and with two plugins claiming one key, whichever spec registers last
  wins — grug-far did. His `sr` is "Open Recent File", so grug-far's entry is
  disabled and `:GrugFar` still opens it. The manifest caught this only because
  it asserts descriptions, not just presence.
- `<leader>st` is text search, as in lvim, displacing LazyVim's todo search.
  Todo is still on `<leader>Ts` from phase 3 and LazyVim's own `<leader>sT`.
- `<leader>f` maps straight to the file picker. LazyVim's file group stays
  reachable at `<leader>ff`, `<leader>fr` and so on.
- `<leader>nf` keeps lvim's minimap dance: close the minimap, then reveal, so
  the tree is not resized by it.

## LSP, formatting, linting (phase 6)

- **`formatexpr` is LazyVim's, set at options time**, not on LSP attach:
  `v:lua.LazyVim.format.formatexpr()`. lvim clears it so `gq` reflows comments
  with textwidth, so `lua/config/options.lua` clears it too (that file loads
  after LazyVim's own options). Neovim reinstalls one on attach, which the
  `LspAttach` autocmd in `lua/plugins/formatting.lua` clears again. The format
  test proves `gq` really wraps at 80 and keeps the comment leader.
- **LazyVim's python extra enables `pyright`, not `basedpyright`** — it
  configures both and picks pyright unless `vim.g.lazyvim_python_lsp` says
  otherwise. It also enables `ruff`.
- **The rust extra drives rust_analyzer through rustaceanvim**, so the
  `rust_analyzer` server spec is deliberately off. Asserting it enabled would be
  wrong; the test asserts rustaceanvim is installed instead.
- `lang.typescript` is a directory with an `init.lua`, not `typescript.lua`, so
  the extra module path still resolves.
- lvim disabled tsserver globally to make deno work. Here `vtsls` only stands
  down inside a deno root, so TypeScript projects keep a server either way.
- The deno gate keys off `deno.imports.json`, his own marker, ported as-is
  rather than "fixed" to `deno.json`.
- Server attachment is only asserted when the executable exists, so the suite
  does not demand half a gigabyte of Mason downloads to be useful.
- Harmless test noise: force-loading every plugin makes the java extra try to
  spawn jdtls with an empty command, since Mason has not installed it. It
  resolves the first time he opens a Java file.

## Git (phase 7)

- **`]h`/`[h` are not dependable as LazyVim defaults.** LazyVim does bind them,
  but inside gitsigns' `on_attach`, which makes them buffer-local and dependent
  on attach timing. In a tracked buffer that gitsigns had demonstrably attached
  to (`gitsigns_status_dict` set, plugin loaded) the hunk maps were absent, while
  the treesitter-textobjects buffer-local maps were all present. Rather than
  leave a muscle-memory binding to chance, `lua/plugins/git.lua` binds all four
  hunk keys globally through `gitsigns.nav_hunk`. LazyVim's `<leader>gh` group
  is still on_attach-based and inherits the same caveat.
- octo.nvim defaults to telescope, so its spec sets `picker = "snacks"`.

## AI (phase 8)

- **avante's `auto_set_keymaps` already owns `<leader>aa`, `<leader>at` and
  visual `<leader>ae`**, and wins over a lazy `keys` entry. That is not new: the
  lvim baseline shows `<leader>aa` as `avante: ask` and `<leader>at` as
  `avante: toggle` today, so his which-key entries for them never took effect
  there either. Only `<leader>ak` and `<leader>ap`, which avante does not claim,
  are bound in the spec. Ask and Toggle both open the sidebar.
- **`make BUILD_FROM_SOURCE=true` exceeds lazy.nvim's build timeout.** The task
  is killed at 120s mid-compile (`make: *** [luajit-templates] Terminated: 15`),
  leaving no native library and a broken `require("avante_lib").load()`. Running
  the make by hand in the plugin directory finishes in about three minutes and
  writes the four `.so` files into `lua/`. Worth knowing after any avante update:
  if avante starts erroring about its library, rebuild by hand.

## Looking like lvim (phase 10)

The earlier phases matched behaviour and left appearance alone, which turned out
to be most of it: LazyVim was still on tokyonight-moon, and 89 of the 92
highlight groups a user looks at differed. Appearance was matched by measurement
rather than by eye: each editor was screenshotted inside tmux, the ANSI was
parsed back into a grid of coloured cells, and five screens ended up identical
to lvim, glyph for glyph and colour for colour. That harness has since been
removed at the operator's request, so the notes below are the record of what it
found.

- **Nothing about colour can be measured headlessly.** minimal.nvim aborts with
  "&termguicolors must be set", nvim keeps its own palette, and every assertion
  then compares nvim's defaults against themselves. Only a real terminal, with
  RGB forced on, reports what was actually painted.
- **Eight statusline glyphs and three separators had been silently emptied.**
  Every icon in `lua/plugins/ui.lua` -- the git diff symbols, the four
  diagnostic symbols, the treesitter tree, and the  and  powerline
  separators -- was a bare space. The statusline had no icons and its sections
  met in flat blocks. All of them are now `\u{...}` escapes, in this file and in
  `breadcrumbs.lua`, where all 32 navic kind icons had gone the same way.
- **lvim's palette has holes, and they are load-bearing.** Its statusline block
  asks for `colors.white`, `colors.red` and `colors.nord13`, none of which its
  palette defines. The earlier port "fixed" them to real colours, which stopped
  lualine emitting transitional highlights and removed the arrows between
  sections. They are now reproduced as nil.
- **LazyVim mocks nvim-web-devicons with mini.icons**, which changes both glyph
  and colour: a Lua buffer showed  DevIconLua in lvim against 󰢱 MiniIconsAzure
  here. mini.icons is off and devicons is real. Fifteen icons upstream has
  recoloured since lvim's 2024 pin are restored by name rather than by pinning
  devicons back two years.
- **lvim has no noice.** The command line is a real row at the bottom (LazyVim
  hides it, `cmdheight=0`, and floats a box mid-screen), and ten layout options
  differed besides -- `relativenumber`, `fillchars`, `statuscolumn`,
  `conceallevel`, `scrolloff`, `pumblend`, `showcmd`. All are asserted in
  `verify_options.lua` as phase 10.
- **lvim draws a winbar**, file icon then LSP symbol path, which LazyVim has no
  equivalent of. Ported onto nvim-navic in `lua/plugins/breadcrumbs.lua`.
- **The minimap needed taking off the plugin's own autostart.** Its BufWinEnter
  hook misses the file named on the command line, whose BufWinEnter has already
  fired by load time, and fires for the nameless buffer of a bare `nvim` --
  where the extra window then makes the dashboard decline to draw. `:Minimap`
  also reports success and leaves no window if called at VimEnter; it needs
  300ms.
- **lazy.nvim keeps only the last `init` among a plugin's spec fragments.** Two
  snacks fragments with an `init` each meant one was silently dropped, which is
  how the dashboard's highlight links went missing while the indent ones worked.
  Every parity highlight now lives in one table in `lua/config/autocmds.lua`.
- lvim underlines the other occurrences of the symbol under the cursor
  (vim-illuminate); LazyVim bolds them (neovim's own document highlight, and
  `LspReference*` is bold in this theme). Same cells, so only the attribute is
  changed.
- lvim's diagnostics use codicon signs, no source suffix in the virtual text,
  and pass each sign as `numhl`, which is what tints the line number of a
  diagnostic line.
- The start screen is alpha's, rebuilt on snacks: same banner, same seven
  entries, and a block 50 columns wide rather than snacks' 60. lvim configures a
  footer that never reaches the screen, so there is none here either.
- Blank cells are compared by background only. Alpha writes its banner padding
  in the banner's highlight and snacks writes the same spaces in Normal; that is
  a difference in the escape sequence and not on the screen.
- **One cell is not matched, deliberately**: the `:` command line. lvim prints a
  transient LSP deprecation warning over that row, which makes an unstable
  baseline, so `cmdheight` is asserted instead.

## Flagged for Jacob (out of scope for the behaviour-preserving migration)

- The 1Password lookup is gone from both configs. Their avante blocks shelled
  out to `op item get` against vault `ifpq6udm2wag2mo3ipcoiu666e`, which no
  longer exists, so every lvim start asked 1Password for permission and then
  failed with `isn't a vault in this account`. Both now fall back to
  `ANTHROPIC_API_KEY`; point `api_key_name` at a live item to get the prompt
  back. lvim's copy takes effect on the next `darwin-rebuild switch`, its config
  being a Nix store symlink.
- avante's pinned model `claude-3-5-sonnet-20241022` is long superseded.
- avante's `claude = { ... }` block has been moved to `providers.claude`, with
  `temperature` and `max_tokens` under `extra_request_body`. The verbatim port
  warned three times on every start. Together with naming mini.icons by its
  current repository, this clears all eight startup warnings; assert with
  `Snacks.notifier.get_history()`, not `:messages` -- LazyVim routes notify
  through snacks, which is why the warnings never appeared in `:messages`.
