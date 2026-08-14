-- Loaded on VeryLazy, after LazyVim's own autocmds.

----------------------------------------------------------------
-- HIGHLIGHT PARITY
----------------------------------------------------------------
-- snacks draws several things lvim drew with other plugins, and reaches for
-- different highlight groups to do it. Each link below points snacks at the
-- group its lvim counterpart used, so the colourscheme stays the single source
-- of the colour.
--
-- These live here rather than in the snacks plugin specs because lazy.nvim
-- keeps only the LAST `init` among a plugin's spec fragments -- it does not
-- chain them. Two snacks fragments with an `init` each means one is silently
-- dropped, which is exactly how the dashboard links went missing.
-- A string value links to that group; a table is set as attributes.
local groups = {
  -- indent guides: indent-blankline's groups, which minimal.nvim still defines
  SnacksIndent = "IndentBlanklineChar",
  SnacksIndentScope = "IndentBlanklineContextChar",
  -- start screen: alpha's banner was Label, its entries Normal, its keys Include
  SnacksDashboardHeader = "Label",
  SnacksDashboardIcon = "Normal",
  SnacksDashboardDesc = "Normal",
  SnacksDashboardKey = "Include",
  -- Floating windows -- the picker above all -- sit on NormalFloat, which this
  -- theme paints #1A1C1D against the editor's own #1D1F21. lvim's telescope
  -- windows measured as #1D1F21, so point snacks at Normal and the picker stops
  -- reading as a darker panel.
  SnacksNormal = "Normal",
  SnacksNormalNC = "Normal",
  -- The picker paints each of its windows through its own group rather than
  -- NormalFloat directly, so all four have to be named.
  SnacksPicker = "Normal",
  SnacksPickerList = "Normal",
  SnacksPickerInput = "Normal",
  SnacksPickerPreview = "Normal",
  -- Other occurrences of the symbol under the cursor. lvim marks them with
  -- vim-illuminate, whose IlluminatedWord* groups underline; LazyVim uses
  -- neovim's own LSP document highlight, and LspReference* is bold in this
  -- theme. Same cells, different attribute, so only the attribute moves.
  LspReferenceText = { underline = true },
  LspReferenceRead = { underline = true },
  LspReferenceWrite = { underline = true },
}

local function apply_links()
  for group, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, group, type(spec) == "string" and { link = spec } or spec)
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("jry_highlight_parity", { clear = true }),
  callback = apply_links,
})
apply_links()

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
