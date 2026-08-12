-- Loaded on VeryLazy, after LazyVim's own autocmds.

-- LazyVim soft-wraps prose filetypes; neither lvim nor the legacy config ever
-- did, and `wrap` with textwidth=80 mostly hides where lines really end. Keep
-- the spell half, which the legacy config had for markdown.
pcall(vim.api.nvim_del_augroup_by_name, "lazyvim_wrap_spell")
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("jry_spell", { clear = true }),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.spell = true
  end,
})
