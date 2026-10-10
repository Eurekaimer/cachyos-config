-- Editing primitives, explicit formatting, and Markdown math snippets.
local clang_format_filetypes = {
  "c",
  "cpp",
  "objc",
  "java",
  "javascript",
  "typescript",
  "proto",
  "cuda",
  "vala",
}

return {
  {
    "nvim-mini/mini.surround",
    version = "*",
    opts = {},
  },

  -- Completion-aware <CR> handling lives in config/keymaps.lua.
  {
    "nvim-mini/mini.pairs",
    version = "*",
    opts = {},
  },

  {
    "stevearc/conform.nvim",
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cF",
        function()
          require("conform").format({ async = true })
        end,
        mode = { "n", "x" },
        desc = "格式化文件/选区",
      },
    },
    opts = function()
      local formatters_by_ft = {
        python = { "black" },
        go = { "gofmt" },
        rust = { "rustfmt" },
        lua = { "stylua" },
      }
      for _, ft in ipairs(clang_format_filetypes) do
        formatters_by_ft[ft] = { "clang-format" }
      end
      return {
        formatters_by_ft = formatters_by_ft,
        formatters = {
          ["clang-format"] = {
            -- Project style wins; only unconfigured files use Google + buffer indent.
            prepend_args = function(_, ctx)
              local style_file = vim.fs.find({ ".clang-format", "_clang-format" }, {
                path = vim.fs.dirname(ctx.filename),
                upward = true,
                type = "file",
              })[1]
              if style_file then
                return { "-style=file" }
              end
              local width = vim.api.nvim_buf_call(ctx.buf, vim.fn.shiftwidth)
              return { string.format("-style={BasedOnStyle: Google, IndentWidth: %d}", width) }
            end,
          },
        },
      }
    end,
  },

  -- Persist edits independently of formatting.
  {
    "okuuva/auto-save.nvim",
    version = "^1.0.0",
    event = { "InsertLeave", "TextChanged" },
    opts = {},
  },

  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    -- LuaSnip uses repeat#set to repeat expansions with ".".
    dependencies = { "tpope/vim-repeat" },
    ft = "markdown",
    config = function()
      local luasnip = require("luasnip")
      luasnip.config.setup({
        enable_autosnippets = true,
        region_check_events = "CursorMoved,CursorHold,InsertEnter",
        delete_check_events = "TextChanged,TextChangedI",
      })
      require("luasnip.loaders.from_lua").lazy_load({
        paths = { vim.fn.stdpath("config") .. "/lua/snippets" },
      })
    end,
  },
}
