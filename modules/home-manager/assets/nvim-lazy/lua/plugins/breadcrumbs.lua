-- The winbar: file icon, file name, then the LSP symbol path to the cursor.
--
-- lvim draws this on every file window (lvim/core/breadcrumbs.lua); LazyVim has
-- no winbar at all, which the layout diff showed as lvim `winbar=" %#DevIconLua#..."`
-- against LazyVim's empty string. Ported here with the same icons, the same
-- separator and the same exclusion list, on the same plugin, nvim-navic.

local icons = {
  -- lvim's ui.ChevronRight, a codicon rather than the font-awesome chevron.
  chevron = "\u{eab6}",
  -- lvim's ui.Circle, glyph then a trailing space.
  circle = "\u{f111} ",
  kind = {
    Array = "\u{ea8a} ",
    Boolean = "\u{ea8f} ",
    Class = "\u{eb5b} ",
    Color = "\u{eb5c} ",
    Constant = "\u{eb5d} ",
    Constructor = "\u{ea8c} ",
    Enum = "\u{ea95} ",
    EnumMember = "\u{eb5e} ",
    Event = "\u{ea86} ",
    Field = "\u{eb5f} ",
    File = "\u{ea7b} ",
    Folder = "\u{f024b} ",
    Function = "\u{ea8c} ",
    Interface = "\u{eb61} ",
    Key = "\u{ea93} ",
    Keyword = "\u{eb62} ",
    Method = "\u{ea8c} ",
    Module = "\u{eb29} ",
    Namespace = "\u{ea8b} ",
    Null = "\u{f07e2} ",
    Number = "\u{ea90} ",
    Object = "\u{ea8b} ",
    Operator = "\u{eb64} ",
    Package = "\u{eb29} ",
    Property = "\u{eb65} ",
    Reference = "\u{eb36} ",
    Snippet = "\u{eb66} ",
    String = "\u{eb8d} ",
    Struct = "\u{ea91} ",
    Text = "\u{ea93} ",
    TypeParameter = "\u{ea92} ",
    Unit = "\u{ea96} ",
    Value = "\u{ea93} ",
    Variable = "\u{ea88} ",
  },
}

local exclude = {
  "help",
  "startify",
  "dashboard",
  "snacks_dashboard",
  "lazy",
  "neo-tree",
  "neogitstatus",
  "NvimTree",
  "Trouble",
  "trouble",
  "alpha",
  "lir",
  "Outline",
  "outline",
  "spectre_panel",
  "toggleterm",
  "DressingSelect",
  "Jaq",
  "harpoon",
  "dap-repl",
  "dap-terminal",
  "dapui_console",
  "dapui_hover",
  "lab",
  "notify",
  "noice",
  "neotest-summary",
  "minimap",
  "snacks_picker_list",
  "snacks_picker_input",
  "grug-far",
  "",
}

local function isempty(s)
  return s == nil or s == ""
end

--- " <devicon> <filename>", with the icon in the devicon's own colour.
local function filename_segment()
  local name = vim.fn.expand("%:t")
  if isempty(name) then
    return ""
  end

  local icon, hl_group = " ", "Normal"
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if ok then
    icon, hl_group = devicons.get_icon(name, vim.fn.expand("%:e"), { default = true })
    if isempty(icon) then
      icon = icons.kind.File
    end
  end

  -- lvim repoints Winbar at Normal's foreground each time it draws, which is
  -- what keeps the winbar readable after a colourscheme change.
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  vim.api.nvim_set_hl(0, "Winbar", { fg = normal.fg })

  return " %#" .. hl_group .. "#" .. icon .. "%* %#Winbar#" .. name .. "%*"
end

local function navic_segment()
  local ok, navic = pcall(require, "nvim-navic")
  if not ok or not navic.is_available() then
    return ""
  end
  local located, location = pcall(navic.get_location, {})
  if not located or location == "error" or isempty(location) then
    return ""
  end
  return "%#NavicSeparator#" .. icons.chevron .. "%* " .. location
end

local function draw()
  if vim.tbl_contains(exclude, vim.bo.filetype) then
    return
  end

  local value = filename_segment()
  if isempty(value) then
    return
  end

  local crumbs = navic_segment()
  value = value .. " " .. crumbs

  if vim.api.nvim_get_option_value("mod", { buf = 0 }) then
    local mod = "%#LspCodeLens#" .. icons.circle .. "%*"
    value = isempty(crumbs) and (value .. mod) or (value .. " " .. mod)
  end

  local tabs = #vim.api.nvim_list_tabpages()
  if tabs > 1 then
    value = value .. "%=" .. vim.api.nvim_tabpage_get_number(0) .. "/" .. tabs
  end

  pcall(vim.api.nvim_set_option_value, "winbar", value, { scope = "local" })
end

return {
  {
    "SmiteshP/nvim-navic",
    lazy = false,
    opts = {
      icons = icons.kind,
      highlight = true,
      separator = " " .. icons.chevron .. " ",
      depth_limit = 0,
      depth_limit_indicator = "..",
      lsp = { auto_attach = true },
    },
    config = function(_, opts)
      require("nvim-navic").setup(opts)

      vim.api.nvim_create_augroup("_winbar", { clear = true })
      vim.api.nvim_create_autocmd({
        "CursorHold",
        "CursorHoldI",
        "BufWinEnter",
        "BufFilePost",
        "InsertEnter",
        "BufWritePost",
        "TabClosed",
        "TabEnter",
      }, {
        group = "_winbar",
        callback = function()
          -- lvim skips windows holding an LSP hover, which have this set.
          if not pcall(vim.api.nvim_buf_get_var, 0, "lsp_floating_window") then
            draw()
          end
        end,
      })
    end,
  },
}
