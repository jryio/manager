-- The colourscheme, which lvim sets in one line: lvim.colorscheme = "minimal-base16".
--
-- minimal.nvim is Jacob's own fork, and the `minimal-base16` variant is the one
-- with the tomorrow-night palette merged in (commit 851a421, "Modify theme to
-- match old tomorrow night"), so it is pinned rather than tracked.
--
-- Measured parity: LazyVim's default
-- tokyonight-moon differed from this in 89 of the 92 groups a user looks at.
return {
  {
    "thebearjew/minimal.nvim",
    lazy = false,
    priority = 1000,
    -- Read at load time by lua/minimal-base16/config.lua, so `init`, not `config`.
    init = function()
      vim.g.minimal_italic_comments = true
    end,
  },

  { "LazyVim/LazyVim", opts = { colorscheme = "minimal-base16" } },

  -- LazyVim's own themes, neither of which is ever shown now.
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", enabled = false },
}
