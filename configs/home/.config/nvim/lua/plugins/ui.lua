return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = { style = "storm" },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- Snacks provides the LazyVim-style dashboard, explorer, picker, and utility UI.
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      bigfile = { enabled = true },
      dashboard = { enabled = true },
      explorer = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true, timeout = 3000 },
      picker = { enabled = true },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
    },
    keys = {
      { "<leader><space>", function() Snacks.picker.smart() end, desc = "智能查找" },
      { "<leader>e", function() Snacks.explorer() end, desc = "文件树" },
      { "<leader>ff", function() Snacks.picker.files() end, desc = "查找文件" },
      { "<leader>fg", function() Snacks.picker.grep() end, desc = "全文搜索" },
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "切换文件" },
      { "<leader>fr", function() Snacks.picker.recent() end, desc = "最近文件" },
      { "<leader>fh", function() Snacks.picker.help() end, desc = "查找帮助" },
      { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "全部诊断" },
      { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "查找快捷键" },
      { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "文档符号" },
      { "<leader>gg", function() Snacks.lazygit() end, desc = "LazyGit" },
      { "<leader>bd", function() Snacks.bufdelete() end, desc = "关闭文件" },
      { "<leader>z", function() Snacks.zen() end, desc = "专注模式" },
      { "<leader>n", function() Snacks.notifier.show_history() end, desc = "通知历史" },
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = { delay = 300, preset = "modern" },
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { options = { theme = "auto", globalstatus = true } },
  },
}
