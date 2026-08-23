local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")

h.settle()
h.load_all_plugins()
vim.cmd.edit(vim.fn.stdpath("config") .. "/tests/fixtures/sample.lua")
vim.api.nvim_win_set_cursor(0, { 1, 0 })

local config = require("gitsigns.config").config
h.check(config.current_line_blame, "current-line blame is enabled")
h.eq(config.current_line_blame_opts.virt_text_pos, "eol", "current-line blame follows source text")

local namespace = vim.api.nvim_get_namespaces().gitsigns_blame
local rendered = vim.wait(2000, function()
  if not namespace then
    namespace = vim.api.nvim_get_namespaces().gitsigns_blame
  end
  if not namespace then
    return false
  end
  local marks = vim.api.nvim_buf_get_extmarks(0, namespace, 0, -1, { details = true })
  return #marks == 1 and marks[1][2] == 0 and marks[1][4].virt_text_pos == "eol"
end, 25)

h.check(rendered, "current-line blame renders one end-of-line annotation")
h.finish("current-line blame")
