-- Assert the keymap manifest against the live config.
local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")
local manifest = dofile(vim.fn.stdpath("config") .. "/tests/keymap_manifest.lua")

h.settle()
h.load_all_plugins()

--- maparg() does not expand <leader>, so do it ourselves.
local function resolve(lhs)
  local leader = vim.g.mapleader or "\\"
  return (lhs:gsub("^<[lL]eader>", leader == " " and " " or leader))
end

local phase = h.phase()

for _, e in ipairs(manifest) do
  if (e.phase or 0) <= phase then
    local lhs = resolve(e.lhs)
    local label = string.format("[p%s] %s %s", tostring(e.phase or 0), e.mode, e.lhs)
    local m = vim.fn.maparg(lhs, e.mode, false, true)
    local mapped = type(m) == "table" and not vim.tbl_isempty(m)

    if e.absent then
      h.check(not mapped, label .. " should be unmapped", mapped and ("still mapped to: " .. vim.inspect(m.rhs or m.desc)) or nil)
    elseif not h.check(mapped, label .. " is not mapped at all") then
      -- nothing further to compare
    elseif e.rhs then
      h.eq(m.rhs, e.rhs, label .. " rhs")
    elseif e.desc then
      h.eq(m.desc, e.desc, label .. " desc")
    elseif e.has then
      local rhs = m.rhs or ""
      h.check(rhs:find(e.has, 1, true) ~= nil, label .. " rhs substring", string.format("want substring: %s\n      got rhs:        %s", e.has, rhs))
    end
  end
end

h.finish(string.format("keymaps (phase <= %s)", phase == math.huge and "all" or phase))
