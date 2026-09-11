# Neovim

[English](../en/neovim.md)

这套配置参考 LazyVim 的使用体验，但没有直接导入完整 LazyVim 发行版。目标是保留
真正影响日常编辑的搜索、导航、LSP、Treesitter 和快捷键提示，同时优先使用
Neovim 0.12 内置能力，避免为了很小的功能长期维护额外插件。

## 设计原则

1. **一个插件必须解决多个反复出现的问题，或者解决 Neovim 本身无法良好解决的
   单一问题。**
2. **禁止职责重叠。** Snacks 是唯一的搜索器、文件树、启动页、通知和浮动终端层。
3. **优先使用 Neovim 0.12。** 原生 LSP 补全替代补全框架，内置 `gc` 替代注释
   插件；主题只在 `lua/plugins/theme.lua` 保留一套 Kanagawa Wave。
4. **可选工具延迟加载。** VimBeGood 只有执行命令时才加载。
5. **锁定结果。** `lazy-lock.json` 记录插件版本，保证恢复可重复。

最终锁文件只包含 **17 个插件仓库**，其中已经包括插件管理器本身。

## 配置结构

| 路径 | 职责 |
| --- | --- |
| `init.lua` | 设置 leader 键并按固定顺序加载核心模块 |
| `lazy-lock.json` | 固定插件版本 |
| `lua/config/autocmds.lua` | 通用生命周期钩子和 fcitx5 状态管理 |
| `lua/config/keymaps.lua` | 全局快捷键和原生补全菜单控制 |
| `lua/config/lazy.lua` | 引导 lazy.nvim 并导入插件声明 |
| `lua/config/options.lua` | 编辑器选项、工具链路径、剪贴板检测和主题兜底 |
| `lua/plugins/theme.lua` | Kanagawa Wave 配色 |
| `lua/plugins/ui.lua` | Snacks、Aerial 大纲、which-key 和光标动画 |
| `lua/plugins/editing.lua` | 成对符号编辑、自动保存、snippets 引擎和移动练习 |
| `lua/plugins/syntax.lua` | Treesitter 解析器与高亮 |
| `lua/plugins/markdown.lua` | Markdown 编辑器内渲染与内联图片 |
| `lua/plugins/java.lua` | nvim-jdtls：Java 语言服务器与 JDT 扩展命令 |
| `lua/plugins/lsp.lua` | Mason、LSP、原生补全、诊断和代码导航 |
| `lua/snippets/markdown.lua` | Markdown 专用 TeX 公式片段 |

配置注释统一使用简洁、规范的英文句子；which-key 中面向使用者的快捷键说明保留
中文，避免日常操作时还要翻译。

## 保留的插件

下表按项目名排序。每个项目都有明确的职责边界；“保留原因”就是以后判断它是否
仍然值得存在的标准。

| 项目 | 加载方式 | 作用 | 保留原因与动机 |
| --- | --- | --- | --- |
| [aerial.nvim](https://github.com/stevearc/aerial.nvim) | `AerialToggle` 等命令 | 多级标题/代码大纲、跳转、Markdown 正文折叠 | 长 Markdown 需要能同步驱动折叠的结构视图；一个插件同时覆盖浏览与折叠，其他语言不接管其折叠设置。 |
| [auto-save.nvim](https://github.com/okuuva/auto-save.nvim) | `InsertLeave`、`TextChanged` | 离开插入模式或文本变化后自动写盘 | 防止写作内容因断电或窗口被强杀而丢失；手动保存仍然有效，也不需要额外快捷键。 |
| [image.nvim](https://github.com/3rd/image.nvim) | 仅 Kitty + `markdown` | 在编辑器内显示 Markdown 内联图片和图片文件 | 图片无法由 Neovim 核心渲染；只在支持 Kitty 图形协议的终端启用，其他终端自动跳过。 |
| [kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim) | 启动时 | 提供 Kanagawa Wave 配色 | 长时间阅读与写作需要低对比度、护眼的配色；`options.lua` 仍保留内置配色兜底。 |
| [lazy.nvim](https://github.com/folke/lazy.nvim) | 启动时 | 安装插件、解析依赖、延迟加载并维护锁文件 | 可重复安装插件需要一个足够小的管理器；它也避免了自己维护 clone/update 脚本。 |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | 仅 `markdown` | 展开 Markdown 中的 TeX 公式片段 | 公式片段需要可维护的 snippet 引擎；只对 markdown 文件加载，不影响其他语言。 |
| [mason-lspconfig.nvim](https://github.com/mason-org/mason-lspconfig.nvim) | 启动时 | 将 nvim-lspconfig 的服务器名映射到 Mason 软件包 | 七种语言服务器只需要维护一份声明，不必重复维护软件包名映射。 |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | 启动时 | 将语言服务器安装到 Neovim 数据目录 | 否则七个服务器要分别处理系统包、npm、Go、Java 和发布压缩包。Mason 只管理开发工具，不管理普通插件。 |
| [mini.pairs](https://github.com/nvim-mini/mini.pairs) | 启动时 | 括号、方括号、花括号和引号自动成对，`<BS>` 删除整对，`<CR>` 展开成缩进块 | 手写 Java 时每个 `(` 和 `{` 都要再打一次闭符号；插件只在进入插入模式时加载，不占启动时间。 |
| [mini.surround](https://github.com/nvim-mini/mini.surround) | 启动时 | 添加、删除、查找、高亮和替换引号/括号等包围符号 | Neovim 核心没有等价操作；它能直接消除大量“删除旧括号再输入新括号”的重复编辑。 |
| [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls) | `java` 文件类型 | 为 eclipse.jdt.ls 提供 JDT 扩展：整理 import、提取变量/常量/方法、编译与重启命令 | 裸 LSP 客户端只能做补全和跳转，`vim.lsp.enable("jdtls")` 拿不到这些 Java 专属操作；Java 是当前要写的主要语言，需要它们。 |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | 启动时 | 为常见语言服务器提供经过维护的默认配置 | LSP 客户端属于 Neovim，但服务器命令、文件类型和项目根目录规则仍需要可靠默认值。 |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | 启动时 | 为 Neovim 原生 Treesitter 下载解析器和查询文件 | 高亮器属于 Neovim，但常用语言解析器和查询文件不会全部随核心提供；一个插件即可覆盖所有语言。 |
| [rainbow-delimiters.nvim](https://github.com/HiPhish/rainbow-delimiters.nvim) | 启动加载 | 按嵌套深度给 `()` `[]` `{}` 逐层着色（Treesitter 驱动） | 深嵌套括号同色时无法分辨层级；七种色相按「相邻层对比最强」的顺序排列，颜色取自 Kanagawa palette，不引入第二套配色。 |
| [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) | 仅 `markdown` | 在编辑器内渲染标题、列表、表格和代码块 | 写作时不必开预览窗口；`Space mr` 可随时关闭渲染查看源码。 |
| [smear-cursor.nvim](https://github.com/sphamba/smear-cursor.nvim) | `VeryLazy` | 在终端中模拟 Neovide 的光标拖尾动画 | 同一份配置在终端与 Neovide 下手感一致；Neovide 内自动禁用，无额外成本。 |
| [snacks.nvim](https://github.com/folke/snacks.nvim) | 启动时，具体模块按需运行 | 启动页、文件树、模糊搜索、通知、大文件处理、状态列、专注模式、buffer 删除和 LazyGit 终端 | 一个仓库替代多个传统 UI 插件，是在保持易用性的同时压低插件数量的关键。 |
| [vim-be-good](https://github.com/ThePrimeagen/vim-be-good) | 仅执行 `:VimBeGood` 时 | 交互式 Vim 移动练习 | 它直接服务于当前的 Vim 学习目标，普通编辑时完全不加载；形成肌肉记忆后可以删除。 |
| [vim-clang-format](https://github.com/rhysd/vim-clang-format) | C 系与 Java 文件类型 | 调用系统 `clang-format` 二进制格式化代码 | Neovim 没有内置 C 系格式化器；直接驱动官方二进制可完全复用项目里的 `.clang-format`，不必再维护一份样式。 |
| [vim-repeat](https://github.com/tpope/vim-repeat) | LuaSnip 依赖 | 让 snippet 展开正确接入 `.` 重复操作 | LuaSnip 的配套依赖，缺少它时重复展开会丢失语义。 |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | `VeryLazy` | 按下 leader/前缀键后显示可继续按的键 | 在学习阶段，“可发现性”比少一个很小的插件更重要；快捷键形成肌肉记忆后可以重新评估。 |

## 明确没有安装的插件

这些不是遗漏功能，而是 Neovim 核心或已经保留的插件拥有相同职责。

| 候选项目 | 决策与替代方案 |
| --- | --- |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | 不安装。使用 Snacks 的 `Space gg` 打开 LazyGit；当前不需要第二套 Git 展示层。 |
| [lazydev.nvim](https://github.com/folke/lazydev.nvim) | 不安装。`lua_ls` 直接把 `VIMRUNTIME` 加入 workspace library，足以维护这套小配置。 |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | 不安装。原生状态栏加 Snacks 状态列已经提供必要的文件、模式和诊断上下文。 |
| [mini.comment](https://github.com/nvim-mini/mini.comment) | 不安装。Neovim 0.12 已经内置 `gc` 和 `gcc`。 |
| [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) | 不安装。文件浏览统一由 Snacks explorer 负责。 |
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) 及其补全源/代码片段扩展 | 不安装。使用 `vim.lsp.completion`，一次删除六个仓库；文件路径补全仍可使用原生 `Ctrl-X Ctrl-F`。 |
| [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) | 不安装。文件浏览统一由 Snacks explorer 负责。 |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | 不安装。文件、全文、buffer、帮助、诊断、快捷键和 LSP 搜索统一由 Snacks picker 负责。 |
| [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | 不安装。配色由 `lua/plugins/theme.lua` 的 Kanagawa Wave 负责，不需要第二套主题插件。 |

## 外部依赖

第一列按字母顺序排列。必需的额外依赖记录在 `packages/required-extra.txt`，当前
工作站显式安装的软件记录在 `packages/pacman-explicit.txt`。

| 依赖 | 状态 | 用途 |
| --- | --- | --- |
| `clang-format`（`clang` 包） | 显式软件包 | `<leader>cF` 格式化 C/C++/Java 等语言 |
| `fd` | 必需额外依赖 | Snacks picker 快速查找文件 |
| `jdk-openjdk` / `jdk21-openjdk` | 显式软件包 | eclipse.jdt.ls 需要 Java 21+ 运行时 |
| `lazygit` | 显式软件包 | `Space gg` Git 界面 |
| `neovim` | 显式软件包；当前配置面向 0.12 | 编辑器、原生 LSP 补全、原生注释和原生代码片段能力 |
| `npm` | 必需额外依赖 | Mason 安装 Bash、Pyright 和 TypeScript 语言服务器 |
| `ripgrep` | 显式软件包 | Snacks picker 项目全文搜索 |
| `tree-sitter-cli` | 必需额外依赖 | 编译 nvim-treesitter v1 解析器 |
| `wl-clipboard` | 可选，启动时自动检测 | Wayland 系统剪贴板互通 |

## 首次启动与恢复

常规恢复会先安装软件包，再恢复用户配置：

```bash
./scripts/restore-all.sh --dry-run
./scripts/restore-all.sh
```

第一次启动 Neovim 时：

1. `config/lazy.lua` 在 lazy.nvim 不存在时自动克隆它。
2. lazy.nvim 根据 `lazy-lock.json` 安装固定版本。
3. Mason 安装配置声明的语言服务器。
4. nvim-treesitter 下载并编译缺失的解析器。

常用状态命令：

```vim
:Lazy
:Mason
:checkhealth snacks
:checkhealth vim.lsp
:checkhealth vim.treesitter
```

## Snacks 工作流

Snacks 是唯一的通用 UI 层。

| 快捷键 | 功能 |
| --- | --- |
| `Space Space` | 智能查找文件或 buffer |
| `Space bd` | 在不破坏窗口布局的情况下删除当前 buffer |
| `Space e` | 切换文件树 |
| `Space fb` | 选择已打开的 buffer |
| `Space ff` | 在当前工作目录查找文件 |
| `Space fg` | 使用 ripgrep 搜索项目文本 |
| `Space fh` | 搜索帮助文档 |
| `Space fr` | 打开最近文件 |
| `Space gg` | 在浮动终端打开 LazyGit |
| `Space n` | 查看通知历史 |
| `Space sd` | 搜索工作区诊断 |
| `Space sk` | 搜索所有已注册快捷键 |
| `Space ss` | 搜索当前 LSP 提供的文档符号 |
| `Space z` | 切换专注模式 |

忘记快捷键时优先使用 `Space sk`，它比死记本文档更快、更可靠。

## 文件树与代码大纲

文件浏览与预览仍由 Snacks 负责：`Space e` 切换文件树，`Space Space` 或 `Space ff` 打开
带预览窗格的 picker，`Space mr` / `Space mi` 控制 Markdown 渲染与内联图片。这是日常
最常用的两个文件管理入口——`Space e` 看目录树，`Space a` 看当前文件结构。

标题与代码大纲由 Aerial 负责。普通模式按 `Space a`（空格后按 `a`）在右侧打开大纲并进入，
再次按下关闭。Markdown 默认展开所有层级，大纲折叠会同步收起正文中的整个章节
（包括子标题及内容），不会删除文字；其他语言仍可浏览代码符号，但不接管正文折叠。

以下按键仅在大纲窗口中生效：

| 按键 | 作用 |
| --- | --- |
| `j` / `k` | 向下/向上选择可见标题，包含不同层级 |
| `<Enter>` | 跳到所选标题并回到正文 |
| `p` | 正文滚动到所选标题，焦点留在大纲 |
| `h` / `l` | 收起/展开当前节点 |
| `zC` / `zO` | 递归收起/展开当前节点及全部子节点 |
| `za` / `zA` | 切换当前节点/递归切换 |
| `zM` / `zR` | 收起/展开整个大纲 |
| `q` | 关闭大纲 |
| `?` | 查看大纲快捷键 |

保留全局 `Ctrl-h/j/k/l` 窗口切换、`Ctrl-s` 保存和 `L` 行尾映射；大纲是只读窗口，
保存正文前先用 `Ctrl-h` 返回正文。未采用上游示例的 `{` / `}` 标题跳转映射，
避免覆盖原有段落移动。

## 编辑与窗口快捷键

| 快捷键 | 功能 |
| --- | --- |
| `Ctrl-H/J/K/L` | 在分屏之间移动 |
| `Ctrl-S` 或 `Space s` | 保存 |
| Normal 模式 `Esc` | 清除搜索高亮 |
| Visual 模式 `J` / `K` | 向下/向上移动选中的行 |
| Insert 模式 `jk` | 返回 Normal 模式 |
| `Space bn` / `Space bp` | 下一个/上一个 buffer |
| `Space wd` | 关闭当前分屏 |
| `Space ws` / `Space wv` | 水平/垂直分屏 |
| `Space w=` | 均分窗口大小 |
| Visual 模式 `<` / `>` | 调整缩进并保留选区 |

用于替代插件的 Neovim 原生功能：

| 快捷键 | 功能 |
| --- | --- |
| `gcc` | 切换当前行注释 |
| `gc{motion}` | 注释一个 Vim motion，例如 `gcip` 注释段落 |
| `Ctrl-X Ctrl-F` | 补全文件系统路径 |
| `u` / `Ctrl-R` | 撤销 / 重做 |
| `.` | 重复上一次修改 |

mini.surround 使用当前默认键位：

| 快捷键 | 功能 |
| --- | --- |
| `sa{motion}{char}` | 添加包围符号 |
| `sd{char}` | 删除包围符号 |
| `sr{old}{new}` | 替换包围符号 |

mini.pairs 在插入模式下自动补全成对符号：

| 输入 | 结果 |
| --- | --- |
| `(` `[` `{` | 同时插入另一半，光标停在中间 |
| `"` `'` `` ` `` | 插入成对引号 |
| 闭括号位于自动补全位置 | 跳过而不是重复插入 |
| 空对中间按 `<BS>` | 一次删除整对 |
| 空对中间按 `Enter` | 展开为缩进块，光标停在块内 |

反斜杠后不触发；单引号前是字母时不触发（避免 `don't` 被拆开）；要原样输入单个符号
用 `Ctrl-V` 前缀。

括号按嵌套层级着色（rainbow-delimiters.nvim，基于 Treesitter），七种颜色依次循环：

| 层级 | 高亮组 | 层级 | 高亮组 |
| --- | --- | --- | --- |
| 1 | `RainbowDelimiterRed` | 5 | `RainbowDelimiterGreen` |
| 2 | `RainbowDelimiterYellow` | 6 | `RainbowDelimiterViolet` |
| 3 | `RainbowDelimiterBlue` | 7 | `RainbowDelimiterCyan` |
| 4 | `RainbowDelimiterOrange` | | |

颜色取自 Kanagawa palette，定义在 `lua/plugins/theme.lua` 的 `overrides` 中，
主题切换后重新应用；没有对应解析器的语言不生效。

退出插入模式或文本变化后会自动写盘（`auto-save.nvim`），断电或窗口被强杀时最多丢失
一次防抖窗口内的改动；手动保存仍然有效。

执行 `:VimBeGood` 开始移动练习。这个插件按命令加载，正常启动没有额外成本。

## LSP 与原生补全

已配置服务器按语言名称排序：

| 语言 | nvim-lspconfig 名称 | Mason 软件包 |
| --- | --- | --- |
| Bash | `bashls` | `bash-language-server` |
| Go | `gopls` | `gopls` |
| Java | `jdtls`（由 nvim-jdtls 启动） | `jdtls` |
| JavaScript / TypeScript | `ts_ls` | `typescript-language-server` |
| Lua | `lua_ls` | `lua-language-server` |
| Python | `pyright` | `pyright` |
| Rust | `rust_analyzer` | `rust-analyzer` |

LSP 快捷键是 buffer-local，只有语言服务器成功连接后才出现：

| 快捷键 | 功能 |
| --- | --- |
| Insert 模式 `Ctrl-Space` | 主动请求补全 |
| Insert 模式 `Alt-s` | 显示函数签名帮助（服务器支持时） |
| 补全菜单打开时 `Enter` | 接受当前补全项 |
| `K` | 查看悬停文档 |
| 补全菜单打开时 `Shift-Tab` / `Tab` | 上一个/下一个补全项 |
| `Space ca` | 代码操作 |
| `Space cd` | 查看光标处诊断 |
| `Space cf` | 请求当前服务器格式化 |
| `Space cr` | 重命名符号 |
| `[d` / `]d` | 上一个/下一个诊断 |
| `gD` / `gd` | 跳转声明/定义 |
| `gI` / `gr` / `gy` | 跳转实现/查看引用/跳转类型定义 |

格式化是否可用取决于服务器能力。例如 Go 和 Rust 服务器可以直接格式化；Pyright
主要是类型检查器，不能替代 Python 格式化工具。

### Java

Java 由 `nvim-jdtls` 启动 eclipse.jdt.ls。`lsp.lua` 只让 Mason 安装 `jdtls`
启动器，不调用 `vim.lsp.enable("jdtls")`，否则会同时出现两个客户端。项目根目录按
`gradlew`、`mvnw`、`settings.gradle{,.kts}`、`pom.xml`、`build.gradle{,.kts}`、
`.git` 依次向上查找，索引缓存在 `~/.cache/nvim/jdtls/<项目名>`。

`.java` 缓冲区除上表通用键位外还有：

| 快捷键 | 功能 |
| --- | --- |
| `Space co` | 整理 import |
| `Space cv` | 提取变量（可视模式提取选中表达式） |
| `Space cc` | 提取常量（同上） |
| `Space cm` | 提取方法（仅可视模式） |

`eclipse.jdt.ls` 自带 `textDocument/formatting`，因此 `Space cf` 在 Java 中同样可用。
另有 `:JdtCompile`、`:JdtRestart`、`:JdtBytecode`、`:JdtUpdateConfig` 等命令。

Java 还启用了 on-type formatting：jdtls 声明 `;`、换行和 `}` 为触发字符，`lsp.lua`
按服务器能力探测后调用 `vim.lsp.on_type_formatting.enable()`，其他服务器未声明该能力时自动跳过。

### 格式化（clang-format）

`vim-clang-format` 驱动系统 `clang-format` 二进制（`clang` 包提供），覆盖
`c`、`cpp`、`objc`、`java`、`javascript`、`typescript`、`proto`、`cuda`、`vala`。
在这些文件类型中按 `Space cF` 格式化整个文件，可视模式下只格式化选区。

样式解析顺序：

1. 从当前文件目录向上查找 `.clang-format` 或 `_clang-format`，找到就用 `-style=file`；
2. 找不到则回退到 `{BasedOnStyle: google, IndentWidth: <shiftwidth>}`。

`Space cf`（LSP 格式化）与 `Space cF`（clang-format）是两条独立路径：前者由语言
服务器执行，后者始终走外部二进制。

## Treesitter

解析器按名称排序：

`bash`、`c`、`cpp`、`go`、`java`、`javascript`、`json`、`lua`、`markdown`、
`markdown_inline`、`python`、`query`、`rust`、`toml`、`typescript`、
`vim`、`vimdoc`、`yaml`。

`java`、`c`、`cpp` 是本次为括号着色新加的解析器（rainbow-delimiters 没有解析器时
不工作）。

实际高亮由 Neovim 完成。nvim-treesitter 只负责安装解析器和查询文件，随后由
`FileType` autocmd 在解析器存在时调用 `vim.treesitter.start()`。没有启用会与核心
重复的额外 Treesitter 模块。

## 中文输入法

`lua/config/autocmds.lua` 直接调用 `fcitx5-remote`，不再增加输入法插件：

1. 离开 Insert 模式时记录 fcitx5 是否启用，并切换到英文。
2. 再次进入 Insert 模式时恢复之前的启用状态。
3. 退出 Neovim 时恢复之前的输入法。

这样 Normal 模式命令始终是 ASCII，同时保留 Insert 模式的中文输入状态。

## 维护与同步

修改实时配置，而不是直接修改仓库快照：

```bash
nvim ~/.config/nvim
```

完成实际启动和功能检查后：

```bash
cd ~/Documents/GitHub/cachyos-config
./scripts/capture.sh
./scripts/audit.sh

git add -A
git commit -m "feat(nvim): refine minimalist editor config"
git push
```

`manifests/home-paths.txt` 已将 nvim 目录加入白名单。插件数据、Mason 下载、解析器
二进制、缓存和撤销历史不会提交；配置文件和锁文件负责在另一台机器上重新生成它们。

## 排障

| 现象 | 检查方法 |
| --- | --- |
| 不出现补全 | 执行 `:checkhealth vim.lsp` 和 `:LspInfo`，确认服务器已连接，再按 `Ctrl-Space`。 |
| 文件或全文搜索为空 | 确认 `fd` 和 `rg` 位于 `PATH`，然后执行 `:checkhealth snacks`。 |
| Bash/Python/TypeScript LSP 安装失败 | 检查 `npm --version`，然后在 `:Mason` 中重试。 |
| 解析器编译失败 | 检查 `tree-sitter --version` 和 C 编译器，再执行 `:TSUpdate`。 |
| Java 无响应或报 `Java XY language features are not available` | 确认 JDK 21+ 在 `PATH`，再执行 `:JdtRestart`；索引缓存在 `~/.cache/nvim/jdtls/`，可删除后重建。 |
| `Space cF` 报找不到 clang-format | `pacman -S clang`，并确认 `clang-format --version` 可执行。 |
| 插件启动失败 | 打开 `:Lazy` 查看失败任务，然后重新执行同步。 |
| 系统剪贴板不可用 | 安装 `wl-clipboard`；配置只在检测到 provider 时启用 `unnamedplus`。 |
