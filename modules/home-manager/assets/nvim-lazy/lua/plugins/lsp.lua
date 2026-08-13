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

      -- Diagnostics as lvim draws them, read out of its running
      -- `vim.diagnostic.config()` rather than its source:
      --   * virtual text is left at nvim's default (`true`), so a message reads
      --     "■■ Unexpected <exp>". LazyVim prefixes ● and appends the server
      --     name when several report, giving "●● Lua Syntax Check.: Unexpected".
      --   * the gutter glyphs are codicons, and lvim also passes each sign as
      --     `numhl`, which is what tints the line number of a diagnostic line.
      --   * the hover float is bordered and always names its source.
      opts.diagnostics = vim.tbl_deep_extend("force", opts.diagnostics or {}, {
        virtual_text = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "\u{ea87}",
            [vim.diagnostic.severity.WARN] = "\u{ea6c}",
            [vim.diagnostic.severity.INFO] = "\u{ea74}",
            [vim.diagnostic.severity.HINT] = "\u{f0336}",
          },
          numhl = {
            [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
            [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
            [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
            [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
          },
        },
        float = {
          border = "rounded",
          focusable = true,
          header = "",
          prefix = "",
          source = "always",
          style = "minimal",
        },
      })

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
