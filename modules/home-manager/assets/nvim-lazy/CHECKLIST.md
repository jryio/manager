# Driving this before cutover

Phases 0–8 are done and the whole suite passes. Phase 9, the cutover, is
deliberately not done: it waits until you have driven this for a while.

    lazyvim            # this config, NVIM_APPNAME=nvim-lazy
    lvim               # unchanged, still the daily driver and the rollback
    task test          # everything, from the config directory
    task test:keymaps  # just the 296 mapping assertions
    task sync          # install exactly what lazy-lock.json pins

## Ten things to try

The suite asserts every one of these, but these are the ones where a mapping
that "exists" can still feel wrong.

1. `,s` writes. `,w` closes the buffer and keeps the window; `,q` takes both.
2. `+` and `_` walk buffers. `H` and `L` go to the ends of the line, so
   bufferline's Shift-H and Shift-L are gone on purpose — `[b` and `]b` remain.
3. `S` splits a line where the cursor is, with no reindent. If a split leaves
   the second half indented, treesitter indent has crept back on.
4. `cw` changes a whole word and leaves the yank register alone: yank something,
   `cw` over another word, then `p`. Note `c` works at all now — it is mapped to
   `<NOP>` in lvim, so `c`, `cw`, `ciw` and `cc` all do nothing there.
5. Visual `<C-r>` substitutes the selection across the file, and visual
   `<leader>s` sorts it.
6. `<leader>tf` opens Trouble on definitions; `<leader>o` opens the outline
   (`:Outline` now, not `:SymbolsOutline`).
7. `gqq` on a long comment wraps at 80 and keeps the comment leader. This is the
   one that breaks if `formatexpr` comes back.
8. `<leader>e` opens the explorer; inside it `h`/`l` collapse and expand, `a`
   adds, `x` cuts, `Y` copies the path relative to the project.
9. `<leader>f` finds files, `<leader>st` greps text, `<leader>sr` opens recent
   files. Todo search moved to `<leader>Ts`.
10. `<C-w>z` zooms the window, and `<M-h/j/k/l>` resize by ten.

Also worth a look: the statusline (nord, `[n/N]` search counter, scrollbar
glyph, `+` when modified), and `<leader>L` for Lazy — `<leader>l` is the LSP
group now.

## Known gaps, by design

- `<leader>aa` is avante's own "ask", not `AvanteToggle`. Same in lvim today.
  `<leader>at` toggles.
- Visual `L` is `$`, per lvim, not the legacy `g_`.
- Language servers install on first use through Mason. Until then a Java buffer
  will complain about jdtls.
- Eight legacy bindings were found and deliberately not ported; see NOTES.md.
  Three avante items want a decision, also in NOTES.md.

## Phase 9, when you are ready

1. `editors.nix`: replace the coc-era `xdg.configFile."nvim"` block with
   `xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink
   "<home>/manager/modules/home-manager/assets/nvim-lazy"`.
2. Remove the dotbot symlink `~/.config/nvim` → `~/dotfiles/nvim` and its
   install-config entry, then `git mv assets/nvim assets/nvim-legacy`.
3. `rm ~/.config/nvim-lazy` (the hand-made symlink home-manager now replaces),
   then `nvim --headless "+Lazy! restore" +qa` with `NVIM_APPNAME` unset.
4. Rerun `task test` with `NVIM_APPNAME` unset.
5. Flip `shell.nix`'s `n = "lvim"` to `n = "nvim"`. Leave `lvim` and
   `~/.config/lvim` alone for a grace period — that is the rollback.
6. `darwin-rebuild switch --flake ~/manager#<host>`.
