*Note:* As Helix is inspired by Vim and [Kakoune](https://github.com/mawww/kakoune), the keybindings are similar but also have some differences. The content of this page is inspired by [Kakoune Wiki](https://github.com/mawww/kakoune/wiki/Migrating-from-Vim).

NOTE: Unlike vim, `f`, `F`, `t` and `T` are not confined to the current line.

## Common actions

Action | Vim | Helix | Explanation
---|---|---|---
Delete a word | `dw` | `wd`
Change a word | `cw` | `ec` or `wc` (includes the whitespace after the word)
Delete a character |  `x` | `d` or `;d` (`;` reduces the selection to a single char)
Copy a line | `yy` | `Xy` (`X` extends all selections to whole lines)
Global replace |`:%s/word/replacement/g<ret>` | `%sword<ret>creplacement<esc>` | `%` selects the entire buffer, `s` opens a prompt for a regex, `<ret>` validates the regex and reduces the selection to each match (hence, all occurrences of word are selected). `c` deletes the selection contents and enter insert mode, replacement is typed and then `<esc>` goes back to normal mode.
Go to first line | `gg` | `gg`
Go to last line | `G` | `ge`
Go to line start | `0` | `gh`
Go to line first non-blank character | `^` | `gs`
Go to line end | `$` | `gl`
Delete to line end | `D` | `vgld` or `t<ret>d` | Note: `v` is used along with `gl` (go to line end), because [`gl` does not select text](https://github.com/helix-editor/helix/issues/1630).<br>`t<ret>` selects "'til" the newline represented by `<ret>`.
Delete entire line | `dd` | `xd` | Note: `x` selects the entire line under the cursor
Jump to matching bracket | `%` | `mm`
Auto complete | `C-p` | `C-x`
Comment lines | `gc` | `Space-c`
Hard-wrap lines (e.g. for comments) | `gq` | `:reflow`
Search for the word under the cursor | `*` | `A-o*n` (if there's a tree-sitter grammar or LSP) or `be*n` | If there's a grammar or LSP, `A-o` expands selection to the parent syntax node (which would be the word in our case). Then `*` uses the current selection as the search pattern, and `n` goes to the next occurrence. `b` selects to the beginning of the word, and `e` selects to the end of the word, effectively selecting the whole word.
Block selection | `C-v`, then expand your selection vertically and horizontally | There's no "block selection" mode, so instead you'd use multiple cursors. Expand your block selection vertically by adding new cursors on the line below with `C`, and horizontally using standard movements
Search "foo" and replace with "bar" in the current selection | `:s/foo/bar/g<ret>` | `sfoo<ret>cbar<esc>,` | `s` will open a prompt in the command line for a regex, and select all matches inside the selection (effectively adding a new cursor on each match). Pressing enter will then finalise this step, and allow the `c` to change the selections to "bar". When done, go back to normal mode with `<esc>`, and keep only the primary selection with `,` (remove all the additional cursors).
Select the whole file | `ggVG` | `%`
Reload a file from disk | `:e<ret>` | `:reload<ret>` (or `:reload-all<ret>` to reload all the buffers)
Run shell command | `:!command` | `:sh command` (or `!command` to insert its output into the buffer)
Setting a bookmark (bookmarking a location) | `ma` to set bookmark with name a. Use `` `a `` to go back to this bookmarked location. | There are no named bookmarks, but you can save a location in the jumplist with `C-s`, then jump back to that location by opening the jumplist picker with `<space>-j`, or back in the jumplist with `C-o` and forward with `C-i`

## Other

Helix allows [some limited movement in `insert` mode](https://docs.helix-editor.com/keymap.html#insert-mode) without switching to `normal` mode.

Unlike Vim, under Helix, the cursor shape is the same (block) in insert mode and normal mode by default.
This can be adjusted in configuration:

```toml
[editor.cursor-shape]
insert = "bar"
```