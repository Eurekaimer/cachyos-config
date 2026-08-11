-- LSP servers are installed by Mason and enabled through Neovim 0.12's native API.
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
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = servers,
        automatic_enable = false,
      })

      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      for _, server in ipairs(servers) do
        local config = { capabilities = capabilities }
        if server == "lua_ls" then
          config.settings = {
            Lua = {
              diagnostics = { globals = { "vim", "Snacks" } },
              workspace = { checkThirdParty = false },
            },
          }
        end
        vim.lsp.config(server, config)
        vim.lsp.enable(server)
      end
    end,
  },

  -- Buffer-local LSP mappings avoid overriding Vim keys in plain text buffers.
  {
    "folke/snacks.nvim",
    init = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_keymaps", { clear = true }),
        callback = function(args)
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
          end

          map("gd", function() Snacks.picker.lsp_definitions() end, "跳转到定义")
          map("gD", function() Snacks.picker.lsp_declarations() end, "跳转到声明")
          map("gr", function() Snacks.picker.lsp_references() end, "查看引用")
          map("gI", function() Snacks.picker.lsp_implementations() end, "跳转到实现")
          map("gy", function() Snacks.picker.lsp_type_definitions() end, "跳转到类型定义")
          map("K", vim.lsp.buf.hover, "悬停文档")
          map("<leader>ca", vim.lsp.buf.code_action, "代码操作")
          map("<leader>cr", vim.lsp.buf.rename, "重命名符号")
          map("<leader>cf", function()
            vim.lsp.buf.format({ async = true })
          end, "格式化文件")
          map("<leader>cd", vim.diagnostic.open_float, "当前诊断")
          map("[d", function()
            vim.diagnostic.jump({ count = -1, float = true })
          end, "上一个诊断")
          map("]d", function()
            vim.diagnostic.jump({ count = 1, float = true })
          end, "下一个诊断")
        end,
      })
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }, {
          { name = "buffer" },
        }),
      })
    end,
  },

  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
  },
}
