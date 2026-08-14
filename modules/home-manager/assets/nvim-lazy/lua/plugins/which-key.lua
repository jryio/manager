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
        { "<leader>a", group = "AI", mode = { "n", "v" } },
        -- LazyVim labels <leader>f "file/find", but <leader>f is a command here
        -- and the group moved to <leader>F. See lua/plugins/picker.lua.
        { "<leader>F", group = "file/find" },
      },
    },
  },
}
