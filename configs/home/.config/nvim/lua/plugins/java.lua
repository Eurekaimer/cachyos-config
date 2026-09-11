-- Java tooling: eclipse.jdt.ls driven by nvim-jdtls.
-- Mason only installs the `jdtls` launcher (see lsp.lua); the client is started here
-- instead of through vim.lsp.enable because nvim-jdtls adds the JDT-specific
-- commands (JdtCompile, JdtRestart, JdtBytecode, ...) and code-action extensions
-- that the bare LSP client has no equivalent for.
local root_markers = {
  "gradlew",
  "mvnw",
  "settings.gradle",
  "settings.gradle.kts",
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
  ".git",
}

local function workspace_dir(root_dir)
  -- eclipse.jdt.ls keeps a per-project index; caching it keeps restarts cheap.
  return vim.fs.joinpath(vim.fn.stdpath("cache"), "jdtls", vim.fn.fnamemodify(root_dir, ":p:h:t"))
end

return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    config = function()
      local jdtls = require("jdtls")

      local map = function(bufnr, mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_jdtls", { clear = true }),
        pattern = "java",
        callback = function(args)
          local root_dir = jdtls.setup.find_root(root_markers, vim.api.nvim_buf_get_name(args.buf))
            or vim.fn.getcwd()

          jdtls.start_or_attach({
            cmd = { "jdtls", "-data", workspace_dir(root_dir) },
            root_dir = root_dir,
            settings = {
              java = {
                signatureHelp = { enabled = true },
                sources = {
                  organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
                },
                completion = {
                  favoriteStaticMembers = {
                    "org.junit.jupiter.api.Assertions.*",
                    "java.util.Objects.requireNonNull",
                  },
                },
                codeGeneration = { useBlocks = false },
              },
            },
          })

          map(args.buf, "n", "<leader>co", jdtls.organize_imports, "整理 import")
          map(args.buf, "n", "<leader>cv", jdtls.extract_variable, "提取变量")
          map(args.buf, "n", "<leader>cc", jdtls.extract_constant, "提取常量")
          map(
            args.buf,
            "x",
            "<leader>cv",
            "<Esc><Cmd>lua require('jdtls').extract_variable({ visual = true })<CR>",
            "提取变量"
          )
          map(
            args.buf,
            "x",
            "<leader>cc",
            "<Esc><Cmd>lua require('jdtls').extract_constant({ visual = true })<CR>",
            "提取常量"
          )
          map(
            args.buf,
            "x",
            "<leader>cm",
            "<Esc><Cmd>lua require('jdtls').extract_method({ visual = true })<CR>",
            "提取方法"
          )
        end,
      })
    end,
  },
}
