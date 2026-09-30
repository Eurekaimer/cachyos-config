# Neovim 配置

以 **Neovim 0.12 原生 LSP 与补全**为核心，使用 lazy.nvim 管理插件。Snacks 提供文件树、查找和终端；Kanagawa 提供主题；Markdown 渲染、Java 和刷题工具按需加载。

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
| LSP 格式化 / clang-format | `<leader>cf` / `<leader>cF` |
| 当前文件关键词补全或 snippet 前进 / 后退 | `<Tab>` / `<S-Tab>` |
| 跳出 `()` / `[]` / `{}` | `<C-Tab>`（终端备用：`<M-l>`） |
| Markdown 渲染 / 图片开关 | `<leader>mr` / `<leader>mi` |

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
| 主题 / UI、查找、大纲、动画 | `lua/plugins/theme.lua` / `ui.lua` |
| 括号、环绕、自动保存、格式化、snippets 加载 | `lua/plugins/editing.lua` |
| Treesitter 与括号层级配色 | `lua/plugins/syntax.lua` |
| Mason、通用 LSP 与补全 / Java 客户端 | `lua/plugins/lsp.lua` / `java.lua` |
| Markdown 渲染、图片与 callout 补全 | `lua/plugins/markdown.lua` |
| 数学与 callout 片段定义 / 刷题 | `lua/snippets/markdown.lua` / `lua/plugins/leetcode.lua` |

全局行为在 `config/`，插件配置在 `plugins/`；插件专用键位也可能定义在对应插件文件中，不全在 `keymaps.lua`。

## 详细文档

| 文档 | 内容 |
|---|---|
| [架构与编辑器行为](docs/architecture.md) | 完整目录、插件职责与加载方式、主题、自动保存、状态栏、输入法 |
| [完整快捷键](docs/keymaps.md) | 通用编辑、补全、窗口、导航、大纲、LSP、环绕操作 |
| [LSP、Java 与格式化](docs/languages.md) | 服务器列表、Java 项目与重构、两种格式化路径 |
| [Markdown 渲染与图片](docs/markdown.md) | 渲染开关、依赖、图片诊断、兼容处理与远程下载风险 |
| [数学 snippets 与 callouts](docs/snippets.md) | 触发词、自动展开、数学模式门控、callout 输入；不是 `.tex` 工程配置 |
| [LeetCode 刷题](docs/leetcode.md) | 国内站点、默认语言、登录、缓存与命令 |

## 管理与维护

- `:Lazy`：查看插件状态；`:Mason`：管理语言服务器；`:checkhealth`：诊断环境。
- `:Lazy sync`：安装、更新和清理插件，会改动锁文件；`:TSUpdate`：更新语法解析器。
- `lazy-lock.json` 记录插件版本；按锁文件恢复已安装插件版本使用 `:Lazy restore`。
- 修改 Lua 配置后重启 Neovim。不要把 `:source $MYVIMRC` 当作完整重载：Lua 模块会缓存，事件与插件也有自己的状态。
- 当前行为包含**自动写盘**，不只是持久化撤销；开关在 `lua/plugins/editing.lua`。Markdown 允许自动下载远程图片，阅读不可信文档时留意网络请求。

备份镜像：`~/Documents/GitHub/cachyos-config/configs/home/.config/nvim/`；该路径由 `cachyos-config/manifests/home-paths.txt` 管理。同步时保留整个目录，包括 `docs/`、`lua/` 与 `lazy-lock.json`，不要包含 LeetCode Cookie 缓存。
