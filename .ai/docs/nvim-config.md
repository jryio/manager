# LunarVim → Helix migration: keybindings inventory + capability matrix

Source: `modules/home-manager/assets/lvim/config.lua` (+ `lua/core/utils.lua`, `bin/lvim.*`).
Target: Helix 25.x (from `.ai/docs/helix/*` and `.ai/docs/helix/migrating-from-vim/*`).
Reference: `.ai/docs/helix-vim-example-config.toml`.

The point of this document is to consolidate **every** keybinding from the live LunarVim setup, classify the origin (vim default / lvim default / plugin), and pair each one with the Helix surface that can replace it (default, sequence, macro, typable command, or "no equivalent").

---

## 1. Origin legend

| Tag | Meaning |
|---|---|
| `vim` | Standard Vim/Neovim built-in. Lvim does not own it. |
| `lvim` | Bundled with LunarVim's builtin plugin set (nvimtree, telescope, which-key, etc.). |
| `plug:<name>` | Comes from a third-party plugin lvim loads. |
| `user` | User-defined override / new binding in `config.lua`. |

## 2. Helix replacement legend

| Tag | Meaning |
|---|---|
| `default` | Already bound in Helix out-of-the-box; nothing to do (or a 1-key rebind). |
| `rebind` | Command exists in Helix; just needs a TOML keymap entry. |
| `sequence` | Achievable with a `[...]` command list in keymap. |
| `macro` | Achievable with a `@...` macro string. |
| `typable` | Use a `:typable-command` from a key. |
| `wontfix` | Helix has no equivalent and a useful approximation isn't worth the rebind. |
| `none` | No equivalent at all. Workflow must change. |

---

## 3. Insert mode (`lvim.keys.insert_mode`)

| Key | LVim mapping | Origin | Intent | Helix mapping | Status |
|---|---|---|---|---|---|
| `<C-c>` | `<ESC>` | user | Escape without sending SIGINT to attached funcs | `[keys.insert] C-c = "normal_mode"` | rebind |
| `<up>` `<down>` `<left>` `<right>` | `<NOP>` | user | Force modal discipline | `up = "no_op"` etc. in `[keys.insert]` | rebind |
| `<F1>` | `<NOP>` | user | Stop accidental help | `F1 = "no_op"` | rebind |
| `<A-Down/Left/Right/Up>`, `<A-j>`, `<A-k>` | `""` (unset) | lvim default | Remove lvim's line-move bindings | Not bound in Helix by default — no action needed | default |
| `<p>` | `""` (unset) | lvim/plug | Remove an accidental insert-mode `p` | n/a in Helix | default |
| `jj`, `jk`, `kj` | `""` | lvim | Remove escape-chord shortcuts | n/a in Helix | default |

## 4. Normal mode (`lvim.keys.normal_mode`)

### 4a. Buffer/file lifecycle

| Key | LVim mapping | Origin | Intent | Helix mapping | Status |
|---|---|---|---|---|---|
| `+` | `:bnext` | user | Next buffer | `"+" = "goto_next_buffer"` | rebind |
| `_` | `:bprevious` | user | Prev buffer | `"_" = "goto_previous_buffer"` | rebind |
| `,s` | `:w<CR>` | user (`,` as second leader) | Save | `[keys.normal.","] s = ":w"` | typable |
| `,w` | `:Sayonara!<CR>` | plug:vim-sayonara | Force close buffer | `[keys.normal.","] w = ":bc!"` | typable |
| `,q` | `:Sayonara<CR>` | plug:vim-sayonara | Close buffer (prompt if dirty) | `[keys.normal.","] q = ":bc"` | typable |

### 4b. Window management

| Key | LVim mapping | Origin | Intent | Helix mapping | Status |
|---|---|---|---|---|---|
| `<M-l>` | `10<C-w>>` | vim | Grow split width by 10 | **no helix command for resize** | none — use tmux/Ghostty splits if you need this |
| `<M-h>` | `10<C-w><` | vim | Shrink split width by 10 | same | none |
| `<M-j>` | `10<C-w>-` | vim | Shrink split height by 10 | same | none |
| `<M-k>` | `10<C-w>+` | vim | Grow split height by 10 | same | none |
| `<C-h>` | `<C-w>h` | vim | Focus split left | `"C-h" = "jump_view_left"` | rebind (`<C-w>h` already works) |
| `<C-j>` | `<C-w>j` | vim | Focus split down | `"C-j" = "jump_view_down"` | rebind |
| `<C-k>` | `<C-w>k` | vim | Focus split up | `"C-k" = "jump_view_up"` | rebind |
| `<C-l>` | `<C-w>l` | vim | Focus split right | `"C-l" = "jump_view_right"` | rebind |

### 4c. Motion / scrolling

| Key | LVim mapping | Origin | Intent | Helix mapping | Status |
|---|---|---|---|---|---|
| `j` | `gj` | user | Move by visual line | Helix `j` = `move_visual_line_down` already | default |
| `k` | `gk` | user | Move by visual line | Helix `k` = `move_visual_line_up` already | default |
| `gj` | `5j` | user | Jump 5 visual lines down | `"gj" = "@5j"` (macro) | macro |
| `gk` | `5k` | user | Jump 5 visual lines up | `"gk" = "@5k"` (macro) | macro |
| `n` | `:norm! nzz<CR>` | user | Search next then center | `n = ["search_next", "align_view_center"]` | sequence |
| `N` | `:norm! Nzz<CR>` | user | Search prev then center | `N = ["search_prev", "align_view_center"]` | sequence |
| `<C-u>` | `<C-u>zz` | user | Half-page up + center | `"C-u" = ["page_cursor_half_up", "align_view_center"]` | sequence |
| `<C-d>` | `<C-d>zz` | user | Half-page down + center | `"C-d" = ["page_cursor_half_down", "align_view_center"]` | sequence |
| `<C-f>` | `<C-f>zz` | user | Full-page down + center | `"C-f" = ["page_down", "align_view_center"]` | sequence |
| `<C-b>` | `<C-b>zz` | user | Full-page up + center | `"C-b" = ["page_up", "align_view_center"]` | sequence |
| `H` | `^` | user | Goto first non-blank | `H = "goto_first_nonwhitespace"` | rebind |
| `L` | `$` | user | Goto line end | `L = "goto_line_end"` | rebind |

### 4d. Quickfix navigation

| Key | LVim mapping | Origin | Intent | Helix mapping | Status |
|---|---|---|---|---|---|
| `[q` | `:cprev` | vim | Prev quickfix entry | Helix has no quickfix list; closest is `[d` (prev diag) | wontfix / remap to diag |
| `]q` | `:cnext` | vim | Next quickfix entry | `]d` (next diag) | wontfix / remap to diag |

### 4e. Edit / yank semantics

| Key | LVim mapping | Origin | Intent | Helix mapping | Status |
|---|---|---|---|---|---|
| `Y` | `:%y+<CR>` | user | Yank entire buffer to system clipboard | `Y = ["select_all", "yank_main_selection_to_clipboard", "keep_primary_selection"]` | sequence |
| `c` | `<NOP>` | user | Disable change-and-yank (use `c<motion>` only) | `c = "change_selection_noyank"` (helix has this natively) | rebind |
| `p` | `p\`]` | user | Paste then move cursor to end of pasted text | Helix `p` = `paste_after`; no native "move-to-end-of-paste" | partial / wontfix |
| `dw` | `de` | user | Fix Vim's `dw` end-of-line quirk | Helix selects-first, so `wd` is already correct | default |
| `J` | `mzJ\`z` | user | Join lines, keep cursor still | Helix `J` = `join_selections`; cursor behavior differs | partial (use default `J`) |
| `S` | `mzi<CR><ESC>\`z` | user | Split line (inverse of J) | `S = ["insert_mode", "insert_newline", "normal_mode"]` (note: collides with `split_selection`) | sequence (rebind risk — see Q6) |

### 4f. Disabled keys

| Key | LVim mapping | Origin | Intent | Helix mapping | Status |
|---|---|---|---|---|---|
| `<A-Down/Left/Right/Up>`, `<A-j>`, `<A-k>` | `""` | lvim | Remove lvim line-mover | Helix uses `<A-j>` for join-with-space and `<A-up/down>` for syntax expand/shrink — **keep Helix defaults; don't unmap** | review |
| `<C-Down/Left/Right/Up>` | `""` | lvim | Remove split resizes | Not bound in Helix | default |
| `<up>` `<down>` `<left>` `<right>` `<bs>` `<delete>` `<F1>` | `<NOP>` | user | Force modal discipline | All `= "no_op"` in `[keys.normal]` | rebind |
| `Q` | `<NOP>` | user | Disable Ex mode | Helix `Q` = `record_macro`; user wants no macros → `Q = "no_op"` | rebind (or keep) |
| `q` | `<NOP>` | user | Disable macro recording | Helix `q` = `replay_macro` → `q = "no_op"` | rebind (or keep) |

## 5. Visual / select mode (`lvim.keys.visual_mode`)

| Key | LVim mapping | Origin | Intent | Helix mapping | Status |
|---|---|---|---|---|---|
| `j` `k` | `gj` `gk` | user | Visual-line motion | Helix select-mode already extends by visual line | default |
| `gj` `gk` | `5j` `5k` | user | Long jumps | `"gj" = "@5j"` in `[keys.select]` | macro |
| `n` `N` | `:norm! nzz<CR>` / `:norm! Nzz<CR>` | user | Search next/prev + center | `n = ["extend_search_next","align_view_center"]` etc. | sequence |
| `<C-u/d/f/b>` | `<C-u>zz` etc. | user | Pages + center | Same sequences as normal mode | sequence |
| `H` `L` | `^` `$` | user | Begin/end of line | `H = "goto_first_nonwhitespace"`, `L = "goto_line_end"` (helix select extends) | rebind |
| `y` | `y\`]` | user | Yank, cursor stays at end | Helix select-mode `y` yanks selection; cursor remains. Close enough. | partial / default |
| `p` | `"_dP\`]` | user | Paste replacing selection without clobbering register | `p = "replace_selections_with_clipboard"` (from helix-vim example) | rebind |
| `J` | `:m '>+1<CR>gv=gv` | user | Move selection down 1 line | Helix has no "move line" command | none |
| `K` | `:m '<-2<CR>gv=gv` | user | Move selection up 1 line | same | none |
| `<C-r>` | `"hy:%s/<C-r>h//gc<left><left><left>` | user | Substitute matching selection across file | Closest: `*` then `c` (helix replace-via-search) | workflow change |
| `<leader>s` | `:!sort<CR>` | user | Sort selection | `[keys.select.space] s = ":sort"` | typable |

## 6. Plugin: CamelCaseMotion (`bkad/CamelCaseMotion`)

| Key | LVim mapping | Origin | Helix mapping | Status |
|---|---|---|---|---|
| `w` | `<Plug>CamelCaseMotion_w` | plug | `w = "move_next_sub_word_start"` | default (just rebind) |
| `b` | `<Plug>CamelCaseMotion_b` | plug | `b = "move_prev_sub_word_start"` | default |
| `e` | `<Plug>CamelCaseMotion_e` | plug | `e = "move_next_sub_word_end"` | default |
| `ge` | `<Plug>CamelCaseMotion_ge` | plug | `move_prev_sub_word_end` (not bound by default; rebind under `g`) | rebind |

> Helix has subword motions built in (kept as `_sub_` variants in `commands.md`). They are not bound by default — perfect free space to take over `w/b/e`.

## 7. WhichKey / leader bindings (`<leader>` = `space`)

| Key | LVim binding | Origin | Intent | Helix equivalent | Status |
|---|---|---|---|---|---|
| `<leader>Lk` | view-all-keymaps | lvim | Discover bindings | `<space>?` = `command_palette` | default |
| `<leader>T l` | `:TodoTrouble` | plug:todo-comments+trouble | List TODOs | `:sh rg -n 'TODO\|FIXME'` or workspace search | typable / sequence |
| `<leader>T s` | `:TodoTelescope` | plug | Fuzzy search TODOs | `[keys.normal.space.T] s = "@<space>/TODO<ret>"` | macro |
| `<leader>T n/k` | jump next/prev TODO | plug | TS comments cycle | `]c` / `[c` (Helix TS comment nav) | default |
| `<leader>h` | clear search highlight | user | nohlsearch | Helix doesn't persist search highlight after movement | wontfix |
| `<leader>n f` | nvimtree find-file toggle | lvim+plug | File explorer at current file | `<space>E` = `file_explorer_in_current_buffer_directory` | default |
| `<leader>m m` | `:MinimapToggle` | plug:minimap.vim | Toggle minimap | Helix has no minimap | none |
| `<leader>o` | `:SymbolsOutline` | plug:symbols-outline | Symbol panel | `<space>s` = `symbol_picker` (picker, not panel) | partial |
| `<leader>P` | `:Telescope projects` | plug:telescope-projects | Switch projects | No native equivalent | none / shell+`:cd` |
| `<leader>t r` | `:Trouble lsp_references` | plug:trouble | LSP refs panel | `gr` = `goto_reference`, or `<space>h` = `select_references_to_symbol_under_cursor` | default |
| `<leader>t f` | `:Trouble lsp_definitions` | plug:trouble | LSP defs | `gd` = `goto_definition` | default |
| `<leader>t d` | document diagnostics | plug:trouble | LSP diag for file | `<space>d` = `diagnostics_picker` | default |
| `<leader>t w` | workspace diagnostics | plug:trouble | LSP diag for ws | `<space>D` = `workspace_diagnostics_picker` | default |
| `<leader>t q` | `:Trouble quickfix` | plug:trouble | Quickfix UI | no helix quickfix | none |
| `<leader>t l` | `:Trouble loclist` | plug:trouble | Location list UI | no helix loclist | none |
| `<leader>v *` | `:Accordion` family | plug:vim-accordion | Multi-vsplit accordion layout | No equivalent | none |
| `<leader>S r/R/Q` | persistence.nvim | plug:persistence | Restore/quit session | No equivalent in Helix | none / external |
| `<leader>a a` | `:AvanteToggle` | plug:avante | AI chat sidebar | None native | none / external (Claude, sg, aichat) |
| `<leader>a k` | `:AvanteClear` | plug:avante | Clear AI session | same | none |
| `<leader>a p` | switch AI provider | plug:avante | Provider picker | same | none |
| `<leader>a e` (visual) | `:AvanteEdit` | plug:avante | Edit-with-AI on selection | same | none |

### Telescope (lvim's default `<leader>f*`, `<leader>b*` etc.)

LVim uses Telescope for files/buffers/grep. Helix's space-mode pickers cover most of this:

| LVim (typical) | Helix |
|---|---|
| `<leader>ff` find files | `<space>f` `file_picker` |
| `<leader>fF` find files in cwd | `<space>F` `file_picker_in_current_directory` |
| `<leader>fb` buffers | `<space>b` `buffer_picker` |
| `<leader>fg` live grep | `<space>/` `global_search` |
| `<leader>fr` recent | `<space>j` `jumplist_picker` (close-ish) |
| `<leader>fp` projects | none |

## 8. Vim options (`vim.opt.*`)

| LVim option | Value | Helix equivalent |
|---|---|---|
| `timeoutlen` | 500 | Not user-configurable (helix uses idle-timeout for completion only). |
| `textwidth` | 80 | `[editor] text-width = 80` + `[editor.soft-wrap] wrap-at-text-width = true` |
| `list = true` | render whitespace + listchars | `[editor.whitespace] render = "all"` + `[editor.whitespace.characters]` |
| `cursorlineopt = "number"` | highlight line-no only | Closest: `[editor] cursorline = false` + leave line-numbers absolute (default). |
| `foldmethod = manual` / `foldexpr = ""` | manual folds | **Helix has no folding** |
| `mouse = ""` | disable mouse | `[editor] mouse = false` |
| `formatoptions = qcrntjlv` | gq comment wrapping | Helix uses `:reflow` (no native `gq`); bind: `gq = ":reflow"` |

## 9. LSP / format-on-save

LVim:
- `format_on_save.enabled = true`
- `null-ls` formatters: `black` (via `blackd-client`) for Python
- linters: `vale` for markdown
- Skipped servers: `rust` (using `rust-analyzer` directly), `tsserver`, `denols` (with manual `denols` for `deno.imports.json` projects)

Helix:
- `[editor] auto-format = true` ← matches `format_on_save`
- Per-language formatters configured in `languages.toml` (one entry per language, `formatter = { command = "...", args = [...] }`)
- LSP per-language in `languages.toml`. Helix supports multiple language servers per file (`language-servers = ["...","..."]`)
- Vale → run as language server (`vale-ls`) or as formatter command; Helix has no built-in linter abstraction
- Deno-vs-tsserver branching → use `roots = ["deno.imports.json"]` or workspace config

> The detailed `languages.toml` is out of scope for this matrix — the question matrix below will pin language ownership.

## 10. Other plugins (no keybindings, but workflows to consider)

| Plugin | Role | Helix native equivalent | Status |
|---|---|---|---|
| `nvim-treesitter` | TS grammars | Built into Helix | default |
| `nvim-treesitter-context` | sticky function header | None (issue #4242 tracked upstream) | none |
| `trim.nvim` | trim trailing WS on save | `[editor] trim-trailing-whitespace = true` | default |
| `nvim-colorizer` | inline color highlights | `[editor.lsp] display-color-swatches = true` (default) | default |
| `vim-surround` | `cs`/`ds`/`ys` | `mr`/`md`/`ms` (helix native) | default |
| `vim-dotenv` | load `.env` files | None — use `direnv` or shell | none |
| `octo.nvim` | GitHub PR review | None — use `gh` CLI or `gh-dash` | none |
| `persistence.nvim` | session save/restore | None | none |
| `treesitter playground` | inspect TS nodes | `:tree-sitter-scopes` typeable | default |
| `minimap.vim` | code minimap | None | none |
| `symbols-outline.nvim` | symbol tree panel | `<space>s` picker (not panel) | partial |
| `lualine` (custom config) | statusline | `[editor.statusline]` (full control) | rebind |
| `alpha` (dashboard) | start screen | None — `hx` opens directly | none |
| `which-key` | popup hint | `[editor] auto-info = true` (helix's mini-mode hints) | partial |

## 11. Categorical summary of LVim binding origins

| Category | Approx count | Helix coverage |
|---|---|---|
| Vim built-ins user re-implemented (j/k visual, H/L line ends, centering, etc.) | ~15 | Mostly default or 1-line rebind |
| User aliases on default vim commands (`+/_` buffers, `,s` save) | ~5 | All `rebind` or `typable` |
| Plugin replacements for vim features (vim-surround, CamelCaseMotion, telescope) | ~10 | All `default` or `rebind` — Helix has these built in |
| Plugin-only UI panels (trouble, minimap, accordion, alpha, octo, persistence, avante, symbols-outline, todo-comments) | ~15 | Mostly `none` or `partial` — Helix is picker-not-panel |
| LSP/format hooks | n/a | `default` via Helix's LSP + `languages.toml` |

## 12. Helix feature surface NOT in LVim today (worth considering)

| Helix feature | What it does |
|---|---|
| Multiple cursors via `C`/`,`/select-from-regex | First-class multi-cursor without a plugin |
| `s` (select_regex inside selection) + `c` workflow | Whole multi-edit story replaces 90% of macros |
| `mi`/`ma` text objects with TS-driven `f`/`t`/`a`/`c`/`T`/`g` | Function/Type/Argument/Comment/Test/Change text-objects with no plugin |
| `]f`/`[f`, `]t`/`[t`, etc. — TS-driven navigation | Function/class/test cycling, no plugin |
| `gw` jump labels (avy-style) | Two-char label jumps without `easymotion` |
| `Z`/`z` view mode (sticky vs not) | Cleaner than vim's `zz/zt/zb` |
| `[g`/`]g` git hunk navigation | Built-in, no `gitsigns` |
| Sub-word motions (`*_sub_word_*`) | CamelCase/snake aware without `CamelCaseMotion` |
| File explorer (`<space>e`) | NEW — Helix 25.x landed `file_explorer` |
| Soft-wrap with `wrap-at-text-width` | Better than vim's wrap |
| `<C-c>` toggle line-comment in normal | No `gcc` needed |

---

## 13. Resolved decisions (2026-05-22)

| Decision | Resolution |
|---|---|
| Comma leader (`,s`/`,w`/`,q`) | **KEEP** — comma takes priority over `keep_primary_selection`. Use `<A-,>` for remove-primary if needed; lose easy keep-primary. |
| TODO comment workflow | **DROP** — `]c`/`[c` (TS comments) is good enough; no special TODO bindings. |
| Window resize `<M-h/j/k/l>` | **DROP** — use Ghostty splits when you need resize. |
| Move-selection up/down (visual `J`/`K`) | **ENGINEER** — wire via `:move` typeable command. |
| Quickfix `[q`/`]q` | **DROP** — Helix has no quickfix. Use `[d`/`]d` for diagnostics natively. |
| Auto-center on `n`/`N` + pages | **ON** — sequences in normal and select modes. |
| Disable arrows / F1 / BS / Del | **OFF** — keep Helix defaults. Don't enforce modal discipline. |
| Disable `q`/`Q` (macros) | **OFF** — keep Helix macros (they're more powerful than vim's). |
| `<C-h/j/k/l>` split focus | **ON** for normal+select only. Preserves insert-mode `<C-j>` (newline) and `<C-k>` (kill-line). |
| Sub-word motions on `w/b/e/ge` | **ON** — replaces CamelCaseMotion. `W/B/E` stay as WORD motions. |
| `gj`/`gk` = 5-line jump (macro) | **ON** — preserves muscle memory. |
| Cursor bar in insert | **OFF** — keep Helix block-everywhere default. |
| `y`/`p` = system clipboard | **ON** — `default-yank-register = "+"`. |
| `Y` = yank whole buffer to clipboard | **ON** — sequence. |
| `c` = change-without-yank | **ON** — `change_selection_noyank`. |
| `p` in select = replace (no register clobber) | **ON** — `replace_selections_with_clipboard`. |
| `S` = split line | **ON** — sequence. WARNING: shadows Helix's `split_selection` (regex split). |
| `gq` → `:reflow` | **ON** — comment hard-wrap. |
| `format_on_save` (auto-format) | **ON** — Helix default. |
| Soft-wrap at text-width 80 | **ON**. |
| Whitespace render + indent guides | **ON**. |
| Statusline customization | **DEFER** — keep Helix defaults for now. |

## 14. Repo placement

There is no Helix module yet (`modules/home-manager/editors.nix` only ships `nvim` and `lvim` config trees from `./assets/`). The migration plan:

1. Land the draft `config.toml` at `.ai/docs/helix-config-draft.toml` first (this session's deliverable).
2. Move to `modules/home-manager/assets/helix/config.toml` once the bindings are validated under `hx` interactively.
3. Add `xdg.configFile."helix"` block to `modules/home-manager/editors.nix` mirroring the `nvim`/`lvim` pattern.
4. Install `pkgs.helix` via `modules/home-manager/packages.nix` (or via the Homebrew bridge if you prefer the cask).
5. `languages.toml` (LSP/formatter wiring) is a separate follow-up — see §9 of this doc.

