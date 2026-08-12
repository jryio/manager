-- Exercise the bindings where "mapped to the right string" and "does the right
-- thing" can differ: recursive maps that depend on another mapping existing,
-- and maps whose effect is a buffer edit rather than a motion.
local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")

h.settle()
h.load_all_plugins()

--- Run keys against a scratch buffer and return the resulting lines.
local function press(lines, keys, filetype)
  vim.cmd("enew!")
  vim.bo.filetype = filetype or "lua"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.api.nvim_feedkeys(vim.keycode(keys), "mtx", false)
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "mtx", false)
  local out = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  vim.bo.modified = false
  return out
end

local cases = {
  {
    phase = 2,
    name = "<leader>/ comments a line",
    -- Recursive onto gcc: if built-in commenting ever moves, this goes quiet
    -- rather than erroring, so assert the edit itself.
    lines = { "local x = 1" },
    keys = "<Space>/",
    want = { "-- local x = 1" },
  },
  {
    phase = 2,
    name = "<leader>/ uncomments a line",
    lines = { "-- local x = 1" },
    keys = "<Space>/",
    want = { "local x = 1" },
  },
  {
    phase = 2,
    name = "S splits a line at the cursor, without reindenting",
    -- lvim splits to "abc" / "def" here. Treesitter indent would make it
    -- "abc" / "  def", which is why lua/plugins/parity.lua turns it off.
    lines = { "abcdef" },
    keys = "lllS",
    want = { "abc", "def" },
  },
  {
    phase = 2,
    name = "J joins without moving the cursor",
    lines = { "one", "two" },
    keys = "J",
    want = { "one two" },
  },
  {
    phase = 2,
    name = "c does not clobber the unnamed register",
    -- yank "one", change "two" with cw, then paste: "one" must survive.
    lines = { "one", "two" },
    keys = "yiwjcwxxx<Esc>p",
    want = { "one", "xxxone" },
  },
  {
    phase = 2,
    name = "dw stops at the end of the last word",
    lines = { "alpha beta" },
    keys = "wdw",
    want = { "alpha " },
  },
  {
    phase = 2,
    name = "<Tab> jumps to the matching bracket",
    lines = { "if (a) then", "end" },
    -- Move onto "(", jump to ")", then delete to prove where the cursor landed.
    keys = "f(<Tab>x",
    want = { "if (a then", "end" },
  },
  {
    phase = 2,
    name = "visual < keeps the selection",
    lines = { "    a", "    b" },
    keys = "Vj<<",
    want = { "a", "b" },
  },
}

for _, c in ipairs(cases) do
  if (c.phase or 0) <= h.phase() then
    local ok, got = pcall(press, c.lines, c.keys, c.filetype)
    if h.check(ok, c.name .. " ran", not ok and tostring(got) or nil) then
      h.eq(got, c.want, c.name)
    end
  end
end

h.finish(string.format("behaviour (phase <= %s)", h.phase() == math.huge and "all" or h.phase()))
