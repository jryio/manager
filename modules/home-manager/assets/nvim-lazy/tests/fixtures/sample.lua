-- Fixture for buffer-local option and formatting checks.
-- This comment block is deliberately longer than eighty columns so that gq and textwidth behaviour can be exercised against it by the format tests.
local M = {}

function M.hello(name)
  return "hello " .. name
end

return M
