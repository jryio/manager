-- The 1:1 keybinding contract, ported from assets/lvim/config.lua and the
-- legacy comma-leader assets/nvim/init.vim.
--
-- Entry fields:
--   mode    single-mode string, as nvim_get_keymap uses it
--   lhs     a leading "<leader>" is expanded to vim.g.mapleader by the verifier
--   rhs     exact right-hand side
--   desc    exact description (use for callback maps, which have no rhs)
--   has     substring of the rhs (for long or escape-heavy right-hand sides)
--   absent  true when the key must be unmapped (a deleted LazyVim default)
--   phase   the phase that introduces it; the verifier skips later phases
--
-- Prefer `desc`/`has` over `rhs` when asserting a LazyVim default we keep, so
-- upstream rewording of an implementation doesn't fail the suite.
return {
  -- ---------------------------------------------------------------- phase 0
  -- LazyVim defaults the plan keeps as-is; here to prove the verifier runs and
  -- to catch upstream regressions on bindings Jacob relies on.
  { mode = "n", lhs = "j", desc = "Down", phase = 0 },
  { mode = "n", lhs = "k", desc = "Up", phase = 0 },
  { mode = "x", lhs = ">", rhs = ">gv", phase = 0 },
  { mode = "n", lhs = "[q", desc = "Previous Trouble/Quickfix Item", phase = 0 },
  { mode = "n", lhs = "]q", desc = "Next Trouble/Quickfix Item", phase = 0 },

  -- ---------------------------------------------------------------- phase 2
  -- insert
  { mode = "i", lhs = "<C-c>", rhs = "<Esc>", phase = 2 },
  { mode = "i", lhs = "<Up>", rhs = "<Nop>", phase = 2 },
  { mode = "i", lhs = "<Down>", rhs = "<Nop>", phase = 2 },
  { mode = "i", lhs = "<Left>", rhs = "<Nop>", phase = 2 },
  { mode = "i", lhs = "<Right>", rhs = "<Nop>", phase = 2 },
  { mode = "i", lhs = "<F1>", rhs = "<Nop>", phase = 2 },
  { mode = "i", lhs = "<A-j>", absent = true, phase = 2 },
  { mode = "i", lhs = "<A-k>", absent = true, phase = 2 },
  { mode = "v", lhs = "<A-j>", absent = true, phase = 2 },
  { mode = "v", lhs = "<A-k>", absent = true, phase = 2 },

  -- normal: buffers, writing, clipboard
  { mode = "n", lhs = "+", rhs = "<cmd>bnext<cr>", phase = 2 },
  { mode = "n", lhs = "_", rhs = "<cmd>bprevious<cr>", phase = 2 },
  { mode = "n", lhs = ",s", rhs = "<cmd>w<cr>", phase = 2 },
  { mode = "n", lhs = ",y", rhs = '"+y', phase = 2 },
  { mode = "v", lhs = ",y", rhs = '"+y', phase = 2 },
  { mode = "n", lhs = ",yy", rhs = '"+yy', phase = 2 },
  { mode = "n", lhs = ",p", rhs = '"+p', phase = 2 },

  -- normal: windows
  { mode = "n", lhs = "<M-l>", rhs = "10<C-w>>", phase = 2 },
  { mode = "n", lhs = "<M-h>", rhs = "10<C-w><", phase = 2 },
  { mode = "n", lhs = "<M-j>", rhs = "10<C-w>-", phase = 2 },
  { mode = "n", lhs = "<M-k>", rhs = "10<C-w>+", phase = 2 },
  { mode = "n", lhs = "<C-h>", rhs = "<C-w>h", phase = 2 },
  { mode = "n", lhs = "<C-j>", rhs = "<C-w>j", phase = 2 },
  { mode = "n", lhs = "<C-k>", rhs = "<C-w>k", phase = 2 },
  { mode = "n", lhs = "<C-l>", rhs = "<C-w>l", phase = 2 },
  { mode = "n", lhs = "<C-Up>", absent = true, phase = 2 },
  { mode = "n", lhs = "<C-Down>", absent = true, phase = 2 },
  { mode = "n", lhs = "<C-Left>", absent = true, phase = 2 },
  { mode = "n", lhs = "<C-Right>", absent = true, phase = 2 },
  { mode = "n", lhs = "<C-w>z", desc = "Zoom Window", phase = 2 },

  -- normal: motion and scrolling
  { mode = "n", lhs = "gj", rhs = "5j", phase = 2 },
  { mode = "n", lhs = "gk", rhs = "5k", phase = 2 },
  { mode = "v", lhs = "gj", rhs = "5j", phase = 2 },
  { mode = "v", lhs = "gk", rhs = "5k", phase = 2 },
  { mode = "n", lhs = "n", rhs = ":norm! nzz<cr>", phase = 2 },
  { mode = "n", lhs = "N", rhs = ":norm! Nzz<cr>", phase = 2 },
  { mode = "v", lhs = "n", rhs = ":norm! nzz<cr>", phase = 2 },
  { mode = "v", lhs = "N", rhs = ":norm! Nzz<cr>", phase = 2 },
  { mode = "n", lhs = "<C-u>", rhs = "<C-u>zz", phase = 2 },
  { mode = "n", lhs = "<C-d>", rhs = "<C-d>zz", phase = 2 },
  { mode = "n", lhs = "<C-f>", rhs = "<C-f>zz", phase = 2 },
  { mode = "n", lhs = "<C-b>", rhs = "<C-b>zz", phase = 2 },
  { mode = "n", lhs = "H", rhs = "^", phase = 2 },
  { mode = "n", lhs = "L", rhs = "$", phase = 2 },

  -- normal: editing
  { mode = "n", lhs = "Y", rhs = "<cmd>%y+<cr>", phase = 2 },
  { mode = "n", lhs = "c", rhs = '"_c', phase = 2 },
  { mode = "v", lhs = "c", rhs = '"_c', phase = 2 },
  { mode = "n", lhs = "dw", rhs = "de", phase = 2 },
  { mode = "n", lhs = "cw", rhs = '"_ce', phase = 2 },
  { mode = "n", lhs = "p", rhs = "p`]", phase = 2 },
  { mode = "n", lhs = "J", rhs = "mzJ`z", phase = 2 },
  { mode = "n", lhs = "S", rhs = "mzi<CR><Esc>`z", phase = 2 },
  { mode = "n", lhs = "gp", rhs = "`[v`]", phase = 2 },
  { mode = "n", lhs = "<Tab>", rhs = "%", phase = 2 },

  -- normal: disabled keys
  { mode = "n", lhs = "<Up>", rhs = "<Nop>", phase = 2 },
  { mode = "n", lhs = "<Down>", rhs = "<Nop>", phase = 2 },
  { mode = "n", lhs = "<Left>", rhs = "<Nop>", phase = 2 },
  { mode = "n", lhs = "<Right>", rhs = "<Nop>", phase = 2 },
  { mode = "n", lhs = "<BS>", rhs = "<Nop>", phase = 2 },
  { mode = "n", lhs = "<Del>", rhs = "<Nop>", phase = 2 },
  { mode = "n", lhs = "<F1>", rhs = "<Nop>", phase = 2 },
  { mode = "n", lhs = "q", rhs = "<Nop>", phase = 2 },
  { mode = "n", lhs = "Q", rhs = "<Nop>", phase = 2 },

  -- normal: diagnostics
  { mode = "n", lhs = "[g", desc = "Prev Diagnostic", phase = 2 },
  { mode = "n", lhs = "]g", desc = "Next Diagnostic", phase = 2 },

  -- visual
  { mode = "v", lhs = "y", rhs = "y`]", phase = 2 },
  { mode = "v", lhs = "p", rhs = '"_dP`]', phase = 2 },
  { mode = "v", lhs = "J", rhs = ":m '>+1<cr>gv=gv", phase = 2 },
  { mode = "v", lhs = "K", rhs = ":m '<-2<cr>gv=gv", phase = 2 },
  { mode = "v", lhs = "<C-r>", has = ":%s/", phase = 2 },
  { mode = "v", lhs = "H", rhs = "^", phase = 2 },
  { mode = "v", lhs = "L", rhs = "$", phase = 2 },
  { mode = "x", lhs = "<", rhs = "<gv", phase = 2 },
  { mode = "v", lhs = "<leader>s", rhs = ":!sort<cr>", phase = 2 },

  -- leader
  { mode = "n", lhs = "<leader>h", has = "nohlsearch", phase = 2 },
  { mode = "n", lhs = "<leader>z", rhs = "za", phase = 2 },
  { mode = "n", lhs = "<leader>/", rhs = "gcc", phase = 2 },
  { mode = "x", lhs = "<leader>/", rhs = "gc", phase = 2 },
  { mode = "n", lhs = "<leader>Sr", desc = "Restore session for current dir", phase = 2 },
  { mode = "n", lhs = "<leader>SR", desc = "Restore last session", phase = 2 },
  { mode = "n", lhs = "<leader>SQ", desc = "Quit without saving session", phase = 2 },
  { mode = "n", lhs = "<leader>S", absent = true, phase = 2 },
  { mode = "n", lhs = "<leader>l", absent = true, phase = 2 },
  { mode = "n", lhs = "<leader>L", rhs = "<cmd>Lazy<cr>", phase = 2 },

  -- terminal
  { mode = "t", lhs = "<Esc>", rhs = "<C-\\><C-n>", phase = 2 },
  { mode = "t", lhs = "<C-j>", rhs = "<C-\\><C-n><C-w>j", phase = 2 },
  { mode = "t", lhs = "<C-k>", rhs = "<C-\\><C-n><C-w>k", phase = 2 },
  { mode = "t", lhs = "<C-l>", rhs = "<C-\\><C-n><C-w>l", phase = 2 },

  -- cmdline
  { mode = "c", lhs = "ww", rhs = "wqall", phase = 2 },
  { mode = "c", lhs = "qq", rhs = "qall", phase = 2 },

  -- ---------------------------------------------------------------- phase 3
  { mode = "n", lhs = ",w", rhs = "<cmd>Sayonara!<cr>", phase = 3 },
  { mode = "n", lhs = ",q", rhs = "<cmd>Sayonara<cr>", phase = 3 },
  { mode = "n", lhs = "w", has = "CamelCaseMotion_w", phase = 3 },
  { mode = "n", lhs = "b", has = "CamelCaseMotion_b", phase = 3 },
  { mode = "n", lhs = "e", has = "CamelCaseMotion_e", phase = 3 },
  { mode = "n", lhs = "ge", has = "CamelCaseMotion_ge", phase = 3 },
  { mode = "v", lhs = "v", has = "expand_region_expand", phase = 3 },
  { mode = "v", lhs = "<C-v>", has = "expand_region_shrink", phase = 3 },
  { mode = "n", lhs = "<leader>vv", rhs = "<cmd>Accordion 3<cr>", phase = 3 },
  { mode = "n", lhs = "<leader>vs", rhs = "<cmd>AccordionStop<cr>", phase = 3 },
  { mode = "n", lhs = "<leader>v4", rhs = "<cmd>Accordion 4<cr>", phase = 3 },
  { mode = "n", lhs = "<leader>v+", rhs = "<cmd>AccordionZoomIn<cr>", phase = 3 },
  { mode = "n", lhs = "<leader>v-", rhs = "<cmd>AccordionZoomOut<cr>", phase = 3 },
  { mode = "n", lhs = "<leader>Tl", rhs = "<cmd>Trouble todo toggle<cr>", phase = 3 },
  { mode = "n", lhs = "<leader>Ts", desc = "Search", phase = 3 },
  { mode = "n", lhs = "<leader>Tn", desc = "Next Comment", phase = 3 },
  { mode = "n", lhs = "<leader>Tk", desc = "Prev Comment", phase = 3 },

  -- ---------------------------------------------------------------- phase 4
  { mode = "n", lhs = "<leader>mm", rhs = "<cmd>MinimapToggle<cr>", phase = 4 },
  { mode = "n", lhs = "<leader>o", rhs = "<cmd>Outline<cr>", phase = 4 },
  { mode = "n", lhs = "<leader>tr", rhs = "<cmd>Trouble lsp_references toggle<cr>", phase = 4 },
  { mode = "n", lhs = "<leader>tf", rhs = "<cmd>Trouble lsp_definitions toggle<cr>", phase = 4 },
  { mode = "n", lhs = "<leader>td", rhs = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", phase = 4 },
  { mode = "n", lhs = "<leader>tq", rhs = "<cmd>Trouble qflist toggle<cr>", phase = 4 },
  { mode = "n", lhs = "<leader>tl", rhs = "<cmd>Trouble loclist toggle<cr>", phase = 4 },
  { mode = "n", lhs = "<leader>tw", rhs = "<cmd>Trouble diagnostics toggle<cr>", phase = 4 },

  -- ---------------------------------------------------------------- phase 5
  { mode = "n", lhs = "<leader>e", desc = "Explorer", phase = 5 },
  { mode = "n", lhs = "<leader>f", desc = "Find File", phase = 5 },
  { mode = "n", lhs = "<leader>P", desc = "Projects", phase = 5 },
  { mode = "n", lhs = "<leader>sb", desc = "Checkout branch", phase = 5 },
  { mode = "n", lhs = "<leader>sc", desc = "Colorscheme", phase = 5 },
  { mode = "n", lhs = "<leader>sf", desc = "Find File", phase = 5 },
  { mode = "n", lhs = "<leader>sh", desc = "Find Help", phase = 5 },
  { mode = "n", lhs = "<leader>sH", desc = "Find highlight groups", phase = 5 },
  { mode = "n", lhs = "<leader>sM", desc = "Man Pages", phase = 5 },
  { mode = "n", lhs = "<leader>sr", desc = "Open Recent File", phase = 5 },
  { mode = "n", lhs = "<leader>sR", desc = "Registers", phase = 5 },
  { mode = "n", lhs = "<leader>st", desc = "Text", phase = 5 },
  { mode = "n", lhs = "<leader>sk", desc = "Keymaps", phase = 5 },
  { mode = "n", lhs = "<leader>sC", desc = "Commands", phase = 5 },
  { mode = "n", lhs = "<leader>sl", desc = "Resume last search", phase = 5 },
  { mode = "n", lhs = "<leader>sp", desc = "Colorscheme with Preview", phase = 5 },
  { mode = "n", lhs = "<leader>nf", desc = "Reveal File", phase = 5 },

  -- ---------------------------------------------------------------- phase 6
  { mode = "n", lhs = "<leader>la", desc = "Code Action", phase = 6 },
  { mode = "n", lhs = "<leader>lj", desc = "Next Diagnostic", phase = 6 },
  { mode = "n", lhs = "<leader>lk", desc = "Prev Diagnostic", phase = 6 },
  { mode = "n", lhs = "<leader>lr", desc = "Rename", phase = 6 },
  { mode = "n", lhs = "<leader>lf", desc = "Format", phase = 6 },
  { mode = "n", lhs = "<leader>ld", rhs = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", phase = 6 },
  { mode = "n", lhs = "<leader>li", rhs = "<cmd>checkhealth vim.lsp<cr>", phase = 6 },
}
