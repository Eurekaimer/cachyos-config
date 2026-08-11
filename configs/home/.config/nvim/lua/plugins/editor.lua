return {
  -- nvim-treesitter v1 installs parsers explicitly and starts highlighting per filetype.
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
    config = function()
      require("nvim-treesitter").setup()
      require("nvim-treesitter").install({
        "bash",
        "go",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "rust",
        "toml",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      })
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },

  {
    "nvim-mini/mini.comment",
    version = "*",
    opts = {},
  },

  {
    "nvim-mini/mini.surround",
    version = "*",
    opts = {},
  },

  {
    "ThePrimeagen/vim-be-good",
    cmd = "VimBeGood",
  },
}
