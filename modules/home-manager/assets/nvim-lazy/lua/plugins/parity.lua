-- Stop LazyVim replacing vim behaviour that lvim leaves alone.
--
-- Both settings below go through LazyVim.set_default, which records its baseline
-- *after* lua/config/options.lua has run. It therefore cannot tell our value
-- from its own default and overrides it anyway, so setting the option harder
-- does not help -- the feature has to be off.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      -- Folds stay manual, as in lvim.
      folds = { enable = false },
      -- Classic indent, as in lvim, which indents from ftplugin (GetLuaIndent
      -- and friends). Treesitter indent differs visibly: with it on, `S` on
      -- "abcdef" leaves "abc" / "  def" in a Lua buffer where lvim leaves
      -- "abc" / "def", and the same gap shows up on every o, O and =.
      indent = { enable = false },
    },
  },
  -- The LSP spec spells the same fold flag `enabled`, not `enable`.
  { "neovim/nvim-lspconfig", opts = { folds = { enabled = false } } },
}
