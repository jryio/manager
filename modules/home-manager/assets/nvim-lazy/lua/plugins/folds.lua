-- Keep folds manual, as lvim has them.
--
-- LazyVim otherwise flips foldmethod to "expr" per buffer and installs a
-- treesitter or LSP foldexpr. It does that through LazyVim.set_default, which
-- records its baseline *after* lua/config/options.lua has run, so it cannot
-- tell our foldmethod=manual from its own default and overrides it regardless.
-- Setting the option harder does not help; disabling the feature does.
--
-- The two keys really do differ: treesitter reads `folds.enable`, the LSP spec
-- reads `folds.enabled`.
return {
  { "nvim-treesitter/nvim-treesitter", opts = { folds = { enable = false } } },
  { "neovim/nvim-lspconfig", opts = { folds = { enabled = false } } },
}
