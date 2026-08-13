-- Statusline, bufferline and the rest of the visible furniture, ported from the
-- STATUSLINE block of assets/lvim/config.lua and its LunarVim components.
--
-- LunarVim's components live in lvim.core.lualine.*, which does not exist here,
-- so the handful he uses are rebuilt from lualine builtins with the same icons,
-- colours and conditions.

-- lvim/core/lualine/colors.lua
local colors = {
  green = "#98be65",
  yellow = "#ECBE7B",
  red = "#ec5f67",
  -- his own nord overrides, from config.lua
  nord1 = "#3B4252",
  nord3 = "#232527", -- modified to match tomorrow-night
  nord5 = "#E5E9F0",
  nord6 = "#ECEFF4",
  nord7 = "#8FBCBB",
  nord8 = "#88C0D0",
  nord14 = "#EBCB8B",
}

-- Nerd Font glyphs, spelled as escapes because they are load-bearing: an
-- earlier pass through this file replaced all eight with a bare space, which
-- silently emptied the git, diagnostic and treesitter indicators. Names and
-- codepoints are lvim/icons.lua's.
local icons = {
  line_added = "\u{eadc}",
  line_modified = "\u{eade}",
  line_removed = "\u{eadf}",
  bold_error = "\u{f057}",
  bold_warning = "\u{f071}",
  bold_information = "\u{f05a}",
  bold_hint = "\u{ea61}",
  tree = "\u{f1bb}",
}

-- Powerline separators, escaped for the same reason. These are what make the
-- sections meet in arrows; blank strings leave the statusline in flat blocks.
local seps = {
  right_arrow = "\u{e0b0}",
  left_arrow = "\u{e0b2}",
  thin_right = "\u{e0b1}",
  thin_left = "\u{e0b3}",
}

-- lvim/core/lualine/conditions.lua
local function hide_in_width()
  return vim.o.columns > 100
end

local function diff_source()
  local gitsigns = vim.b.gitsigns_status_dict
  if gitsigns then
    return { added = gitsigns.added, modified = gitsigns.changed, removed = gitsigns.removed }
  end
end

local components = {
  filename = { "filename", color = {}, cond = nil },
  diff = {
    "diff",
    source = diff_source,
    symbols = {
      added = icons.line_added .. " ",
      modified = icons.line_modified .. " ",
      removed = icons.line_removed .. " ",
    },
    padding = { left = 2, right = 1 },
    diff_color = {
      added = { fg = colors.green },
      modified = { fg = colors.yellow },
      removed = { fg = colors.red },
    },
    cond = nil,
  },
  diagnostics = {
    "diagnostics",
    sources = { "nvim_diagnostic" },
    symbols = {
      error = icons.bold_error .. " ",
      warn = icons.bold_warning .. " ",
      info = icons.bold_information .. " ",
      hint = icons.bold_hint .. " ",
    },
  },
  treesitter = {
    function()
      return icons.tree
    end,
    color = function()
      local ts = vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()]
      return { fg = ts and not vim.tbl_isempty(ts) and colors.green or colors.red }
    end,
    cond = hide_in_width,
  },
  location = { "location" },
  encoding = { "o:encoding", fmt = string.upper, color = {}, cond = hide_in_width },
  filetype = { "filetype", cond = nil, padding = { left = 1, right = 1 } },
}

--- [current/total] for the active search, blank when nothing is highlighted.
local function search_result()
  if vim.v.hlsearch == 0 then
    return ""
  end
  local last_search = vim.fn.getreg("/", 0, {})
  if not last_search or last_search == "" then
    return ""
  end
  local searchcount = vim.fn.searchcount({ maxcount = 9999 })
  return "[" .. searchcount.current .. "/" .. searchcount.total .. "]"
end

local function modified()
  if vim.bo.modified then
    return "+"
  elseif vim.bo.modifiable == false or vim.bo.readonly == true then
    return "-"
  end
  return ""
end

local scrollbar = {
  function()
    local current_line = vim.fn.line(".")
    local total_lines = vim.fn.line("$")
    local chars = { "__", "▁▁", "▂▂", "▃▃", "▄▄", "▅▅", "▆▆", "▇▇", "██" }
    local line_ratio = current_line / total_lines
    if current_line == 1 then
      return "Top"
    elseif line_ratio == 1.0 then
      return "Bot"
    end
    return chars[math.ceil(line_ratio * #chars)]
  end,
  padding = { left = 1, right = 1 },
  color = { fg = colors.nord14, bg = colors.nord3 },
  cond = nil,
}

--- Insert an empty component between every real one, then give each a single
--- angled separator, so sections meet in arrows instead of blocks.
local function process_sections(sections)
  local empty = require("lualine.component"):extend()
  function empty:draw(default_highlight)
    self.status = ""
    self.applied_separator = ""
    self:apply_highlights(default_highlight)
    self:apply_section_separators()
    return self.status
  end

  for name, section in pairs(sections) do
    local left = name:sub(9, 10) < "x"
    for pos = 1, name ~= "lualine_z" and #section or #section - 1 do
      -- Deliberately uncoloured. lvim writes `color = { fg = colors.white, bg =
      -- colors.white }` against a palette that defines no `white`, so both are
      -- nil and the spacer inherits its section's colour. Giving it a real
      -- colour instead makes lualine emit a static highlight rather than a
      -- transitional one, and the  arrows between sections disappear.
      table.insert(section, pos * 2, { empty, color = {} })
    end
    for id, comp in ipairs(section) do
      if type(comp) ~= "table" then
        comp = { comp }
        section[id] = comp
      end
      comp.separator = left and { right = seps.right_arrow } or { left = seps.left_arrow }
      -- lualine_z holds the scrollbar, so it gets no left arrow. Empty in lvim
      -- too, unlike the two above.
      if name == "lualine_z" and id == 3 and not left then
        comp.separator = { left = "" }
      end
    end
  end
  return sections
end

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function()
      return {
        options = {
          theme = {
            normal = {
              a = { fg = colors.nord1, bg = colors.nord8 },
              b = { fg = colors.nord5, bg = colors.nord1 },
              c = { fg = colors.nord5, bg = colors.nord3 },
            },
            insert = { a = { fg = colors.nord1, bg = colors.nord6 } },
            visual = { a = { fg = colors.nord1, bg = colors.nord7 } },
            -- lvim names `colors.nord13` here, which its palette never defines,
            -- so replace mode keeps the normal-mode background. Reproduced
            -- rather than corrected: nord14 would recolour a real mode.
            replace = { a = { fg = colors.nord1 } },
            inactive = {
              a = { fg = colors.nord1, bg = colors.nord8 },
              b = { fg = colors.nord5, bg = colors.nord1 },
              c = { fg = colors.nord5, bg = colors.nord1 },
            },
          },
          component_separators = "",
          section_separators = { left = seps.thin_right, right = seps.thin_left },
          globalstatus = vim.o.laststatus == 3,
          -- lvim's start screen has no statusline; the row is simply blank.
          disabled_filetypes = { statusline = { "snacks_dashboard", "alpha" } },
        },
        sections = process_sections({
          lualine_a = { "mode" },
          lualine_b = {
            components.filename,
            components.diff,
            -- lvim asks for `bg = colors.red` from a palette with no `red`; the
            -- `+` therefore draws in the section's own colours.
            { modified, color = {} },
            { "%w", cond = function() return vim.wo.previewwindow end },
            { "%r", cond = function() return vim.bo.readonly end },
            { "%q", cond = function() return vim.bo.buftype == "quickfix" end },
          },
          lualine_c = { components.diagnostics },
          lualine_x = { search_result, components.filetype },
          lualine_y = { components.treesitter, components.location },
          lualine_z = { components.encoding, scrollbar },
        }),
        inactive_sections = {
          lualine_b = { "branch" },
          lualine_c = { "%f %y %m" },
          lualine_x = {},
        },
        extensions = { "lazy" },
      }
    end,
  },

  -- Unclickable, no close icons: buffers are closed with ,w and ,q.
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        close_command = false,
        right_mouse_command = false,
        middle_mouse_command = false,
        show_buffer_close_icons = false,
        show_close_icon = false,
        sort_by = "insert_at_end",
      },
    },
  },

  -- File icons come from nvim-web-devicons, as in lvim. LazyVim substitutes
  -- mini.icons and preloads it under the devicons module name, which changes
  -- both glyph and colour: a Lua buffer showed  (DevIconLua) in lvim against
  -- 󰢱 (MiniIconsAzure) here, in the statusline and the winbar alike.
  -- The repository moved; naming it by its old name makes LazyVim warn about a
  -- rename on every start, disabled or not.
  { "nvim-mini/mini.icons", enabled = false },
  {
    "nvim-tree/nvim-web-devicons",
    lazy = false,
    config = function()
      require("nvim-web-devicons").setup({})

      -- lvim pins devicons at e37bb1f (May 2024) and upstream has since
      -- recoloured fifteen icons -- Go from #519ABA to the official #00ADD8,
      -- YAML from grey to red, and so on. Rather than pin two years back and
      -- lose every icon added since, the old colours are restored by name.
      -- Regenerate by diffing the DevIcon groups of two `pty.sh dump` files.
      local overrides = {
        DevIconBSPWM = "#2F2F2F",
        DevIconCMake = "#6D8086",
        DevIconCMakeLists = "#6D8086",
        DevIconCss = "#42A5F5",
        DevIconD = "#427819",
        DevIconFreeCAD = "#CB0D0D",
        DevIconFreeCADConfig = "#CB0D0D",
        DevIconGo = "#519ABA",
        DevIconLogos = "#599EFF",
        DevIconMailmap = "#41535B",
        DevIconNotebook = "#51A0CF",
        DevIconUI = "#0C306E",
        DevIconVala = "#7239B3",
        DevIconYaml = "#6D8086",
        DevIconYml = "#6D8086",
      }

      -- devicons redefines these groups on every colourscheme change.
      local function apply()
        for group, fg in pairs(overrides) do
          vim.api.nvim_set_hl(0, group, { fg = fg })
        end
      end
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("devicon_parity", { clear = true }),
        callback = apply,
      })
      apply()
    end,
  },

  -- lvim has no noice: the command line is a real row at the bottom of the
  -- screen and messages print into it. LazyVim routes both through noice, which
  -- sets cmdheight to 0 and opens a floating command box mid-screen instead.
  { "folke/noice.nvim", enabled = false },
  { "rcarriga/nvim-notify", enabled = false },

  -- lvim's indent-guide exclusions, on LazyVim's snacks indent.
  {
    "folke/snacks.nvim",
    opts = {
      indent = {
        -- indent-blankline drew lvim's guides with lvim.icons.ui.LineLeft;
        -- snacks defaults to a full-height box char, which reads heavier.
        indent = { char = "▏" },
        scope = { char = "▏" },
        filter = function(buf)
          local excluded = {
            help = true,
            terminal = true,
            nofile = true,
            alpha = true,
            snacks_dashboard = true,
            ["lsp-installer"] = true,
            lspinfo = true,
            minimap = true,
          }
          return vim.g.snacks_indent ~= false
            and vim.b[buf].snacks_indent ~= false
            and vim.bo[buf].buftype == ""
            and not excluded[vim.bo[buf].filetype]
        end,
      },
    },
  },

  {
    "wfxr/minimap.vim",
    -- The code-minimap binary is already installed for lvim.
    build = "cargo install --locked code-minimap",
    -- Not lazy: minimap_auto_start only takes effect at load, and lvim shows the
    -- minimap from the moment a file opens.
    lazy = false,
    keys = {
      { "<leader>mm", "<cmd>MinimapToggle<cr>", desc = "Minimap Toggle" },
    },
    config = function()
      -- minimap_auto_start is deliberately off; this autocmd replaces it,
      -- because the plugin's own version misfires at both ends of startup:
      --
      --   * it opens on the nameless buffer of a bare `nvim`, and that second
      --     window makes the dashboard decline to draw -- lvim never has this
      --     problem, since alpha claims the buffer before BufWinEnter and
      --     "alpha" is in the block list, whereas "snacks_dashboard" is not the
      --     filetype yet at that point;
      --   * it misses the file named on the command line entirely, whose
      --     BufWinEnter has already fired by the time the plugin loads.
      --
      -- A real, named file buffer is what lvim shows a minimap for.
      local function wanted()
        return vim.bo.buftype == ""
          and vim.api.nvim_buf_get_name(0) ~= ""
          and not vim.tbl_contains(vim.g.minimap_block_filetypes or {}, vim.bo.filetype)
      end

      local function open_here()
        if wanted() then
          pcall(vim.cmd, "Minimap")
        end
      end

      vim.api.nvim_create_autocmd("BufWinEnter", {
        group = vim.api.nvim_create_augroup("minimap_parity", { clear = true }),
        callback = open_here,
      })

      -- The delay is not decoration. Called at VimEnter, or scheduled straight
      -- after it, :Minimap reports success and leaves no window -- the
      -- code-minimap job is spawned while the layout is still settling. 300ms
      -- past VimEnter it sticks.
      if vim.v.vim_did_enter == 1 then
        vim.defer_fn(open_here, 300)
      else
        vim.api.nvim_create_autocmd("VimEnter", {
          once = true,
          callback = function()
            vim.defer_fn(open_here, 300)
          end,
        })
      end
    end,
    init = function()
      local ignore_filetypes = {
        "help",
        "alpha",
        "snacks_dashboard",
        "neo-tree",
        "NvimTree",
        "startify",
        "lsp-installer",
        "lspinfo",
        "nofile",
      }
      -- Off on purpose; the BufWinEnter autocmd in `config` does this job.
      vim.g.minimap_auto_start = 0
      vim.g.minimap_auto_start_win_enter = 0
      vim.g.minimap_highlight_range = 1
      vim.g.minimap_highlight_search = 1
      vim.g.minimap_git_colors = 1
      vim.g.minimap_block_filetypes = ignore_filetypes
      vim.g.minimap_block_buftypes = ignore_filetypes
      vim.g.minimap_close_filetypes = ignore_filetypes
      vim.g.minimap_close_buftypes = ignore_filetypes
    end,
  },

  -- lvim used the archived romgrk fork; this is the maintained one, same opts.
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "LazyFile",
    opts = {
      enable = true,
      max_lines = 0,
      multiline_threshold = 1,
    },
  },

  -- symbols-outline.nvim is archived; outline.nvim is its successor. The command
  -- changes from :SymbolsOutline to :Outline, so <leader>o moves with it.
  {
    "hedyhli/outline.nvim",
    cmd = { "Outline", "OutlineOpen" },
    keys = {
      { "<leader>o", "<cmd>Outline<cr>", desc = "Symbols Outline" },
    },
    opts = {
      outline_window = { width = 45, relative_width = false },
    },
  },

  -- Trouble is a LazyVim default; this is lvim's group for it, in v3 syntax.
  -- LazyVim's own <leader>x group stays.
  {
    "folke/trouble.nvim",
    keys = {
      { "<leader>tr", "<cmd>Trouble lsp_references toggle<cr>", desc = "References" },
      { "<leader>tf", "<cmd>Trouble lsp_definitions toggle<cr>", desc = "Definitions" },
      { "<leader>td", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics" },
      { "<leader>tq", "<cmd>Trouble qflist toggle<cr>", desc = "QuickFix" },
      { "<leader>tl", "<cmd>Trouble loclist toggle<cr>", desc = "LocationList" },
      { "<leader>tw", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace Diagnostics" },
    },
  },
}
