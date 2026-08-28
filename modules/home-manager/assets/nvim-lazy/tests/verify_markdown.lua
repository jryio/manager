local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")

h.settle()
h.load_all_plugins()
vim.cmd("enew!")
vim.cmd("setfiletype markdown")

h.eq(vim.wo.wrap, true, "markdown buffers soft-wrap")

local config = require("render-markdown.state").get(vim.api.nvim_get_current_buf())
h.eq(config.anti_conceal.enabled, false, "tables stay rendered under cursor")
h.eq(config.pipe_table.enabled, true, "pipe tables render")

for _, component in ipairs({
  "bullet",
  "checkbox",
  "code",
  "dash",
  "document",
  "heading",
  "html",
  "indent",
  "inline_highlight",
  "latex",
  "link",
  "paragraph",
  "quote",
  "sign",
  "yaml",
}) do
  h.eq(config[component].enabled, false, component .. " stays raw")
end

h.finish("markdown")
