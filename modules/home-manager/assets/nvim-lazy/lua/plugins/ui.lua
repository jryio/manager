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
    symbols = { added = " ", modified = " ", removed = " " },
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
    symbols = { error = " ", warn = " ", info = " ", hint = " " },
  },
  treesitter = {
    function()
      return ""
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
      table.insert(section, pos * 2, { empty, color = { fg = colors.nord3, bg = colors.nord3 } })
    end
    for id, comp in ipairs(section) do
      if type(comp) ~= "table" then
        comp = { comp }
        section[id] = comp
      end
      comp.separator = left and { right = "" } or { left = "" }
      -- lualine_z holds the scrollbar, so it gets no left arrow
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
            replace = { a = { fg = colors.nord1, bg = colors.nord14 } },
            inactive = {
              a = { fg = colors.nord1, bg = colors.nord8 },
              b = { fg = colors.nord5, bg = colors.nord1 },
              c = { fg = colors.nord5, bg = colors.nord1 },
            },
          },
          component_separators = "",
          section_separators = { left = "", right = "" },
          globalstatus = vim.o.laststatus == 3,
        },
        sections = process_sections({
          lualine_a = { "mode" },
          lualine_b = {
            components.filename,
            components.diff,
            { modified, color = { fg = colors.red } },
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

  -- lvim's indent-guide exclusions, on LazyVim's snacks indent.
  {
    "folke/snacks.nvim",
    opts = {
      indent = {
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
    cmd = { "Minimap", "MinimapClose", "MinimapToggle", "MinimapRefresh", "MinimapUpdateHighlight" },
    keys = {
      { "<leader>mm", "<cmd>MinimapToggle<cr>", desc = "Minimap Toggle" },
    },
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
      vim.g.minimap_auto_start = 1
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
