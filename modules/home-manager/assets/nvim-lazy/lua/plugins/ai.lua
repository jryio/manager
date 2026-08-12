-- avante.nvim, carried over from lvim's plugin list.
--
-- Deliberately a near-verbatim port, deprecations and all: this migration is
-- meant to preserve behaviour, and three separate things here want deciding
-- rather than quietly changing. See NOTES.md.
--   * the model is claude-3-5-sonnet-20241022
--   * the 1Password vault in api_key_name no longer exists
--   * `claude = { ... }` moved under `providers.claude` in newer avante
local function is_mac_volume()
  return string.match(vim.fn.getcwd(), "^/Volumes/") ~= nil
end

return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    -- Skips itself on external volumes, where the native library load is slow.
    cond = function()
      return not is_mac_volume()
    end,
    version = false,
    build = "make BUILD_FROM_SOURCE=true",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "echasnovski/mini.icons",
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = { insert_mode = true },
          },
        },
      },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = { file_types = { "markdown", "Avante" } },
        ft = { "markdown", "Avante" },
      },
    },
    config = function()
      -- Forces the native libraries to reload; see avante.nvim#612.
      require("avante_lib").load()
      require("avante").setup({
        provider = "claude",
        claude = {
          api_key_name = {
            "op",
            "item",
            "get",
            "2oxvera3ak3no5b2usvciuwnim",
            "--vault",
            "ifpq6udm2wag2mo3ipcoiu666e",
            "--fields",
            "credential",
            "--reveal",
          },
          endpoint = "https://api.anthropic.com",
          model = "claude-3-5-sonnet-20241022",
          temperature = 0,
          max_tokens = 4096,
        },
        behaviour = {
          auto_suggestions = false,
          auto_set_highlight_group = true,
          auto_set_keymaps = true,
          auto_apply_diff_after_generation = false,
          support_paste_from_clipboard = false,
          minimize_diff = true,
        },
        hints = { enabled = true },
        windows = {
          position = "right",
          wrap = true,
          width = 30,
          sidebar_header = { enabled = true, align = "center", rounded = true },
          input = { prefix = "> ", height = 8 },
          edit = { border = "rounded", start_insert = true },
          ask = {
            floating = false,
            start_insert = true,
            border = "rounded",
            focus_on_apply = "ours",
          },
        },
        mappings = {
          diff = {
            ours = "co",
            theirs = "ct",
            all_theirs = "ca",
            both = "cb",
            cursor = "cc",
            next = "<C-n>",
            prev = "<C-p>",
          },
          suggestion = {
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
          jump = { next = "]]", prev = "[[" },
          submit = { normal = "<CR>", insert = "<C-s>" },
          sidebar = {
            apply_all = "A",
            apply_cursor = "a",
            switch_windows = "<Tab>",
            reverse_switch_windows = "<S-Tab>",
          },
        },
        highlights = {
          diff = { current = "DiffText", incoming = "DiffAdd" },
        },
        diff = {
          autojump = true,
          list_opener = "copen",
          -- Keeps the c-prefixed diff mappings from waiting on operator-pending.
          override_timeoutlen = 500,
        },
      })
    end,
    -- avante's own auto_set_keymaps already owns <leader>aa (ask), <leader>at
    -- (toggle) and visual <leader>ae (edit), and wins over a spec entry -- which
    -- is exactly what happens in lvim today, where his which-key entries for
    -- them never took effect either. Only the keys avante does not claim are
    -- bound here.
    keys = {
      { "<leader>ak", "<cmd>AvanteClear<cr>", desc = "Clear" },
      {
        "<leader>ap",
        function()
          vim.ui.input({ prompt = "Provider: " }, function(input)
            if input then
              vim.cmd("AvanteSwitchProvider " .. input)
            end
          end)
        end,
        desc = "Provider",
      },
    },
  },
}
