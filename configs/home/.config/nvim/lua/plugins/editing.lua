-- Editing primitives: structural edits, Markdown math snippets, and optional training.
return {
  {
    "nvim-mini/mini.surround",
    version = "*",
    opts = {},
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
