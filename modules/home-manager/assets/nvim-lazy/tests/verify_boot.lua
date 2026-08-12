-- Assert a clean start: no spec errors, everything installed, nothing errored
-- while loading, and :checkhealth reports no ERROR for what we depend on.
local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")

h.settle()
h.load_all_plugins()

local Config = require("lazy.core.config")

for _, notif in ipairs(Config.spec.notifs or {}) do
  h.check(notif.level ~= vim.log.levels.ERROR, "plugin spec error", tostring(notif.msg))
end

for name, plugin in pairs(Config.plugins) do
  if not plugin.dir:find(vim.fn.stdpath("config"), 1, true) then
    h.check(plugin._.installed ~= false, "plugin not installed: " .. name)
  end
end

-- A plugin whose config function throws reports it through :messages. Scrape
-- rather than wrapping vim.notify: LazyVim queues notifications through its own
-- wrapper, and re-entering it from a hook overflows that queue.
local messages = vim.api.nvim_exec2("messages", { output = true }).output or ""
for line in messages:gmatch("[^\n]+") do
  if line:match("^E%d+:") or line:match("[Ee]rror executing") or line:match("^Error ") then
    h.check(false, "error during startup", vim.trim(line))
  end
end

-- checkhealth renders into a scratch buffer; scrape it for ERROR lines.
for _, target in ipairs({ "lazy", "vim.lsp", "vim.treesitter" }) do
  local ok, err = pcall(vim.cmd, "checkhealth " .. target)
  if h.check(ok, "checkhealth " .. target .. " ran", not ok and tostring(err) or nil) then
    local bad = {}
    for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
      if line:match("^%s*-?%s*ERROR") then
        table.insert(bad, string.format("%d: %s", i, vim.trim(line)))
      end
    end
    h.check(#bad == 0, "checkhealth " .. target .. " has no ERROR", table.concat(bad, "\n      "))
    pcall(vim.cmd, "bwipeout!")
  end
end

h.finish("boot")
