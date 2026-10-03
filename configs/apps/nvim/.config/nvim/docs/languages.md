# LSP、Java 与格式化

[返回首页](../README.md) · [LSP 快捷键](keymaps.md#lsp)

## LSP

Mason 确保以下服务器已安装并由 Neovim 0.12 原生接口启用：

| Server | 语言 |
|---|---|
| `bashls` | Bash |
| `gopls` | Go |
| `lua_ls` | Lua |
| `pyright` | Python |
| `rust_analyzer` | Rust |
| `ts_ls` | JavaScript / TypeScript |

Lua LSP 已识别 `vim` 和 `Snacks` 全局变量、LuaJIT runtime 及 Neovim runtime library。支持 completion 的 server 会自动启用 Neovim 原生补全。

原生 `autotrigger` 只响应服务器声明的触发字符（例如 Pyright 的 `.`），不会自行覆盖
普通标识符输入和退格。本配置在文本变化后等待 80 ms，在菜单关闭且光标位于关键词
或 `.` 后时请求 LSP 补全；菜单打开时仍由原生补全筛选候选。确认、取消、离开插入
模式或切换缓冲区会取消待触发请求，避免菜单立即重新弹出。

Python 使用 Pyright 的语义补全：`imp` 提示 `import`，`import asy` 提示 `asyncio`；
已有 `import asyncio` 和 `event_loop` 定义时，`asy`、`event_l` 分别提示模块和变量。
`asyncio.` 的成员补全在错字导致菜单消失后，退格修正前缀会再次出现；无需重新输入 `.`。
`<C-Space>` 仍可手动触发，`<Tab>` / `<S-Tab>` 选择，`<Enter>` 确认，`<C-e>` 取消。

### Java

Java 由 `nvim-jdtls` 启动 eclipse.jdt.ls（Mason 只负责安装 `jdtls` 启动器，
`lsp.lua` 不启用它，避免出现两个客户端）。项目根目录按 `gradlew`、`mvnw`、
`settings.gradle{,.kts}`、`pom.xml`、`build.gradle{,.kts}`、`.git` 依次向上查找，
索引缓存在 `~/.cache/nvim/jdtls/<项目名>-<root 路径哈希>`（同名项目不会共用索引）。

当前 Java 设置针对 CS61B 目录结构：**对所有 Java 项目关闭 Maven 导入**，
并设置 `project.sourcePaths = { "." }`（见 `lua/plugins/java.lua`）。
因此不能把它当作通用 Maven 项目配置；正常 Maven 项目应恢复默认导入，并将课程特化设置限定到对应项目。

除[通用 LSP 键位](keymaps.md#lsp)外，`.java` 缓冲区额外提供：

| 按键 | 作用 |
|---|---|
| `<leader>co` | 整理 import |
| `<leader>cv` | 提取变量（可视模式提取选中表达式） |
| `<leader>cc` | 提取常量（同上） |
| `<leader>cm` | 提取方法（仅可视模式） |

`eclipse.jdt.ls` 自身也提供 `textDocument/formatting`，所以 `<leader>cf`
在 Java 里同样可用；命令 `:JdtCompile`、`:JdtRestart`、`:JdtBytecode`、
`:JdtUpdateConfig` 也可用。需要 Java 21+ 运行时。

Java 还启用了 on-type formatting：jdtls 声明了 `;`、换行和 `}` 作为触发字符，
`vim.lsp.on_type_formatting` 在这些字符输入后请服务器调整缩进（`lsp.lua` 中按能力
探测启用，其他服务器未声明该能力时自动跳过）。

### 签名帮助

`<A-s>` 在插入模式下显示当前调用的签名。Neovim 默认把 `CTRL-S` 映射到签名帮助，
而本配置把 `CTRL-S` 用作保存，因此改用 `Alt+s`。

### 格式化（clang-format）

`vim-clang-format` 调用系统的 `clang-format` 二进制（`clang` 包提供），
适用于 `c`、`cpp`、`objc`、`java`、`javascript`、`typescript`、`proto`、
`cuda`、`vala`。在这些文件类型中按 `<leader>cF` 格式化整个文件（可视模式格式化选区）。

样式解析顺序：

1. 从当前文件目录向上查找 `.clang-format` 或 `_clang-format`，找到就用 `-style=file`；
2. 找不到则回退到 `{BasedOnStyle: google, IndentWidth: <shiftwidth>}`。

`<leader>cf`（LSP 格式化）与 `<leader>cF`（clang-format）是两条独立路径：
前者由语言服务器执行，后者始终走外部二进制。
