-- Dump the whole visible surface -- highlight groups plus the options that
-- decide layout -- as JSON, for lvim/LazyVim comparison.
--
--   tests/visual/pty.sh dump lvim /tmp/lvim.json
--
-- Must run in a terminal, not headlessly: minimal.nvim aborts with
-- "&termguicolors must be set" and lvim then reports nvim's default palette.
--
-- Links are followed to their definition, so `@variable -> Identifier` compares
-- as the colour it actually paints, not as the name it borrows.
local out = vim.env.NVIM_DUMP_OUT or "/dev/stdout"

pcall(vim.api.nvim_exec_autocmds, "User", { pattern = "VeryLazy", modeline = false })
vim.wait(500, function()
  return false
end)

local function hex(n)
  return n and string.format("#%06X", n) or nil
end

--- Follow `link=` chains to the group that actually carries the attributes.
local function resolve(name, seen)
  seen = seen or {}
  if seen[name] then
    return {}
  end
  seen[name] = true
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name })
  if not ok or not hl then
    return {}
  end
  if hl.link then
    local target = resolve(hl.link, seen)
    target.__link = hl.link
    return target
  end
  return hl
end

local groups = {}
for name in pairs(vim.api.nvim_get_hl(0, {})) do
  local hl = resolve(name)
  groups[name] = {
    fg = hex(hl.fg),
    bg = hex(hl.bg),
    sp = hex(hl.sp),
    bold = hl.bold or nil,
    italic = hl.italic or nil,
    underline = hl.underline or nil,
    undercurl = hl.undercurl or nil,
    strikethrough = hl.strikethrough or nil,
    reverse = hl.reverse or nil,
    link = hl.__link,
  }
end

-- Everything that moves a glyph on screen, as opposed to colouring one.
local layout = {}
for _, name in ipairs({
  "background", "cmdheight", "colorcolumn", "conceallevel", "cursorline",
  "cursorlineopt", "fillchars", "foldcolumn", "foldenable", "laststatus",
  "linespace", "list", "listchars", "number", "numberwidth", "pumblend",
  "pumheight", "relativenumber", "ruler", "scrolloff", "showcmd", "showmode",
  "showtabline", "sidescrolloff", "signcolumn", "statuscolumn", "statusline",
  "tabline", "termguicolors", "winbar", "winblend", "wrap",
}) do
  local ok, value = pcall(function()
    return vim.api.nvim_get_option_value(name, {})
  end)
  -- Spelled out rather than `ok and value or nil`, which would drop every
  -- option that is legitimately false.
  if ok then
    layout[name] = value
  end
end

-- Diagnostics are drawn into the buffer, so their glyphs and prefixes are part
-- of the visible surface too.
local function diagnostic_config()
  local ok, cfg = pcall(vim.diagnostic.config)
  if not ok or type(cfg) ~= "table" then
    return nil
  end
  local function describe(value)
    if type(value) == "function" then
      return "<function>"
    end
    return value
  end
  return {
    virtual_text = type(cfg.virtual_text) == "table" and vim.tbl_map(describe, cfg.virtual_text) or describe(cfg.virtual_text),
    signs = type(cfg.signs) == "table" and vim.tbl_map(describe, cfg.signs) or describe(cfg.signs),
    underline = describe(cfg.underline),
    update_in_insert = cfg.update_in_insert,
    severity_sort = describe(cfg.severity_sort),
    float = type(cfg.float) == "table" and vim.tbl_map(describe, cfg.float) or describe(cfg.float),
  }
end

local payload = {
  colorscheme = vim.g.colors_name,
  diagnostics = diagnostic_config(),
  background = vim.o.background,
  termguicolors = vim.o.termguicolors,
  layout = layout,
  plugins = (function()
    local ok, Config = pcall(require, "lazy.core.config")
    if not ok then
      return nil
    end
    local names = {}
    for name, spec in pairs(Config.plugins) do
      names[name] = spec._.loaded ~= nil
    end
    return names
  end)(),
  groups = groups,
}

local fd = assert(io.open(out, "w"))
fd:write(vim.json.encode(payload))
fd:close()
io.stdout:write(string.format("\nHARNESS ok   dump_visual -> %s (%d groups)\n", out, vim.tbl_count(groups)))
vim.cmd("qa!")
