-- Editing primitives: autopairs, structural edits, formatters, Markdown math snippets, and optional training.

-- clang-format covers the C family plus Java, JavaScript, TypeScript and Protobuf.
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

  -- Autopairs: an opener inserts its partner, <BS> deletes the whole pair, and
  -- <CR> inside an empty pair opens an indented block. Pressing <CR> is wired in
  -- config/keymaps.lua, which owns the completion-confirm branch.
  {
    "nvim-mini/mini.pairs",
    version = "*",
    opts = {},
  },

  -- External formatter backed by the system `clang-format` binary. The plugin
  -- resolves style in two steps: a `.clang-format` / `_clang-format` found from
  -- the file's directory upward is passed as `-style=file`; with no style file it
  -- falls back to `-style={BasedOnStyle: google, IndentWidth: <shiftwidth>}`.
  {
    "rhysd/vim-clang-format",
    ft = clang_format_filetypes,
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_clang_format", { clear = true }),
        pattern = clang_format_filetypes,
        callback = function(args)
          vim.keymap.set({ "n", "v" }, "<leader>cF", "<cmd>ClangFormat<CR>", {
            buffer = args.buf,
            desc = "clang-format 格式化",
          })
        end,
      })
    end,
  },

  -- Continuous persistence: a power loss must not cost more than one debounce window.
  {
    "okuuva/auto-save.nvim",
    version = "^1.0.0",
    event = { "InsertLeave", "TextChanged" },
    opts = {},
  },

  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
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

  {
    "ThePrimeagen/vim-be-good",
    cmd = "VimBeGood",
  },
}
