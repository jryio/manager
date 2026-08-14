-- Loaded after LazyVim's own defaults, before lazy.nvim starts.
-- Ported from assets/lvim/config.lua's VIM OPTIONS block.
local opt = vim.opt

opt.textwidth = 80

-- LazyVim uses 300. Higher keeps which-key from appearing constantly.
opt.timeoutlen = 500

opt.mouse = ""
opt.cursorlineopt = "number"

-- LazyVim ships "jcroqlnt": this drops `o` and adds `v`. Filetype plugins still
-- amend it per buffer, exactly as they already do under lvim (a Lua buffer
-- settles on "vjncroql", because ftplugin/lua.vim removes `t`).
opt.formatoptions = "qcrntjlv"

-- Appended rather than assigned, to keep the default two-character `tab` entry;
-- a single-character tab listchar raises E474.
opt.list = true
opt.listchars:append("eol:¬")
opt.listchars:append("extends:❯")
opt.listchars:append("precedes:❮")
opt.listchars:append("trail:·")
opt.listchars:append("nbsp:·")

-- Manual folds. LazyVim would otherwise let treesitter and the LSP install a
-- foldexpr, which also fights `gq` reflowing comments.
opt.foldmethod = "manual"
opt.foldexpr = ""

-- lvim sets lsp.buffer_options.formatexpr = "" so `gq` reflows comments with
-- textwidth and formatoptions instead of asking conform or the language server.
-- LazyVim installs v:lua.LazyVim.format.formatexpr() during its own options, and
-- this file loads after it. Neovim reinstalls one on LSP attach, which
-- lua/plugins/formatting.lua clears again.
opt.formatexpr = ""

-- Carried over from the legacy config, dictionary and all.
opt.spellfile = vim.fn.stdpath("config") .. "/spell/dictionary.utf-8.add"

-- lvim has no scroll or window animation; match it.
vim.g.snacks_animate = false

----------------------------------------------------------------
-- LAYOUT PARITY
----------------------------------------------------------------
-- Every option below was found by diffing the two editors' running state,
-- rather than by reading either config, so the list is what actually differed.

-- The command line lives at the bottom of the screen, one row high. LazyVim
-- hands it to noice, which hides the row entirely (cmdheight 0) and opens a
-- floating box mid-screen instead; noice is disabled in lua/plugins/ui.lua.
opt.cmdheight = 1

-- Absolute line numbers. LazyVim turns relativenumber on.
opt.relativenumber = false

-- No concealing: lvim shows quotes in JSON and markup characters as typed.
opt.conceallevel = 0

-- LazyVim replaces the number column with its own statuscolumn (fold column
-- plus signs plus number). lvim uses the stock one, which is why its gutter is
-- a column wider and carries the LineNr background.
opt.statuscolumn = ""

-- Stock fillchars: `~` past the end of the buffer, and no fold glyphs. LazyVim
-- sets "eob: " among others, which blanks the tildes.
opt.fillchars = ""

opt.scrolloff = 8
opt.pumblend = 0
opt.showcmd = false
