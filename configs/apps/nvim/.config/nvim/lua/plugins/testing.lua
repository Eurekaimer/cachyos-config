-- Test runners only: no DAP, automatic runs or extra language tooling.
return {
  {
    "nvim-neotest/neotest",
    cmd = "NeotestJava",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "rcasia/neotest-java",
      "nvim-neotest/neotest-python",
      "fredrikaverpil/neotest-golang",
      "rouge8/neotest-rust",
    },
    keys = {
      {
        "<leader>Tn",
        function()
          require("neotest").run.run()
        end,
        desc = "运行最近测试",
      },
      {
        "<leader>Tf",
        function()
          require("neotest").run.run(vim.fn.expand("%:p"))
        end,
        desc = "运行当前文件测试",
      },
      {
        "<leader>Ta",
        function()
          require("neotest").run.run(vim.fn.getcwd())
        end,
        desc = "运行当前项目测试",
      },
      {
        "<leader>Tl",
        function()
          require("neotest").run.run_last()
        end,
        desc = "重新运行上次测试",
      },
      {
        "<leader>Ts",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "切换测试摘要",
      },
      {
        "<leader>To",
        function()
          require("neotest").output.open({ enter = true })
        end,
        desc = "查看测试输出",
      },
      {
        "<leader>Tp",
        function()
          require("neotest").output_panel.toggle()
        end,
        desc = "切换测试输出面板",
      },
      {
        "<leader>Tx",
        function()
          require("neotest").run.stop()
        end,
        desc = "停止最近测试",
      },
    },
    config = function()
      require("neotest").setup({
        adapters = {
          -- Open a Java buffer first; install the JUnit runner with :NeotestJava setup.
          require("neotest-java"),
          -- Upstream selects the project Python and falls back to unittest without pytest.
          require("neotest-python"),
          -- v2 supports the Go parser from nvim-treesitter main; uses go test by default.
          require("neotest-golang")({}),
          -- Requires cargo-nextest; ordinary test runs do not require nvim-dap.
          require("neotest-rust"),
        },
      })
    end,
  },
}
