-- The 1:1 keybinding contract, ported from assets/lvim/config.lua and the
-- legacy comma-leader assets/nvim/init.vim.
--
-- Entry fields:
--   mode    single-mode string, as nvim_get_keymap uses it
--   lhs     a leading "<leader>" is expanded to vim.g.mapleader by the verifier
--   rhs     exact right-hand side
--   desc    exact description (use for callback maps, which have no rhs)
--   has     substring of the rhs (for long or escape-heavy right-hand sides)
--   absent  true when the key must be unmapped (a deleted LazyVim default)
--   phase   the phase that introduces it; the verifier skips later phases
--
-- Prefer `desc`/`has` over `rhs` when asserting a LazyVim default we keep, so
-- upstream rewording of an implementation doesn't fail the suite.
return {
  -- ---------------------------------------------------------------- phase 0
  -- LazyVim defaults the plan keeps as-is; here to prove the verifier runs and
  -- to catch upstream regressions on bindings Jacob relies on.
  { mode = "n", lhs = "j", desc = "Down", phase = 0 },
  { mode = "n", lhs = "k", desc = "Up", phase = 0 },
  { mode = "x", lhs = ">", rhs = ">gv", phase = 0 },
  { mode = "n", lhs = "[q", desc = "Previous Trouble/Quickfix Item", phase = 0 },
  { mode = "n", lhs = "]q", desc = "Next Trouble/Quickfix Item", phase = 0 },
}
