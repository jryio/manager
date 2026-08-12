-- Group names for the prefixes Jacob's bindings introduce. Added per phase,
-- alongside the bindings themselves.
return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>S", group = "Session" },
        { "<leader>T", group = "Todo" },
        { "<leader>v", group = "Accordion" },
        { "<leader>t", group = "Trouble" },
        { "<leader>m", group = "Minimap" },
        { "<leader>n", group = "Explorer" },
        { "<leader>l", group = "LSP" },
      },
    },
  },
}
