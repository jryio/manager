-- Loaded on VeryLazy, after LazyVim's own keymaps, so a plain set overrides them.
--
-- Ported 1:1 from assets/lvim/config.lua and the legacy comma-leader
-- assets/nvim/init.vim. Where the two disagree, lvim wins: it is the config he
-- actually drives. Bindings that need a plugin arrive with that plugin's phase.
local map = vim.keymap.set

--- LazyVim moves its defaults around between releases; a missing key here means
--- upstream renamed something rather than that we no longer care. The manifest
--- entries in tests/keymap_manifest.lua assert the deletion actually happened.
local function del(mode, lhs)
  pcall(vim.keymap.del, mode, lhs)
end

-- ---------------------------------------------------------------------- insert

-- Control-C sends no KeyboardInterrupt to Lua callbacks this way.
map("i", "<C-c>", "<Esc>", { desc = "Escape" })

for _, key in ipairs({ "<Up>", "<Down>", "<Left>", "<Right>", "<F1>" }) do
  map("i", key, "<Nop>")
end

-- LazyVim moves lines with these; lvim leaves them alone.
del("i", "<A-j>")
del("i", "<A-k>")
del("v", "<A-j>")
del("v", "<A-k>")

-- ---------------------------------------------------------------------- normal

-- Buffers
map("n", "+", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "_", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })

-- Write
map("n", ",s", "<cmd>w<cr>", { desc = "Save" })

-- System clipboard, from the legacy config
map("n", ",y", '"+y', { desc = "Yank to clipboard" })
map("v", ",y", '"+y', { desc = "Yank to clipboard" })
map("n", ",yy", '"+yy', { desc = "Yank line to clipboard" })
map("n", ",p", '"+p', { desc = "Paste from clipboard" })

-- Resize by ten. Same keys as LazyVim's move-line, which these replace.
map("n", "<M-l>", "10<C-w>>", { desc = "Widen" })
map("n", "<M-h>", "10<C-w><", { desc = "Narrow" })
map("n", "<M-j>", "10<C-w>-", { desc = "Shorten" })
map("n", "<M-k>", "10<C-w>+", { desc = "Heighten" })

-- LazyVim 16 ships no window-navigation keys, so these are additions.
map("n", "<C-h>", "<C-w>h", { desc = "Left Window" })
map("n", "<C-j>", "<C-w>j", { desc = "Lower Window" })
map("n", "<C-k>", "<C-w>k", { desc = "Upper Window" })
map("n", "<C-l>", "<C-w>l", { desc = "Right Window" })

-- lvim unmaps LazyVim's arrow-key resizes.
del("n", "<C-Up>")
del("n", "<C-Down>")
del("n", "<C-Left>")
del("n", "<C-Right>")

-- Bigger steps. j/k already move by display line, count-aware, from LazyVim.
map({ "n", "v" }, "gj", "5j", { desc = "Down 5" })
map({ "n", "v" }, "gk", "5k", { desc = "Up 5" })

-- Keep the cursor centred while searching and scrolling.
map({ "n", "v" }, "n", ":norm! nzz<cr>", { silent = true, desc = "Next Search Result" })
map({ "n", "v" }, "N", ":norm! Nzz<cr>", { silent = true, desc = "Prev Search Result" })
map({ "n", "v" }, "<C-u>", "<C-u>zz")
map({ "n", "v" }, "<C-d>", "<C-d>zz")
map({ "n", "v" }, "<C-f>", "<C-f>zz")
map({ "n", "v" }, "<C-b>", "<C-b>zz")

-- Line ends, not screen top and bottom.
map("n", "H", "^", { desc = "Line Start" })
map("n", "L", "$", { desc = "Line End" })

-- Whole file to the system clipboard, rather than an alias for yy.
map("n", "Y", "<cmd>%y+<cr>", { desc = "Yank File to Clipboard" })

-- Changing text should not clobber the unnamed register. lvim maps this to
-- <NOP>, which silently breaks `c` outright; the legacy config parks the text in
-- register x. The black hole is what both were reaching for.
map({ "n", "v" }, "c", '"_c', { desc = "Change (no yank)" })

-- :help dw -- vim treats the last word of a line specially.
--
-- `cw` spells out the black hole rather than leaning on the `c` mapping above.
-- Recursive, as the legacy config had it, `ce` also picks up CamelCaseMotion's
-- `e`, which sits one character short under an operator and leaves the last
-- letter behind. Non-recursive without the register, `cw` would clobber the very
-- register `c` exists to protect. This way `cw` and `dw` stay symmetric.
map("n", "dw", "de")
map("n", "cw", '"_ce')

-- Land at the end of pasted or joined text instead of the start.
map("n", "p", "p`]", { desc = "Paste" })
map("n", "J", "mzJ`z", { desc = "Join Lines" })
map("n", "S", "mzi<CR><Esc>`z", { desc = "Split Line" })
map("n", "gp", "`[v`]", { desc = "Reselect Paste" })

-- Matching pair. Recursive on purpose, so matchit answers rather than builtin %.
map({ "n", "x", "o" }, "<Tab>", "%", { remap = true, desc = "Matching Pair" })

-- Zoom a split. Replaces the legacy vim-maximizer binding, no plugin needed.
map("n", "<C-w>z", function()
  Snacks.zen.zoom()
end, { desc = "Zoom Window" })

-- Keys that only ever fire by accident.
for _, key in ipairs({ "<Up>", "<Down>", "<Left>", "<Right>", "<BS>", "<Del>", "<F1>", "q", "Q" }) do
  map("n", key, "<Nop>")
end

-- Diagnostics, under the legacy coc bindings. LazyVim's ]d and [d still work.
map("n", "[g", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev Diagnostic" })
map("n", "]g", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next Diagnostic" })

-- ------------------------------------------------------------------ visual

-- Land at the end of the operated text, and paste without losing the register.
map("v", "y", "y`]", { desc = "Yank" })
map("v", "p", '"_dP`]', { desc = "Paste" })

-- Move the selection.
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

-- Substitute the selection across the file.
map("v", "<C-r>", '"hy:%s/<C-r>h//gc<left><left><left>', { desc = "Replace Selection" })

-- lvim has visual H and L match normal mode; the legacy config used g_ for L.
map("v", "H", "^", { desc = "Line Start" })
map("v", "L", "$", { desc = "Line End" })

-- LazyVim ships > but not <.
map("x", "<", "<gv", { desc = "Indent Left" })

map("v", "<leader>s", ":!sort<cr>", { desc = "Sort" })

-- ---------------------------------------------------------------------- leader

-- Clear the highlight and the search register, so n does not resurrect it.
map("n", "<leader>h", "<cmd>let @/ = '' | nohlsearch<cr>", { desc = "No Highlight" })

map("n", "<leader>z", "za", { desc = "Toggle Fold" })

-- Comment, as in lvim. LazyVim puts grep here; grep is on <leader>sg.
map("n", "<leader>/", "gcc", { remap = true, desc = "Toggle Comment" })
map("x", "<leader>/", "gc", { remap = true, desc = "Toggle Comment" })

-- Sessions. LazyVim also keeps its own <leader>q group.
map("n", "<leader>Sr", function()
  require("persistence").load()
end, { desc = "Restore session for current dir" })
map("n", "<leader>SR", function()
  require("persistence").load({ last = true })
end, { desc = "Restore last session" })
map("n", "<leader>SQ", function()
  require("persistence").stop()
end, { desc = "Quit without saving session" })

-- <leader>l heads the LSP group from phase 6, so Lazy moves up a case. That
-- displaces LazyVim's changelog binding, which :LazyVim changelog still reaches.
del("n", "<leader>l")
map("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- -------------------------------------------------------------------- terminal

-- Single escape, as in the legacy config. LazyVim wants it pressed twice.
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Normal Mode" })

-- The legacy config leaves <C-h> alone here, since terminals send it for
-- backspace.
map("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Lower Window" })
map("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Upper Window" })
map("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Right Window" })

-- ------------------------------------------------------------------- cmdline

map("c", "ww", "wqall")
map("c", "qq", "qall")
