-- Mason installs servers; Neovim 0.12 provides LSP configuration and completion.
local servers = {
  "bashls",
  "gopls",
  "lua_ls",
  "pyright",
  "rust_analyzer",
  "ts_ls",
}

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "mason-org/mason-lspconfig.nvim",
    },
    init = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_keymaps", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
          end

          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = desc })
          end

          map("n", "gd", function() Snacks.picker.lsp_definitions() end, "跳转到定义")
          map("n", "gD", function() Snacks.picker.lsp_declarations() end, "跳转到声明")
          map("n", "gr", function() Snacks.picker.lsp_references() end, "查看引用")
          map("n", "gI", function() Snacks.picker.lsp_implementations() end, "跳转到实现")
          map("n", "gy", function() Snacks.picker.lsp_type_definitions() end, "跳转到类型定义")
          map("n", "K", vim.lsp.buf.hover, "悬停文档")
          map("n", "<leader>ca", vim.lsp.buf.code_action, "代码操作")
          map("n", "<leader>cr", vim.lsp.buf.rename, "重命名符号")
          map("n", "<leader>cf", function()
            vim.lsp.buf.format({ async = true })
          end, "格式化文件")
          map("n", "<leader>cd", vim.diagnostic.open_float, "当前诊断")
          map("n", "[d", function()
            vim.diagnostic.jump({ count = -1, float = true })
          end, "上一个诊断")
          map("n", "]d", function()
            vim.diagnostic.jump({ count = 1, float = true })
          end, "下一个诊断")
          map("i", "<C-Space>", vim.lsp.completion.get, "触发补全")
        end,
      })
    end,
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = servers,
        automatic_enable = false,
      })

      for _, server in ipairs(servers) do
        local config = {}
        if server == "lua_ls" then
          config.settings = {
            Lua = {
              diagnostics = { globals = { "vim", "Snacks" } },
              runtime = { version = "LuaJIT" },
              telemetry = { enable = false },
              workspace = {
                checkThirdParty = false,
                library = { vim.env.VIMRUNTIME },
              },
            },
          }
        end
        vim.lsp.config(server, config)
        vim.lsp.enable(server)
      end
    end,
  },
}
