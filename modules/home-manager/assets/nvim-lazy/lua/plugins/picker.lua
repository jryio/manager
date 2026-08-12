-- Picker and file tree, on snacks: LazyVim 16's default for both.
--
-- lvim drove telescope and nvim-tree, so this maps his layout onto the snacks
-- equivalents rather than reinstalling either. LazyVim's own <leader>f and
-- <leader>s bindings stay where they do not collide.
return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = { replace_netrw = true },
      picker = {
        sources = {
          explorer = {
            win = {
              list = {
                keys = {
                  -- h and l already collapse and expand, a adds, d deletes,
                  -- r renames, c copies and p pastes. These are the gaps
                  -- against his nvim-tree and Zed habits.
                  ["A"] = "explorer_add",
                  ["x"] = "explorer_move",
                  ["Y"] = "explorer_yank_relative",
                },
              },
            },
            actions = {
              -- snacks yanks absolute paths; Zed's project panel copies the
              -- path relative to the project, which is what he reaches for.
              explorer_yank_relative = function(picker)
                local paths = {}
                for _, item in ipairs(picker:selected({ fallback = true })) do
                  table.insert(paths, vim.fn.fnamemodify(Snacks.picker.util.path(item), ":."))
                end
                local value = table.concat(paths, "\n")
                vim.fn.setreg(vim.v.register or "+", value, "l")
                Snacks.notify.info("Yanked " .. #paths .. " relative path(s)")
              end,
            },
          },
        },
      },
    },
    keys = {
      -- Explorer, straight onto <leader>e rather than through <leader>fe.
      {
        "<leader>e",
        function()
          Snacks.explorer()
        end,
        desc = "Explorer",
      },

      -- lvim's muscle memory: <leader>f finds files. LazyVim's file group is
      -- still reachable at <leader>f{f,r,c,...}, and <leader><space> too.
      {
        "<leader>f",
        function()
          Snacks.picker.files()
        end,
        desc = "Find File",
      },

      {
        "<leader>P",
        function()
          Snacks.picker.projects()
        end,
        desc = "Projects",
      },

      -- The lvim search group, source for source.
      { "<leader>sb", function() Snacks.picker.git_branches() end, desc = "Checkout branch" },
      { "<leader>sc", function() Snacks.picker.colorschemes() end, desc = "Colorscheme" },
      { "<leader>sf", function() Snacks.picker.files() end, desc = "Find File" },
      { "<leader>sh", function() Snacks.picker.help() end, desc = "Find Help" },
      { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Find highlight groups" },
      { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
      { "<leader>sr", function() Snacks.picker.recent() end, desc = "Open Recent File" },
      { "<leader>sR", function() Snacks.picker.registers() end, desc = "Registers" },
      -- Text search. Displaces LazyVim's <leader>st (Todo), which lives on
      -- <leader>Ts from phase 3, and on <leader>sT.
      { "<leader>st", function() Snacks.picker.grep() end, desc = "Text" },
      { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
      { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
      { "<leader>sl", function() Snacks.picker.resume() end, desc = "Resume last search" },
      { "<leader>sp", function() Snacks.picker.colorschemes() end, desc = "Colorscheme with Preview" },

      -- lvim closed the minimap before revealing the tree, so the tree would not
      -- be resized by it. Kept: minimap.vim still resizes windows the same way.
      {
        "<leader>nf",
        function()
          pcall(vim.cmd, "MinimapClose")
          Snacks.explorer.reveal()
        end,
        desc = "Reveal File",
      },
    },
  },

  -- His <leader>st is text search; todo search is <leader>Ts and <leader>sT.
  {
    "folke/todo-comments.nvim",
    keys = {
      { "<leader>st", false },
    },
  },

  -- <leader>sr opens recent files, as in lvim. Two plugins claiming one key is
  -- a race, and grug-far was winning it; :GrugFar still reaches search-replace.
  {
    "MagicDuck/grug-far.nvim",
    keys = {
      { "<leader>sr", false },
    },
  },
}
