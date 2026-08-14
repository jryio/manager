-- Dump every global mapping as JSON, for baseline capture and manifest authoring.
--   nvim --headless -c "luafile tests/dump_keymaps.lua" -c qa
-- Writes to $NVIM_DUMP_OUT, or stdout when unset. Runs against any config
-- (including lvim), so every plugin interaction is best-effort.
pcall(vim.api.nvim_exec_autocmds, "User", { pattern = "VeryLazy", modeline = false })
vim.wait(200, function() return false end)

pcall(function()
  local Config = require("lazy.core.config")
  require("lazy").load({ plugins = vim.tbl_keys(Config.plugins), wait = true })
  vim.wait(500, function() return false end)
end)

local out = {}
for _, mode in ipairs({ "n", "i", "v", "x", "s", "o", "c", "t" }) do
  local maps = {}
  for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
    maps[m.lhs] = {
      rhs = m.rhs,
      desc = m.desc,
      callback = m.callback ~= nil,
      noremap = m.noremap == 1,
      silent = m.silent == 1,
      expr = m.expr == 1,
    }
  end
  out[mode] = maps
end

local json = vim.json.encode(out)
local path = vim.env.NVIM_DUMP_OUT
if path and path ~= "" then
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local fh = assert(io.open(path, "w"))
  fh:write(json)
  fh:close()
  io.stdout:write("wrote " .. path .. "\n")
else
  io.stdout:write(json .. "\n")
end
vim.cmd("qa!")
