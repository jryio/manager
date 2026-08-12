-- Shared harness utilities.
--
-- Run tests as `nvim --headless -c "luafile tests/<t>.lua" -c qa`, NOT `nvim -l`:
-- `-l` skips the user config entirely, which would make every assertion vacuous.
local M = {}

local failures = {}
local checks = 0

function M.check(ok, label, detail)
  checks = checks + 1
  if not ok then
    table.insert(failures, detail and (label .. "\n      " .. detail) or label)
  end
  return ok
end

function M.eq(actual, expected, label)
  local same = vim.deep_equal(actual, expected)
  return M.check(same, label, not same and string.format("want: %s\n      got:  %s", vim.inspect(expected), vim.inspect(actual)))
end

--- Fire VeryLazy and drain the scheduler.
--- LazyVim loads its keymaps and autocmds on the VeryLazy event, which never
--- arrives in a headless session, so we raise it ourselves.
function M.settle()
  pcall(vim.api.nvim_exec_autocmds, "User", { pattern = "VeryLazy", modeline = false })
  vim.wait(200, function() return false end)
end

--- Force every lazy.nvim plugin to load.
--- `keys=` specs create placeholder mappings at startup, but which-key group
--- names and plugin-internal (often buffer-local) maps only exist post-load.
function M.load_all_plugins()
  local ok, Config = pcall(require, "lazy.core.config")
  if not ok then
    return M.check(false, "lazy.core.config is unavailable")
  end
  local names = vim.tbl_keys(Config.plugins)
  local loaded, err = pcall(function()
    require("lazy").load({ plugins = names, wait = true })
  end)
  if not loaded then
    -- One bad plugin shouldn't mask the rest; retry individually.
    for _, name in ipairs(names) do
      pcall(function() require("lazy").load({ plugins = { name }, wait = true }) end)
    end
    vim.notify("load_all_plugins: bulk load failed, fell back to per-plugin: " .. tostring(err), vim.log.levels.WARN)
  end
  vim.wait(500, function() return false end)
  return true
end

function M.phase()
  return tonumber(vim.env.NVIM_TEST_PHASE) or math.huge
end

--- Exit cleanly when the phase that introduces this test hasn't landed yet, so
--- `task test` is green at every phase without pretending the check ran.
function M.require_phase(n, name)
  if M.phase() < n then
    io.stdout:write(string.format("\nHARNESS skip %s (arrives in phase %d)\n", name, n))
    vim.cmd("qa!")
  end
end

function M.finish(name)
  if #failures == 0 then
    io.stdout:write(string.format("\nHARNESS ok   %s (%d checks)\n", name, checks))
    vim.cmd("qa!")
    return
  end
  io.stdout:write(string.format("\nHARNESS FAIL %s (%d checks, %d failed)\n", name, checks, #failures))
  for _, f in ipairs(failures) do
    io.stdout:write("  - " .. f .. "\n")
  end
  -- `cq` is the only reliable way to set a nonzero exit from a -c script.
  vim.cmd("cq!")
end

return M
