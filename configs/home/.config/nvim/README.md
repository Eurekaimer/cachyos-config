# Neovim 配置

以 **Neovim 0.12 原生 LSP 与补全**为核心，使用 lazy.nvim 管理插件。Snacks 提供文件树、查找和终端；Kanagawa 提供主题；Markdown 渲染、Java、neotest 和刷题工具按需加载。

`<leader>` 与 `<localleader>` 均为空格键。

## 快速开始

```bash
nvim
```

首次启动会安装插件、已配置的语言服务器与 Treesitter 解析器，需要网络连接；等待安装完成后重启，再打开代码文件。

- 基础环境：Neovim **>= 0.12**、Git、真彩色终端；图标建议使用 Nerd Font。
- 文件查找/全文搜索：安装 `fd`、`ripgrep`。
- 系统剪贴板：`wl-copy` 或 `xclip`；中文输入法自动切换：`fcitx5-remote`。
- 可选功能依赖：图片需要 Kitty、ImageMagick 与 curl；Java 需要 JDK 21+；外部格式化需要 `clang-format`；Git 界面需要 LazyGit；刷题需要 curl。
- 测试：Python 项目测试依赖、Go 工具链、Rust `cargo-nextest`；Java 使用 jdtls 与 JUnit runner，见[测试说明](docs/languages.md#测试neotest)。

## 常用入口

| 操作 | 按键或命令 |
|---|---|
| 保存 / 退出插入模式 | `<C-s>` / `jk` |
| 智能查找 / 文件树 | `<leader><space>` / `<leader>e` |
| 查找文件 / 全文搜索 | `<leader>ff` / `<leader>fg` |
| 搜索快捷键 | `<leader>sk` |
| 窗口切换 | `<C-h/j/k/l>` |
| 终端 / 大纲 | `<leader>tt` / `<leader>a` |
| 跳转定义 / 悬停文档 | `gd` / `K`（LSP 附加后） |
| 代码操作 / 重命名 | `<leader>ca` / `<leader>cr` |
| LSP 格式化 / Conform 文件或选区格式化 | `<leader>cf` / `<leader>cF` |
| 当前文件关键词补全或 snippet 前进 / 后退 | `<Tab>` / `<S-Tab>` |
| 跳出 `()` / `[]` / `{}` | `<C-Tab>`（终端备用：`<M-l>`） |
| Markdown 渲染 / 图片开关 | `<leader>mr` / `<leader>mi` |
| 最近测试 / 当前文件测试 / 结果树 | `<leader>Tn` / `<leader>Tf` / `<leader>Ts` |
| Hot100 / 自定义及在线题单 | 插件“题库 → 题单”，或 `:Leet lists`（先用 `:Leet` 登录） |

完整键位见[快捷键参考](docs/keymaps.md)。

## 配置架构与修改入口

```text
init.lua
  → config.options → config.keymaps → config.autocmds
  → config.lazy → 导入 lua/plugins/ 下的插件规格
```

| 职责 | 文件 |
|---|---|
| 显示、缩进、剪贴板、Neovide 参数 | `lua/config/options.lua` |
| 通用键位、Tab/Enter 调度 | `lua/config/keymaps.lua` |
| 光标恢复、输入法、文件同步 | `lua/config/autocmds.lua` |
| 状态栏字符数缓存 | `lua/config/statusline.lua` |
| 插件管理器引导与导入 | `lua/config/lazy.lua` |
| 主题 / UI、查找、大纲、拖尾 | `lua/plugins/theme.lua` / `ui.lua` |
| 括号、环绕、自动保存、格式化、snippets 加载 | `lua/plugins/editing.lua` |
| Treesitter 与括号层级配色 | `lua/plugins/syntax.lua` |
| Mason、通用 LSP 与补全 / Java 客户端 | `lua/plugins/lsp.lua` / `java.lua` |
| Markdown 渲染、图片与 callout 补全 | `lua/plugins/markdown.lua` |
| 数学与 callout 片段定义 / 刷题 | `lua/snippets/markdown.lua` / `lua/plugins/leetcode.lua` |
| 题单界面 / Hot100 官方题号 | `lua/config/leetcode_lists.lua` / `leetcode_hot100.lua` |
| Java/Python/Go/Rust 测试、结果树与输出 | `lua/plugins/testing.lua` |

全局行为在 `config/`，插件配置在 `plugins/`；插件专用键位也可能定义在对应插件文件中，不全在 `keymaps.lua`。

## 详细文档

| 文档 | 内容 |
|---|---|
| [架构与编辑器行为](docs/architecture.md) | 完整目录、插件职责与加载方式、主题、自动保存、状态栏、输入法 |
| [完整快捷键](docs/keymaps.md) | 通用编辑、补全、窗口、导航、大纲、LSP、环绕操作 |
| [LSP、Java、格式化与测试](docs/languages.md) | 服务器、Java 项目与重构、格式化器、neotest 依赖与限制 |
| [Markdown 渲染与图片](docs/markdown.md) | 渲染开关、依赖、图片诊断、兼容处理与远程下载风险 |
| [数学 snippets 与 callouts](docs/snippets.md) | 触发词、自动展开、数学模式门控、callout 输入；不是 `.tex` 工程配置 |
| [LeetCode 刷题](docs/leetcode.md) | 国内站点、默认语言、登录、缓存、Hot100 题单与按题号打开 |

## 管理与维护

- `:Lazy`：查看插件状态；`:Mason`：管理语言服务器；`:checkhealth`：诊断环境。
- `:Lazy sync`：安装、更新和清理插件，会改动锁文件；`:TSUpdate`：更新语法解析器。
- `lazy-lock.json` 记录插件版本；按锁文件恢复已安装插件版本使用 `:Lazy restore`。
- 修改 Lua 配置后重启 Neovim。不要把 `:source $MYVIMRC` 当作完整重载：Lua 模块会缓存，事件与插件也有自己的状态。
- 当前行为包含**自动写盘**，不只是持久化撤销；开关在 `lua/plugins/editing.lua`。Markdown 允许自动下载远程图片，阅读不可信文档时留意网络请求。

### 本次整理与配置控制

- 按选择移除 Vim 练习游戏；其他现有功能保留。
- Conform 替换旧的 clang-format 插件；保留 `<leader>cF` 文件/选区格式化及项目样式优先策略，不新增保存时格式化。
- neotest 仅接入 Java/Python/Go/Rust；复用现有 Treesitter/plenary，新增 nio 与四个适配器，不添加 DAP。Rust runner 安装在 `~/.cargo/bin/cargo-nextest`，Java JUnit runner 位于 Neovim 数据目录。
- 光标拖尾只把 `lua/plugins/ui.lua` 的 `time_interval` 调为 `10`；原动力学参数不变，改回 `17` 可恢复原刷新间隔。
- 主题只保留定制配色与主题选择，省略与插件默认值相同的样式选项；Markdown 移除未安装补全插件的浮窗忽略项，保留图片下载/JPEG/callout 的兼容处理。
- Snacks、Aerial、which-key、括号层级配色、自动保存、LuaSnip、Java 与刷题功能保留；未额外添加 Gitsigns、mini.ai 或 TODO 插件。
- 增减功能直接编辑 `lua/plugins/` 中对应规格；删除插件时一并清理键位、依赖和文档。确认后用 `:Lazy clean` 清理不再引用的安装目录，不必清空整个 Neovim 数据目录。

备份仓库：`~/Documents/GitHub/cachyos-config/`。Neovim 权威源为
`configs/apps/nvim/.config/nvim/`，`configs/home/.config/nvim/` 是生成镜像，
路径清单由 `configs/apps/nvim/paths` 与 `manifests/home-paths.txt` 管理。
只同步 Neovim 时应保持两份目录一致，包括 `docs/`、`lua/`、`lazy-lock.json`
与 `maven-settings.xml`，不要包含 LeetCode Cookie 缓存。
