return {
  -- Snacks replaces separate dashboard, explorer, picker, notifier, and terminal plugins.
  {
    "folke/snacks.nvim",
    priority = 900,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      dashboard = { enabled = true },
      explorer = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true, timeout = 3000 },
      picker = { enabled = true },
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },
      terminal = { enabled = true },
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
      -- Git work happens in a shell surfaced from the editor: one terminal rooted at
      -- the project, toggled from any buffer. Ctrl+/ is the usual alternative.
      { "<leader>tt", function() Snacks.terminal() end, desc = "终端" },
      { "<C-/>", function() Snacks.terminal() end, desc = "终端" },
      { "<leader>bd", function() Snacks.bufdelete() end, desc = "关闭文件" },
      { "<leader>z", function() Snacks.zen() end, desc = "专注模式" },
      { "<leader>n", function() Snacks.notifier.show_history() end, desc = "通知历史" },
    },
  },

  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialClose", "AerialInfo" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      { "<leader>a", "<cmd>AerialToggle<CR>", desc = "切换标题/代码大纲" },
    },
    opts = {
      layout = { default_direction = "right", min_width = 24 },
      -- Markdown folds include section contents; leave other filetypes' folds alone.
      manage_folds = { markdown = true, ["_"] = false },
      link_tree_to_folds = true,
      keymaps = {
        -- Preserve global save, window navigation, and end-of-line mappings.
        ["<C-s>"] = false,
        ["<C-j>"] = false,
        ["<C-k>"] = false,
        ["L"] = false,
        -- Keep native paragraph/section motions; j/k select, Enter jumps.
        ["{"] = false,
        ["}"] = false,
        ["[["] = false,
        ["]]"] = false,
      },
    },
  },

  -- which-key is retained for discoverability while learning modal editing.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 300,
      preset = "modern",
      spec = {
        { "<leader>b", group = "缓冲区" },
        { "<leader>c", group = "代码" },
        { "<leader>f", group = "查找" },
        { "<leader>g", group = "Git" },
        { "<leader>m", group = "Markdown" },
        { "<leader>s", group = "保存/搜索/诊断" },
        { "<leader>w", group = "窗口" },
      },
    },
  },

  -- Neovide already animates its cursor; use this text-cell approximation elsewhere.
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    cond = function()
      return not vim.g.neovide
    end,
    opts = {
      smear_between_buffers = true,
      smear_between_neighbor_lines = true,
      scroll_buffer_space = true,
      smear_insert_mode = true,
      stiffness = 0.8,
      trailing_stiffness = 0.6,
      stiffness_insert_mode = 0.7,
      trailing_stiffness_insert_mode = 0.7,
      damping = 0.95,
      damping_insert_mode = 0.95,
      distance_stop_animating = 0.5,
      legacy_computing_symbols_support = false,
    },
  },
}
