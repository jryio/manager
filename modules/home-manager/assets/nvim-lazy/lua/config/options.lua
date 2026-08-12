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

-- Carried over from the legacy config, dictionary and all.
opt.spellfile = vim.fn.stdpath("config") .. "/spell/dictionary.utf-8.add"

-- lvim has no scroll or window animation; match it.
vim.g.snacks_animate = false
