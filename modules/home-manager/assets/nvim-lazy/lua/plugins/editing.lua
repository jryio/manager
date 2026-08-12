-- Editing plugins carried over from lvim and the legacy config.
return {
  -- ys / cs / ds. LazyVim 16 ships no surround plugin, so nothing to displace.
  { "tpope/vim-surround", event = "VeryLazy" },

  -- Reads .env files into the vim environment.
  { "tpope/vim-dotenv", event = "VeryLazy" },

  {
    "bkad/CamelCaseMotion",
    event = "VeryLazy",
    config = function()
      -- Recursive maps, as in lvim, so `cw` -> `ce` reaches the CamelCase `e`
      -- too. lvim leaves select mode mapped as well; the legacy config sunmapped
      -- it. Following lvim.
      vim.cmd([[
        map <silent> w <Plug>CamelCaseMotion_w
        map <silent> b <Plug>CamelCaseMotion_b
        map <silent> e <Plug>CamelCaseMotion_e
        map <silent> ge <Plug>CamelCaseMotion_ge
      ]])
    end,
  },

  -- Grow and shrink the visual selection. The plan offered treesitter
  -- incremental selection instead, but nvim-treesitter's main branch dropped
  -- that module, and this is what his fingers already know.
  {
    "terryma/vim-expand-region",
    keys = {
      { "v", "<Plug>(expand_region_expand)", mode = "v" },
      { "<C-v>", "<Plug>(expand_region_shrink)", mode = "v" },
    },
  },

  {
    "cappyzawa/trim.nvim",
    event = "BufWritePre",
    opts = { ft_blocklist = { "markdown" } },
  },

  {
    "norcalli/nvim-colorizer.lua",
    event = "VeryLazy",
    config = function()
      require("colorizer").setup({ "*" }, {
        RGB = true,
        RRGGBB = true,
        RRGGBBAA = true,
        rgb_fn = true,
        hsl_fn = true,
        css = true,
        css_fn = true,
      })
    end,
  },

  -- Close a buffer without taking the window with it.
  {
    "mhinz/vim-sayonara",
    cmd = "Sayonara",
    keys = {
      { ",w", "<cmd>Sayonara!<cr>", desc = "Close Buffer" },
      { ",q", "<cmd>Sayonara<cr>", desc = "Close Buffer and Window" },
    },
  },

  -- Stack vertical splits so more than a few stay usable.
  {
    "mattboehm/vim-accordion",
    cmd = { "Accordion", "AccordionStop", "AccordionZoomIn", "AccordionZoomOut" },
    keys = {
      { "<leader>vv", "<cmd>Accordion 3<cr>", desc = "Start" },
      { "<leader>vs", "<cmd>AccordionStop<cr>", desc = "Stop" },
      { "<leader>v4", "<cmd>Accordion 4<cr>", desc = "Accordion 4" },
      { "<leader>v+", "<cmd>AccordionZoomIn<cr>", desc = "Zoom In <size + 1>" },
      { "<leader>v-", "<cmd>AccordionZoomOut<cr>", desc = "Zoom Out <size - 1>" },
    },
  },

  -- todo-comments is a LazyVim default; this is lvim's own group for it.
  -- LazyVim's ]t, [t, <leader>st and <leader>x{t,T} all stay.
  {
    "folke/todo-comments.nvim",
    keys = {
      { "<leader>Tl", "<cmd>Trouble todo toggle<cr>", desc = "List" },
      {
        "<leader>Ts",
        function()
          Snacks.picker.todo_comments()
        end,
        desc = "Search",
      },
      {
        "<leader>Tn",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "Next Comment",
      },
      {
        "<leader>Tk",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "Prev Comment",
      },
    },
  },
}
