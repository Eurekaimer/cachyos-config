return {
  -- Treesitter is the only syntax plugin; Neovim provides the highlighter itself.
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

  -- Surround editing has no equivalent in core Neovim and saves repeated edits.
  {
    "nvim-mini/mini.surround",
    version = "*",
    opts = {},
  },

  -- This command-only training plugin never loads during normal editing.
  {
    "ThePrimeagen/vim-be-good",
    cmd = "VimBeGood",
  },
}
