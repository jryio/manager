# Driving this

All ten phases are done, including the cutover on 2026-08-13. This tree IS
`~/.config/nvim`, reached through an out-of-store symlink, so editing a file
here changes the editor at once with no rebuild.

    nvim               # this config
    n, lazyvim         # aliases for nvim
    task test          # everything, from the config directory
    task test:keymaps  # just the 296 mapping assertions
    task sync          # install exactly what lazy-lock.json pins

It should look exactly like lvim now, not merely work like it: same
minimal-base16 colours, same statusline arrows and icons, same winbar
breadcrumbs, same minimap, same start screen, and the command line back at the
bottom of the screen where lvim keeps it. That was verified screen by screen
against lvim's own output; the harness has since been removed, so what is left
is the config and the account of it under "Looking like lvim" in NOTES.md.

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

## What the cutover did, and how to get back

1. `editors.nix` points `~/.config/nvim` at this tree with
   `mkOutOfStoreSymlink`; lazy.nvim writes `lazy-lock.json` into the config
   directory, so a read-only store copy would break `:Lazy update`.
2. `assets/lvim` and the old vim-plug/coc `assets/nvim` are deleted, and
   `shell.nix` maps both `n` and `lazyvim` to `nvim`.
3. LunarVim is gone from the machine: `~/.local/bin/lvim`,
   `~/.local/share/lunarvim`, `~/.local/state/lvim`, `~/.cache/lvim`. The
   dotbot-era `~/dotfiles/lvim` and `~/dotfiles/nvim` are untouched, as is
   everything else under `~/dotfiles`.
4. This config's plugin, state and cache directories were moved from the
   `nvim-lazy` appname onto the default one; the 2024-era originals are kept
   beside them as `*-legacy-2024`. Mason bakes absolute paths into its shims,
   so those were rewritten in place -- a package installed before the move that
   still points at `nvim-lazy` needs `:MasonInstall` again.

Rollback is `git revert` of the cutover commit plus a switch: the old configs
are in git history, and `~/dotfiles` still holds the pre-Nix originals. There is
no lvim to fall back to any more.
