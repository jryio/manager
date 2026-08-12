-- Assert formatter wiring: blackd-client for python via conform, and that gq
-- reflows comments using textwidth rather than an LSP formatexpr.
-- Populated in phase 6, alongside the conform and lint specs.
local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")
h.require_phase(6, "format")

h.settle()
h.load_all_plugins()

h.check(false, "verify_format.lua is not implemented yet")
h.finish("format")
