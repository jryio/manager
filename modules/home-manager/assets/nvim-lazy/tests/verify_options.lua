-- Assert editor options against the live config.
--
-- Assertions run with a real file open, because textwidth and formatoptions are
-- buffer-local and filetype plugins get a say in them; checking only the global
-- value would pass while typing still behaved wrongly.
local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")

h.settle()
vim.cmd.edit(vim.fn.stdpath("config") .. "/tests/fixtures/sample.lua")
vim.wait(200, function() return false end)

--- vim.opt:get() returns one of three shapes. Flatten all of them to a string:
--- a list for comma-separated options, a flag set with boolean values for
--- formatoptions, and a key/value map for listchars and friends.
local function norm(value)
  if type(value) ~= "table" then
    return value
  end
  if vim.islist(value) then
    return table.concat(value, ",")
  end
  local keys = vim.tbl_keys(value)
  table.sort(keys)
  local flags = not vim.iter(keys):any(function(k)
    return type(value[k]) == "string"
  end)
  if flags then
    return table.concat(keys)
  end
  return table.concat(
    vim.tbl_map(function(k)
      return k .. ":" .. tostring(value[k])
    end, keys),
    ","
  )
end

local specs = {
  -- phase 0: LazyVim defaults, proving the check runs against a loaded config
  { phase = 0, opt = "expandtab", want = true },
  { phase = 0, opt = "shiftwidth", want = 2 },
  { phase = 0, opt = "undofile", want = true },

  -- phase 1: parity with assets/lvim/config.lua
  { phase = 1, opt = "textwidth", want = 80 },
  { phase = 1, opt = "timeoutlen", want = 500 },
  { phase = 1, opt = "mouse", want = "" },
  { phase = 1, opt = "cursorlineopt", want = "number" },
  { phase = 1, opt = "list", want = true },
  { phase = 1, opt = "foldmethod", want = "manual" },
  { phase = 1, opt = "listchars", parts = { "eol:¬", "extends:❯", "precedes:❮", "trail:·", "nbsp:·", "tab:" } },
  { phase = 1, opt = "spellfile", has = "spell/dictionary.utf-8.add" },
  -- `foldexpr` is asserted globally only. Buffer-locally, nvim's own
  -- ftplugin/lua.lua installs v:lua.vim.treesitter.foldexpr() -- lvim lands on
  -- exactly the same value, and with foldmethod=manual it is inert anyway.
  { phase = 1, global = "foldexpr", want = "" },
  -- The set lvim reaches in a Lua buffer: ftplugin/lua.vim drops `t`, adds `o`.
  -- Asserting the global set here would claim behaviour he has never had.
  { phase = 1, opt = "formatoptions", chars = "vjncroql" },
  { phase = 1, global = "formatoptions", chars = "qcrntjlv" },
}

for _, s in ipairs(specs) do
  if (s.phase or 0) <= h.phase() then
    local name = s.opt or s.global
    local label = string.format("[p%s] %s%s", tostring(s.phase or 0), name, s.global and " (global)" or "")
    local actual = norm(
      s.global and vim.api.nvim_get_option_value(name, { scope = "global" }) or vim.opt_local[name]:get()
    )

    if s.want ~= nil then
      h.eq(actual, s.want, label)
    elseif s.chars then
      -- order-insensitive: formatoptions is a set, not a sequence
      local missing, extra = {}, {}
      for c in s.chars:gmatch(".") do
        if not actual:find(c, 1, true) then
          table.insert(missing, c)
        end
      end
      for c in actual:gmatch(".") do
        if not s.chars:find(c, 1, true) then
          table.insert(extra, c)
        end
      end
      h.check(
        #missing == 0 and #extra == 0,
        label,
        string.format("want set: %s\n      got:      %s (missing %s, extra %s)", s.chars, actual, table.concat(missing), table.concat(extra))
      )
    elseif s.parts then
      for _, part in ipairs(s.parts) do
        h.check(actual:find(part, 1, true) ~= nil, label .. " contains " .. part, "got: " .. actual)
      end
    elseif s.has then
      h.check(actual:find(s.has, 1, true) ~= nil, label .. " contains " .. s.has, "got: " .. actual)
    end
  end
end

h.finish(string.format("options (phase <= %s)", h.phase() == math.huge and "all" or h.phase()))
