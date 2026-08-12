-- Assert editor options against the live config.
--
-- Assertions run with a real file open, because textwidth and formatoptions are
-- buffer-local and filetype plugins get a say in them; checking only the global
-- value would pass while typing still behaved wrongly.
local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")

h.settle()
vim.cmd.edit(vim.fn.stdpath("config") .. "/tests/fixtures/sample.lua")
vim.wait(200, function() return false end)

local specs = {
  -- phase 0: LazyVim defaults, proving the check runs against a loaded config
  { phase = 0, opt = "expandtab", want = true },
  { phase = 0, opt = "shiftwidth", want = 2 },
  { phase = 0, opt = "undofile", want = true },
}

for _, s in ipairs(specs) do
  if (s.phase or 0) <= h.phase() then
    local label = string.format("[p%s] %s", tostring(s.phase or 0), s.opt)
    local actual = vim.opt_local[s.opt]:get()

    if s.want ~= nil then
      h.eq(actual, s.want, label)
    elseif s.chars then
      -- order-insensitive: formatoptions is a set, not a sequence
      local missing, extra = {}, {}
      for c in s.chars:gmatch(".") do
        if not actual:find(c, 1, true) then table.insert(missing, c) end
      end
      for c in tostring(actual):gmatch(".") do
        if not s.chars:find(c, 1, true) then table.insert(extra, c) end
      end
      h.check(#missing == 0 and #extra == 0, label, string.format("want set: %s\n      got:      %s (missing %s, extra %s)", s.chars, actual, table.concat(missing), table.concat(extra)))
    elseif s.parts then
      for _, part in ipairs(s.parts) do
        local found = false
        for _, item in ipairs(type(actual) == "table" and vim.tbl_keys(actual) or {}) do
          if part:find(item, 1, true) == 1 then found = true end
        end
        -- listchars comes back as a key/value table; compare on the raw string too
        local raw = vim.api.nvim_get_option_value("listchars", { scope = "local" })
        h.check(found or raw:find(part, 1, true) ~= nil, label .. " contains " .. part, "got: " .. raw)
      end
    elseif s.has then
      h.check(tostring(actual):find(s.has, 1, true) ~= nil, label .. " contains " .. s.has, "got: " .. tostring(actual))
    end
  end
end

h.finish(string.format("options (phase <= %s)", h.phase() == math.huge and "all" or h.phase()))
