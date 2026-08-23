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
    "FabijanZulj/blame.nvim",
    lazy = false,
    opts = {
      virtual_style = "right_align",
      max_summary_width = 40,
      colors = { "#515457" },
    },
    config = function(_, opts)
      opts.format_fn = require("blame.formats.default_formats").date_message
      local blame = require("blame")
      blame.setup(opts)

      local displayed_buffer
      local function show_blame(buf)
        if vim.api.nvim_get_current_buf() ~= buf or vim.bo[buf].buftype ~= "" or not vim.b[buf].gitsigns_head then
          return
        end
        if displayed_buffer == buf then
          return
        end
        if blame.is_open() then
          vim.cmd("BlameToggle")
        end
        vim.cmd("BlameToggle virtual")
        displayed_buffer = buf
      end

      local group = vim.api.nvim_create_augroup("inline_git_blame", { clear = true })
      vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        callback = function(args)
          show_blame(args.buf)
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "GitSignsUpdate",
        callback = function(args)
          show_blame(args.data and args.data.bufnr or args.buf)
        end,
      })
    end,
  },

  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
    -- octo defaults to telescope, which is not installed here.
    opts = { picker = "snacks" },
  },
}
