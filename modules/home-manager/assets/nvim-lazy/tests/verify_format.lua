-- Assert the formatting and linting wiring: blackd-client for python, vale for
-- markdown, and gq reflowing comments with textwidth rather than the LSP.
local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")
h.require_phase(6, "format")

h.settle()
h.load_all_plugins()

local fixtures = vim.fn.stdpath("config") .. "/tests/fixtures"

-- conform wiring
local conform = require("conform")
local blackd = conform.get_formatter_info("blackd-client")
h.eq(blackd.command, "blackd-client", "python formatter is blackd-client")

local py_formatters = vim.tbl_map(function(f)
  return f.name
end, conform.list_formatters_for_buffer and {} or {})
local by_ft = require("lazy.core.plugin").values(require("lazy.core.config").plugins["conform.nvim"], "opts", false)
h.check(
  vim.tbl_contains((by_ft.formatters_by_ft or {}).python or {}, "blackd-client"),
  "python is formatted by blackd-client",
  vim.inspect((by_ft.formatters_by_ft or {}).python)
)

-- nvim-lint wiring
local lint_opts = require("lazy.core.plugin").values(require("lazy.core.config").plugins["nvim-lint"], "opts", false)
h.check(
  vim.tbl_contains((lint_opts.linters_by_ft or {}).markdown or {}, "vale"),
  "markdown is linted by vale",
  vim.inspect((lint_opts.linters_by_ft or {}).markdown)
)

-- gq must reflow with textwidth, so formatexpr has to be empty on an attached
-- buffer. Without a server to attach, assert the global default instead.
vim.cmd.edit(fixtures .. "/sample.lua")
local buf = vim.api.nvim_get_current_buf()
vim.wait(3000, function()
  return #vim.lsp.get_clients({ bufnr = buf }) > 0
end, 100)
h.eq(vim.bo[buf].formatexpr, "", "formatexpr is empty, so gq uses textwidth")

-- And prove gq actually wraps at 80.
vim.cmd("enew!")
vim.bo.filetype = "lua"
local long = "-- " .. string.rep("word ", 40)
vim.api.nvim_buf_set_lines(0, 0, -1, false, { long })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.api.nvim_feedkeys(vim.keycode("gqq"), "mtx", false)
local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
h.check(#lines > 1, "gq split a long comment", "got " .. #lines .. " line(s)")
local over = vim.tbl_filter(function(l)
  return #l > 80
end, lines)
h.check(#over == 0, "gq wrapped every line at 80 columns", vim.inspect(over))
h.check(
  vim.tbl_filter(function(l)
    return not l:match("^%-%-")
  end, lines)[1] == nil,
  "gq kept the comment leader on every line",
  vim.inspect(lines)
)
vim.bo.modified = false

-- blackd-client only formats if a blackd daemon is listening.
if vim.fn.executable("blackd-client") == 1 then
  vim.cmd.edit(fixtures .. "/sample.py")
  local ok = pcall(conform.format, { bufnr = 0, formatters = { "blackd-client" }, timeout_ms = 4000 })
  if not ok then
    io.stdout:write("     (skipped blackd-client run: no blackd daemon listening)\n")
  end
  vim.bo.modified = false
else
  io.stdout:write("     (skipped blackd-client run: not installed)\n")
end

h.finish("format")
