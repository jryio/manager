# Vim

Helix's editing model is strongly inspired from vim and kakoune, and a notable difference from vim (and the most striking similarity to kakoune) is that Helix follows the `selection → action` model. This means that whatever you are going to act on (a word, a paragraph, a line, etc) is selected first and the action itself (delete, change, yank, etc) comes second. A cursor is simply a single width selection.

Vim, and to a lesser extent neovim, have long been resistant to growing too many core features, but has had a thriving plugin ecosystem where a lot of great experiments have lead to some usage patterns that are commonly agreed to be worthwhile. Part of Helix's motivation was to bring many of these agreed upon improvements core to the editor so that a sprawling configuration and the constant maintenance thereof would be mostly eliminated. It is worth noting that a plugin system and more programmatic configuration are planned, but time is being taken to design it just right. To this end some plugin inspired functionality that is core to Helix includes:

* **Tree-sitter and LSP** -- Detailed elsewhere
* **Unimpaired** -- A set of bindings on `[` and `]` to jump to the prior and next of a textobject. This is made more powerful by tree-sitter driven textobjects.
* **Space mode** -- A common set of miscellaneous bindings inspired by the many user bindings in vim distributions like spacevim
* **Surround/match mode** -- A flexible way to manipulate braces, quotes and other pairings around your selections bound to `m`, made even more powerful as it includes the ability to expand selections by tree-sitter driven textobjects.
* **Fuzzy pickers** -- Interactive search, symbol selection and more with Levenshtein matching driven by the excellent implementations from `rg` and `skim`.

# Kakoune

Kakoune's strength is in being a first class citizen of the shell environment it runs in, and really defines very little about the editor with all the functionality helix provides being possible through shell integrations and external sidecar processes like kak-lsp and kak-tree. The downside of this approach is that you need to configure and maintain a number of plugins in varying languages in order to achieve all the functionality Helix includes. Helix prefers instead to include common functionality as part of the core editor.

Besides approach to core features, Helix's editing model, while derived from Kakoune, differs in some important ways:

* *Avoids use of held modifiers.* A consequence of this preference is that the pattern of using shift to extend selections with a given movement is replaced with the use of a new mode toggled with `v`. Kakoune's view mode is then moved to `z` to make room.
* *Avoids use of alt.* Alt is often in an awkward place on the keyboard, making for strenuous key combinations. Kakoune uses alt to mean the reversal of direction, but Helix restores the use of shift for this purpose, bringing it more in line with the vim lineage.
* Helix was created after Kakoune decided to change the meaning of the `x` key, so Helix's `x` still exhibits conditional behavior (extend to line bounds, or else add a line below to selection). A decision hasn't been made on if this will remain the case.

# Helix

Helix has its own unique features, that don't derive from its parentage.

* **Navigation by tree-sitter** - Expand and shrink selections by traversing the tree-sitter AST with `Alt-o`/`Alt-i`, expand by specific kinds of things like function- or class-like structures with `mi` and `ma`, or navigate to the next and previous with `Alt-n` / `Alt-p` by node or `]` / `[` by those same code structures.
