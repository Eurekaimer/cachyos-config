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

local function root_source_pom(root_dir)
  local pom = vim.fs.joinpath(root_dir, "pom.xml")
  if vim.fn.filereadable(pom) == 0 then
    return nil
  end
  local contents = table.concat(vim.fn.readfile(pom), "\n"):gsub("<!%-%-.-%-%->", "")
  if contents:match("<sourceDirectory>%s*%${project%.basedir}%s*</sourceDirectory>") then
    return contents
  end
end

local function course_library(contents, root_dir)
  local parent = contents:match("<parent>(.-)</parent>") or ""
  if not parent:match("<groupId>%s*CS61B%s*</groupId>") then
    return nil
  end
  local relative_path = parent:match("<relativePath>%s*(.-)%s*</relativePath>")
  if relative_path then
    local parent_pom = vim.fs.normalize(vim.fs.joinpath(root_dir, relative_path))
    if vim.fn.filereadable(parent_pom) == 1 then
      return vim.fs.dirname(parent_pom)
    end
  end
end

local function workspace_dir(root_dir)
  -- eclipse.jdt.ls keeps a per-project index; caching it keeps restarts cheap.
  local project = vim.fs.basename(root_dir)
  return vim.fs.joinpath(vim.fn.stdpath("cache"), "jdtls", project .. "-" .. vim.fn.sha256(root_dir))
end

return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    cmd = { "CS61BSetup", "CS61BSync", "CS61BTest", "CS61BPom" },
    config = function()
      local jdtls = require("jdtls")

      local function course_project()
        local root = jdtls.setup.find_root(root_markers, vim.api.nvim_buf_get_name(0)) or vim.fn.getcwd()
        local contents = root_source_pom(root)
        local library = contents and course_library(contents, root)
        assert(library, "当前项目不是可识别的 CS61B 项目；请打开课程 Java 文件或 pom.xml")
        return root, library
      end

      local function open_pom()
        local root = course_project()
        vim.cmd.edit(vim.fs.joinpath(root, "pom.xml"))
      end

      vim.api.nvim_create_user_command("CS61BPom", open_pom, { desc = "打开当前课程 pom.xml" })
      vim.api.nvim_create_user_command("CS61BSetup", function()
        open_pom()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local sources, targets = 0, 0
        local edits = {}
        for i, line in ipairs(lines) do
          local source_count, target_count
          local updated
          updated, source_count = line:gsub("(<source>)%s*[^<]+%s*(</source>)", function(a, b)
            return a .. "14" .. b
          end)
          updated, target_count = updated:gsub("(<target>)%s*[^<]+%s*(</target>)", function(a, b)
            return a .. "14" .. b
          end)
          sources, targets = sources + source_count, targets + target_count
          if updated ~= line then edits[i] = updated end
        end
        assert(sources > 0 and targets > 0, "当前 pom 未显式声明 source 和 target；未修改文件")
        for i, line in pairs(edits) do
          vim.api.nvim_buf_set_lines(0, i - 1, i, false, { line })
        end
        vim.cmd.update()
        vim.notify("当前课程 pom.xml 已保存：source/target = 14；执行 :CS61BSync 同步依赖")
      end, { desc = "显式保存当前课程 pom 的 Java 14 设置" })

      local function maven(goal)
        local root, library = course_project()
        assert(vim.fn.executable("mvn") == 1, "需要安装 Maven（mvn）")
        Snacks.terminal.open({
          "mvn",
          "--batch-mode",
          "--settings", vim.fs.joinpath(vim.fn.stdpath("config"), "maven-settings.xml"),
          "-Dmaven.repo.local=" .. library,
          goal,
        }, {
          cwd = root,
          interactive = false,
          win = { position = "bottom" },
        })
      end

      vim.api.nvim_create_user_command("CS61BSync", function() maven("dependency:resolve") end, {
        desc = "使用课程本地库同步 Maven 依赖",
      })
      vim.api.nvim_create_user_command("CS61BTest", function() maven("test") end, {
        desc = "使用课程本地库运行 Maven test",
      })

      local map = function(bufnr, mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_jdtls", { clear = true }),
        pattern = "java",
        callback = function(args)
          local root_dir = jdtls.setup.find_root(root_markers, vim.api.nvim_buf_get_name(args.buf))
            or vim.fn.getcwd()

          local java_settings = {
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
          }

          -- CS61B poms use the project root as both source and test directories.
          -- m2e cannot import that overlapping layout; keep the existing invisible
          -- project workaround only there. Normal Maven projects need their build
          -- model for editing, test dependencies and neotest-java's LSP classpath.
          local course_pom = root_source_pom(root_dir)
          if course_pom then
            java_settings.import = { maven = { enabled = false } }
            java_settings.project = { sourcePaths = { "." } }
            local library = course_library(course_pom, root_dir)
            if library then
              java_settings.project.referencedLibraries = { vim.fs.joinpath(library, "*.jar") }
            end
          end

          jdtls.start_or_attach({
            cmd = { "jdtls", "-data", workspace_dir(root_dir) },
            root_dir = root_dir,
            init_options = {
              settings = { java = java_settings },
              -- Import the opened file's invisible project and refresh cached libraries.
              triggerFiles = { vim.uri_from_bufnr(args.buf) },
            },
            settings = { java = java_settings },
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
      -- Loading on FileType can miss the first buffer's event.
      if vim.bo.filetype == "java" then
        vim.api.nvim_exec_autocmds("FileType", { group = "user_jdtls", pattern = "java" })
      end
    end,
  },
}
