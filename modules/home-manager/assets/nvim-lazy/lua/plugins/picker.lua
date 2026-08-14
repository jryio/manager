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
        -- snacks dims the whole screen behind the picker (snacks.win's default
        -- backdrop is 60% toward black), which measures as the editor's
        -- #1D1F21 background dropping to #111213 while the picker is open.
        -- lvim's telescope never dimmed anything, so turn it off; only the
        -- `default` preset asks for it, the others already say false.
        layout = { layout = { backdrop = false } },
        sources = {
          -- Which tool lists the files is the whole cost of opening the picker:
          -- the matcher needs 2-4ms for 5,000 paths, but the listing dominates.
          -- Measured at 20ms for rg against 85ms for the fd that was on PATH (a
          -- cargo-installed 8.5.3 from 2022, since displaced by the brew one).
          -- snacks prefers fd, so ask for rg, which modules/darwin/homebrew.nix
          -- declares; fall back to the default where it is missing.
          files = vim.fn.executable("rg") == 1 and { cmd = "rg" } or {},
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

      -- lvim's muscle memory: <leader>f finds files.
      --
      -- Nothing longer may share this prefix. When it does, nvim has to wait out
      -- `timeoutlen` -- 500ms, per lvim -- on every press to find out whether a
      -- longer mapping is coming, which it measures as a picker that takes
      -- 600ms to appear instead of 85ms. LazyVim's file/find group therefore
      -- lives on <leader>F below, key for key.
      {
        "<leader>f",
        function()
          Snacks.picker.files()
        end,
        desc = "Find File",
      },

      -- LazyVim's file/find group, moved off <leader>f wholesale.
      { "<leader>ff", false },
      { "<leader>fF", false },
      { "<leader>fg", false },
      { "<leader>fr", false },
      { "<leader>fR", false },
      { "<leader>fb", false },
      { "<leader>fB", false },
      { "<leader>fc", false },
      { "<leader>fe", false },
      { "<leader>fE", false },
      { "<leader>fp", false },
      { "<leader>Ff", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
      { "<leader>FF", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
      { "<leader>Fg", function() Snacks.picker.git_files() end, desc = "Find Files (git-files)" },
      { "<leader>Fr", function() Snacks.picker.recent() end, desc = "Recent" },
      { "<leader>FR", function() Snacks.picker.recent({ filter = { cwd = true } }) end, desc = "Recent (cwd)" },
      { "<leader>Fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>FB", function() Snacks.picker.buffers({ hidden = true, nofile = true }) end, desc = "Buffers (all)" },
      { "<leader>Fc", LazyVim.pick.config_files(), desc = "Find Config File" },
      { "<leader>Fe", function() Snacks.explorer({ cwd = LazyVim.root() }) end, desc = "Explorer Snacks (root dir)" },
      { "<leader>FE", function() Snacks.explorer() end, desc = "Explorer Snacks (cwd)" },
      { "<leader>Fp", function() Snacks.picker.projects() end, desc = "Projects" },

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
