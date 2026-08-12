-- Formatting and linting, ported from lvim's null-ls setup.
-- Format-on-save is a LazyVim default, which is what lvim had too.
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        -- blackd-client talks to a running blackd, which is why lvim used it
        -- over black: no interpreter start-up per format.
        ["blackd-client"] = {
          command = "blackd-client",
          stdin = true,
        },
      },
      formatters_by_ft = {
        python = { "blackd-client" },
      },
    },
  },

  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        markdown = { "vale" },
      },
    },
  },

  -- lvim sets lsp.buffer_options.formatexpr = "" so that gq reflows comments
  -- with textwidth and formatoptions instead of asking the language server.
  -- Neovim installs its own formatexpr on attach, and LazyVim installs one over
  -- that, so clearing it needs to happen after both.
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("jry_gq_formatexpr", { clear = true }),
        callback = function(event)
          vim.bo[event.buf].formatexpr = ""
        end,
      })
    end,
  },
}
