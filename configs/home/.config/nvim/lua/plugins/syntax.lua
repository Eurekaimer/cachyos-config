-- Syntax parsers and delimiter highlighting are centralized here because Markdown rendering and image discovery reuse them.
return {
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
        "c",
        "cpp",
        "go",
        "java",
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

  -- Tree-sitter powered rainbow delimiters: every nesting level gets its own
  -- colour so deep bracket nests stay distinguishable. This only loads the
  -- highlighter; the seven RainbowDelimiter* groups are defined in theme.lua, and
  -- the plugin's default order already maximises adjacent-level contrast.
  {
    "HiPhish/rainbow-delimiters.nvim",
    lazy = false,
  },
}
