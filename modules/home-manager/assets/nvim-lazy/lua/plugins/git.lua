-- Git.
--
-- LazyVim does bind ]h and [h inside gitsigns' `on_attach`, so they are
-- buffer-local and only appear once gitsigns has attached. In practice they were
-- missing from an attached, tracked buffer under force-load, so the four hunk
-- keys the legacy config used are bound here as ordinary global maps instead.
-- Guaranteed present, and assertable.
return {
  {
    "lewis6991/gitsigns.nvim",
    keys = {
      {
        "]h",
        function()
          require("gitsigns").nav_hunk("next")
        end,
        desc = "Next Hunk",
      },
      {
        "[h",
        function()
          require("gitsigns").nav_hunk("prev")
        end,
        desc = "Prev Hunk",
      },
      {
        ",hs",
        function()
          require("gitsigns").stage_hunk()
        end,
        desc = "Stage Hunk",
      },
      {
        ",hr",
        function()
          require("gitsigns").reset_hunk()
        end,
        desc = "Reset Hunk",
      },
    },
  },

  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
    -- octo defaults to telescope, which is not installed here.
    opts = { picker = "snacks" },
  },
}
