# LSP、Java、格式化与测试

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

Java 对 CS61B 的根目录源码布局保留兼容处理：最近的 `pom.xml`（去除 XML 注释后）
包含 `<sourceDirectory>${project.basedir}</sourceDirectory>` 时，关闭 Maven 导入并设置
`project.sourcePaths = { "." }`，避免 m2e 的嵌套源码导入错误。普通 Maven 项目恢复默认
构建导入与源码目录，供 LSP 与 neotest 解析测试依赖；不按机器路径硬编码课程项目。
课程 pom 的 parent `groupId` 为 `CS61B` 时，沿 `<parent><relativePath>` 定位
`library-sp21/javalib/masterpom.xml`，将该目录的顶层 `*.jar` 关联给 jdtls。
启动时传入当前 Java 文件的 `triggerFiles`，让已缓存的课程索引也刷新库；
直接用 `nvim 文件.java` 打开第一份文件同样会附加客户端。无需更改课程源码。

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

#### CS61B Maven 操作

在课程 Java 文件或该项目的 `pom.xml` 中执行：

| 命令 | 作用 |
|---|---|
| `:CS61BPom` | 打开当前项目的 `pom.xml` |
| `:CS61BSetup` | 将显式 `<source>` / `<target>` 改为 `14` 并保存；不自动运行 |
| `:CS61BSync` | 在项目根运行 Maven `dependency:resolve` |
| `:CS61BTest` | 在项目根运行 Maven `test`，保留终端输出 |

顺序：`:CS61BSetup` → `:CS61BSync` → 回到 Java/pom 缓冲区 → `:CS61BTest`。
同步只解析 Maven 依赖，不让 m2e 导入课程的重叠源码布局；Java 编辑依赖上面的课程库关联。
同步与测试共同传入以下选项：

```text
--settings <当前 Neovim 配置目录>/maven-settings.xml
-Dmaven.repo.local=<由 parent relativePath 定位的 library-sp21/javalib>
```

`maven-settings.xml` 是空用户设置，替代 `~/.m2/settings.xml`；不改动全局 Maven 配置、
用户设置文件或其他项目的仓库。只覆盖当前命令的本地仓库；缺失依赖仍会联网下载。
源码级别与目标字节码 `14` 不等于安装或切换 JDK 14：jdtls 仍需 JDK 21+，
Maven 使用当前 `JAVA_HOME` / `PATH` 下的 JDK。本机使用 JDK 27。
课程实验尚未完成时，真实断言失败仍会导致 Maven `BUILD FAILURE`，不会被屏蔽。

验证：在完整 lab2 副本上运行上述三步，依赖解析与 `test` 均得到 `BUILD SUCCESS`；
10 项测试通过、0 失败、0 错误。原课程 pom 未修改。

### 签名帮助

`<A-s>` 在插入模式下显示当前调用的签名。Neovim 默认把 `CTRL-S` 映射到签名帮助，
而本配置把 `CTRL-S` 用作保存，因此改用 `Alt+s`。

### 外部格式化（Conform）

`lua/plugins/editing.lua` 使用 `conform.nvim` 统一调用外部格式化器。
普通模式 `<leader>cF` 格式化文件，可视模式格式化选区；`:ConformInfo` 查看工具状态与日志。
不启用保存时格式化，自动保存与格式化互相独立。

| 文件类型 | 外部工具 |
|---|---|
| C/C++/Objective-C、Java、JavaScript/TypeScript、Protobuf、CUDA、Vala | `clang-format` |
| Go | `gofmt` |
| Rust | `rustfmt` |
| Python | `black` |
| Lua | `stylua` |

工具必须在 Neovim 的 PATH 中；插件不自动安装它们。
本机已有 clang-format、gofmt、rustfmt；black 与 stylua 尚未安装。

clang-format 文件类型的样式解析顺序：

1. 从当前文件目录向上查找 `.clang-format` 或 `_clang-format`，找到就用 `-style=file`；
2. 找不到则回退到 `{BasedOnStyle: google, IndentWidth: <shiftwidth>}`。

`<leader>cf`（LSP 格式化）与 `<leader>cF`（Conform）是两条独立路径：
前者由语言服务器执行，后者按上表调用外部二进制，不悄悄回退到 LSP。

## 测试（neotest）

配置入口：`lua/plugins/testing.lua`；测试键位使用大写 `<leader>T`，不占用终端 `<leader>tt`。
不自动运行测试，不增加 DAP 或调试 UI；结果树和输出仅在调用时打开。

| 语言 | Adapter | 运行条件 |
|---|---|---|
| Java | `rcasia/neotest-java` | Java buffer 已启动 jdtls，项目导入/编译及测试 classpath 可用 |
| Python | `nvim-neotest/neotest-python` | 项目 Python 与测试依赖；官方优先检测 pytest/django，否则 unittest |
| Go | `fredrikaverpil/neotest-golang` | Go 工具链、可运行的模块；默认 `go test`，不需要 gotestsum |
| Rust | `rouge8/neotest-rust` | Cargo、rustc、cargo-nextest；不额外接管 Rust LSP |

Java 首次在 `:NeotestJava setup` 中选择下载 JUnit Platform standalone jar，插件会校验 SHA-256。
本机已安装默认 6.0.3 runner；安装在 `~/.local/share/nvim/neotest-java/`，不是配置目录。
打开 Java 文件并等待 jdtls 导入完成再运行测试。上游默认匹配以 `Test`、`Tests`、`IT`、`Spec`
结尾的测试类。课程项目通过 parent pom 的相对路径关联顶层 JUnit/jh61b/stdlib 等 jars，
不通过 jdtls 的 Maven 导入处理重叠源码目录；额外的库需加入课程库关联配置。
多模块项目沿用最近构建文件的根目录策略，并未新增跨模块管理。

Rust runner 已按 [Nextest 官方预编译安装说明](https://nexte.st/docs/installation/pre-built-binaries/)
安装到 `~/.cargo/bin/cargo-nextest`；`config/options.lua` 已将此目录加入 Neovim PATH。
Rust adapter 对 `main.rs`/`lib.rs`/`mod.rs` 默认按 `tests` 模块发现单测；部分集成测试按
Cargo 测试目标运行，不支持 rstest 的所有参数化情况。

`<leader>Ta` 运行当前工作目录下的测试，不猜测另一个项目根；先用 `:pwd` / `:cd` 核对目录。
失败时按 `<leader>To` 查看当前位置测试输出，或 `<leader>Tp` 看完整运行输出；
`:checkhealth neotest` 和 `:checkhealth neotest-java` 用于依赖诊断。
