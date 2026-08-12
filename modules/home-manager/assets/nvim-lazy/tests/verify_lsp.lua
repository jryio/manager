-- Assert the right language server is configured, and would attach, per
-- language fixture -- including lvim's deno gating.
--
-- Configuration is asserted unconditionally. Attachment is only asserted when
-- the server's executable is actually present, so the suite stays useful on a
-- machine where Mason has not downloaded half a gigabyte of servers yet.
local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")
h.require_phase(6, "lsp")

h.settle()
h.load_all_plugins()

local fixtures = vim.fn.stdpath("config") .. "/tests/fixtures"

--- LazyVim merges server specs into the nvim-lspconfig spec's opts.
local function configured_servers()
  local spec = require("lazy.core.config").plugins["nvim-lspconfig"]
  local opts = require("lazy.core.plugin").values(spec, "opts", false)
  return opts.servers or {}
end

local servers = configured_servers()

local function enabled(name)
  local s = servers[name]
  return s ~= nil and s.enabled ~= false
end

-- One entry per lang extra in lazyvim.json. `pyright` rather than
-- `basedpyright`: LazyVim configures both and enables pyright unless
-- vim.g.lazyvim_python_lsp says otherwise. Rust is absent on purpose -- the rust
-- extra drives rust_analyzer through rustaceanvim, so the server spec is off.
for _, case in ipairs({
  { file = "sample.go", server = "gopls" },
  { file = "sample.py", server = "pyright" },
  { file = "sample.py", server = "ruff" },
  { file = "sample.ts", server = "vtsls" },
  { file = "sample.lua", server = "lua_ls" },
  { file = "sample.md", server = "jsonls" },
  { file = "sample.md", server = "yamlls" },
}) do
  h.check(enabled(case.server), string.format("%s is configured and enabled", case.server))
end

h.check(require("lazy.core.config").plugins["rustaceanvim"] ~= nil, "the rust extra brought rustaceanvim")

-- The deno gate. Outside a deno root, denols stands down and vtsls handles
-- TypeScript; inside one, they swap. cwd decides, as it does in lvim, so this
-- process can only observe one side -- assert whichever side it is in.
local in_deno_root = vim.fs.root(vim.uv.cwd() or vim.fn.getcwd(), { "deno.imports.json" }) ~= nil
if in_deno_root then
  h.check(enabled("denols"), "inside a deno root, denols is enabled")
  h.check(not enabled("vtsls"), "inside a deno root, vtsls stands down")
  local init = (servers.denols or {}).init_options or {}
  h.eq(init.importMap, "./deno.imports.json", "denols importMap")
  h.eq(init.config, "./deno.config.jsonc", "denols config")
  h.eq(init.cache, "./.deno", "denols cache")
  h.eq(init.lint, true, "denols lint")
  h.eq((((init.suggest or {}).imports or {}).hosts or {})["https://deno.land/"], true, "denols suggest host")
else
  h.check(not enabled("denols"), "outside a deno root, denols stands down")
  h.check(enabled("vtsls"), "outside a deno root, vtsls handles TypeScript")
end

--- Open a fixture and wait for any client to attach.
local function attaches(file, server)
  vim.cmd.edit(fixtures .. "/" .. file)
  local buf = vim.api.nvim_get_current_buf()
  vim.wait(8000, function()
    return #vim.lsp.get_clients({ bufnr = buf, name = server }) > 0
  end, 100)
  return #vim.lsp.get_clients({ bufnr = buf, name = server }) > 0
end

for _, case in ipairs({
  { file = "sample.go", server = "gopls", exe = "gopls" },
  { file = "sample.lua", server = "lua_ls", exe = "lua-language-server" },
}) do
  if vim.fn.executable(case.exe) == 1 then
    h.check(attaches(case.file, case.server), case.server .. " attaches to " .. case.file)
  else
    io.stdout:write(string.format("     (skipped %s attach: %s not installed)\n", case.server, case.exe))
  end
end

h.finish("lsp")
