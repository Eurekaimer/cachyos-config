-- Mason installs servers; Neovim 0.12 provides LSP configuration and completion.
local servers = {
  "bashls",
  "gopls",
  "lua_ls",
  "pyright",
  "rust_analyzer",
  "ts_ls",
}

-- Mason installs these, but nvim-jdtls starts the Java server itself so that its
-- JDT-specific commands and code-action extensions are available (plugins/java.lua).
local plugin_managed_servers = { "jdtls" }

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "mason-org/mason-lspconfig.nvim",
    },
    init = function()
      -- Native autotrigger covers server punctuation, not ordinary typing or
      -- backspace after the menu loses all matches. Reopen from the edited text.
      local completion_group = vim.api.nvim_create_augroup("user_lsp_completion", { clear = true })
      local completion_timer = assert(vim.uv.new_timer())
      local generation = 0
      local dismissed_buf, dismissed_tick
      local function cancel_completion()
        generation = generation + 1
        completion_timer:stop()
      end
      vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP" }, {
        group = completion_group,
        callback = function(args)
          cancel_completion()
          if vim.fn.pumvisible() ~= 0
            or (dismissed_buf == args.buf and dismissed_tick == vim.b[args.buf].changedtick) then
            return
          end
          local pending = generation
          local cursor = vim.api.nvim_win_get_cursor(0)
          completion_timer:start(80, 0, vim.schedule_wrap(function()
            if pending ~= generation or vim.api.nvim_get_current_buf() ~= args.buf
              or not vim.deep_equal(cursor, vim.api.nvim_win_get_cursor(0))
              or not vim.api.nvim_get_mode().mode:match("^i") or vim.fn.pumvisible() ~= 0 then
              return
            end
            local prefix = vim.api.nvim_get_current_line():sub(1, cursor[2])
            if vim.fn.match(prefix, [[\k$\|\.$]]) < 0
              or #vim.lsp.get_clients({ bufnr = args.buf, method = "textDocument/completion" }) == 0 then
              return
            end
            vim.lsp.completion.get()
          end))
        end,
      })
      vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, {
        group = completion_group,
        callback = cancel_completion,
      })
      vim.api.nvim_create_autocmd("CompleteDone", {
        group = completion_group,
        callback = function(args)
          cancel_completion()
          if vim.v.event.reason == "accept" or vim.v.event.reason == "cancel" then
            -- Accepting a word itself fires TextChangedI; wait for a new edit.
            dismissed_buf, dismissed_tick = args.buf, vim.b[args.buf].changedtick
          end
        end,
      })
      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = completion_group,
        callback = function()
          cancel_completion()
          completion_timer:close()
        end,
      })
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_keymaps", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
          end

          -- jdtls re-indents on `;`, `}` and newline, so Java keeps its shape while
          -- typing instead of waiting for an explicit format.
          if client and client:supports_method("textDocument/onTypeFormatting") then
            vim.lsp.on_type_formatting.enable(true, { client_id = client.id })
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
          -- Neovim's default insert-mode signature-help key is CTRL-S, which
          -- config/keymaps.lua already uses for saving.
          if client and client:supports_method("textDocument/signatureHelp") then
            map("i", "<A-s>", vim.lsp.buf.signature_help, "签名帮助")
          end
        end,
      })
    end,
    config = function()
      local ensure_installed = vim.deepcopy(servers)
      vim.list_extend(ensure_installed, plugin_managed_servers)
      require("mason-lspconfig").setup({
        ensure_installed = ensure_installed,
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
