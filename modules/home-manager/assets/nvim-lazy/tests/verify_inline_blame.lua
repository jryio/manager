local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")

h.settle()
h.load_all_plugins()
vim.cmd("edit lua/plugins/git.lua")

local bufnr = vim.api.nvim_get_current_buf()
local namespace = vim.api.nvim_get_namespaces().blame_ns
local expected = vim.api.nvim_buf_line_count(bufnr)
local rendered = vim.wait(2000, function()
  if not namespace then
    namespace = vim.api.nvim_get_namespaces().blame_ns
  end
  return namespace and #vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {}) == expected
end, 25)

h.check(rendered, "inline blame annotates every line")
if namespace then
  h.eq(
    #vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {}),
    expected,
    "inline blame annotation count matches buffer lines"
  )
end

h.finish("inline blame")
