-- Treesitter parsers, the LSP group, and lvim's deno gating.
-- Language servers themselves come from the LazyVim lang extras in lazyvim.json.

--- lvim keys the deno decision off `deno.imports.json`, not the conventional
--- deno.json. That is his own marker, and the plan says to port it, not fix it.
local function deno_root()
  return vim.fs.root(vim.uv.cwd() or vim.fn.getcwd(), { "deno.imports.json" })
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "comment", -- so TODO and friends highlight inside comments
        "cpp",
        "css",
        "go",
        "java",
        "javascript",
        "json",
        "lua",
        "python",
        "rust",
        "typescript",
        "yaml",
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      local root = deno_root()
      opts.servers.denols = {
        enabled = root ~= nil,
        root_dir = root and function(_, on_dir)
          on_dir(root)
        end or nil,
        init_options = {
          enable = true,
          lint = true,
          unstable = false,
          importMap = "./deno.imports.json",
          config = "./deno.config.jsonc",
          cache = "./.deno",
          suggest = {
            imports = {
              hosts = { ["https://deno.land/"] = true },
            },
          },
        },
      }

      -- One TypeScript server per project. lvim disabled tsserver outright to
      -- get deno working; here vtsls only stands down inside a deno root.
      if root then
        opts.servers.vtsls = vim.tbl_deep_extend("force", opts.servers.vtsls or {}, { enabled = false })
      end

      return opts
    end,
  },

  -- lvim's LSP group. LazyVim's own <leader>c group stays.
  {
    "neovim/nvim-lspconfig",
    keys = {
      { "<leader>la", vim.lsp.buf.code_action, desc = "Code Action" },
      {
        "<leader>lj",
        function()
          vim.diagnostic.jump({ count = 1, float = true })
        end,
        desc = "Next Diagnostic",
      },
      {
        "<leader>lk",
        function()
          vim.diagnostic.jump({ count = -1, float = true })
        end,
        desc = "Prev Diagnostic",
      },
      { "<leader>lr", vim.lsp.buf.rename, desc = "Rename" },
      {
        "<leader>lf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        desc = "Format",
      },
      { "<leader>ld", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics" },
      { "<leader>li", "<cmd>checkhealth vim.lsp<cr>", desc = "Info" },
    },
  },
}
