-- Retire LazyVim default keys that Jacob's bindings claim.
--
-- These live in plugin `keys` specs rather than LazyVim's config/keymaps.lua, so
-- `false` in the spec is the supported way to drop them. Deleting them from
-- lua/config/keymaps.lua would work by load-order luck alone.
return {
  -- H and L are line ends, not buffer cycling; `+` and `_` cycle buffers.
  -- [b and ]b stay, as a second way round.
  {
    "akinsho/bufferline.nvim",
    keys = {
      { "<S-h>", false },
      { "<S-l>", false },
    },
  },

  -- S splits a line, the sister to J. Flash keeps s and its other entries.
  {
    "folke/flash.nvim",
    keys = {
      { "S", false, mode = { "n", "o", "x" } },
    },
  },

  -- <leader>S heads the session group. Scratch buffers keep <leader>.
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>S", false },
    },
  },
}
