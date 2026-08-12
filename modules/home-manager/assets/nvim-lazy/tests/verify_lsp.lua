-- Assert the expected language server attaches for each fixture, including the
-- deno gating (denols, not vtsls, when a root has deno.imports.json).
-- Populated in phase 6, alongside the LSP specs themselves.
local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")
h.require_phase(6, "lsp")

h.settle()
h.load_all_plugins()

h.check(false, "verify_lsp.lua is not implemented yet")
h.finish("lsp")
