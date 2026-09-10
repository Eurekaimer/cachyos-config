# Neovim 配置说明

这是一套以 **Neovim 0.12 原生能力**为核心的 Lua 配置，重点覆盖：

- Kanagawa Wave 彩色主题；
- Snacks 文件导航、查找、通知和启动页；
- Neovim 原生 LSP 与补全；
- Markdown 编辑器内渲染、Kitty 图片显示；
- Markdown 中的 TeX 数学公式 snippets；
- 终端与 Neovide 各自适配的光标动画；
- fcitx5 中文输入法状态自动切换。

`<leader>` 和 `<localleader>` 均为空格键。

## 快速开始

```bash
nvim
```

首次启动时 `lazy.nvim` 会安装插件，Mason 会安装已配置的语言服务器，Treesitter 会安装语法解析器。常用入口：

| 操作 | 按键或命令 |
|---|---|
| 智能查找 | `<leader><space>` |
| 文件树 | `<leader>e` |
| 查找文件 | `<leader>ff` |
| 全文搜索 | `<leader>fg` |
| 搜索全部快捷键 | `<leader>sk` |
| Markdown 渲染开关 | `<leader>mr` |
| Markdown 图片开关 | `<leader>mi` |
| 插件管理 | `:Lazy` |

## 环境要求

### 必需

- Neovim `>= 0.12`；
- Git；
- 支持真彩色的终端；
- Nerd Font（当前 Kitty 使用 `FantasqueSansM Nerd Font Mono`）。

### 按功能可选

| 依赖 | 用途 |
|---|---|
| Kitty `>= 0.28` | image.nvim 的 Kitty Graphics Protocol 后端 |
| ImageMagick | 图片读取、缩放和裁剪；配置使用 `magick_cli` processor |
| curl | 下载 Markdown 中的远程图片 |
| `fcitx5-remote` | 普通模式与插入模式间自动切换输入法 |
| `wl-copy` 或 `xclip` | 系统剪贴板集成 |
| LazyGit | `<leader>gg` Git 界面 |

当前机器已验证：Neovim 0.12.5、Kitty 0.48.2、ImageMagick 7 均可用。

## 配置结构

```text
~/.config/nvim/
├── init.lua                    # 入口：leader、核心配置加载顺序
├── lazy-lock.json              # 插件版本锁定
├── README.md                   # 本文档
└── lua/
    ├── config/
    │   ├── options.lua         # 编辑器选项、PATH、Neovide 参数、主题兜底
    │   ├── keymaps.lua         # 全局快捷键和 Tab/snippet 调度
    │   ├── autocmds.lua        # 自动命令、fcitx5、光标恢复
    │   └── lazy.lua            # lazy.nvim 引导与插件导入
    ├── plugins/
    │   ├── theme.lua           # Kanagawa Wave
    │   ├── ui.lua              # Snacks、which-key、smear-cursor
    │   ├── editing.lua         # mini.surround、auto-save、LuaSnip、vim-be-good
    │   ├── syntax.lua          # Treesitter parsers
    │   ├── markdown.lua        # render-markdown、image.nvim
    │   └── lsp.lua             # Mason、LSP、补全与 buffer-local 键位
    └── snippets/
        └── markdown.lua        # Markdown 专用 TeX 公式片段
```

加载顺序固定为：

```text
options → keymaps → autocmds → lazy.nvim → plugin specs
```

核心配置与插件配置分离；插件按职责拆分，Markdown snippets 独立存放，不与 `.tex` 工程配置混合。

## 插件一览

| 插件 | 职责 | 加载方式 |
|---|---|---|
| [lazy.nvim](https://github.com/folke/lazy.nvim) | 插件安装、懒加载、更新与锁定 | 启动引导 |
| [kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim) | Kanagawa Wave 主题 | 启动优先加载 |
| [snacks.nvim](https://github.com/folke/snacks.nvim) | dashboard、explorer、picker、通知、zen、bufdelete、LazyGit | 启动加载 |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | 中文快捷键分组提示 | `VeryLazy` |
| [aerial.nvim](https://github.com/stevearc/aerial.nvim) | 多级标题/代码大纲、跳转、Markdown 正文折叠 | `<leader>a` 或 Aerial 命令 |
| [smear-cursor.nvim](https://github.com/sphamba/smear-cursor.nvim) | 在终端中模拟 Neovide 光标拖尾 | `VeryLazy`；Neovide 内禁用 |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | 语法树、高亮及 Markdown 结构解析 | 启动加载 |
| [mini.surround](https://github.com/nvim-mini/mini.surround) | 添加、删除、替换环绕字符 | 常驻 |
| [auto-save.nvim](https://github.com/okuuva/auto-save.nvim) | 离开插入模式或文本变化后自动写盘，防止断电丢稿 | `InsertLeave`、`TextChanged` |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | Markdown TeX 公式 snippets | 仅 `markdown` |
| [vim-repeat](https://github.com/tpope/vim-repeat) | 让 snippet 展开正确接入重复操作 | LuaSnip 依赖 |
| [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) | 标题、列表、表格、代码块等编辑器内渲染 | 仅 `markdown` |
| [image.nvim](https://github.com/3rd/image.nvim) | Markdown 内联图片及图片文件显示 | 仅 Kitty + `markdown` |
| [vim-be-good](https://github.com/ThePrimeagen/vim-be-good) | Vim 操作训练 | `:VimBeGood` 时加载 |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP server 配置来源 | 按需 |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | 外部语言服务器管理 | LSP 依赖 |
| [mason-lspconfig.nvim](https://github.com/mason-org/mason-lspconfig.nvim) | Mason 与 Neovim LSP 对接 | LSP 依赖 |

## 主题与光标动画

### Kanagawa Wave

主题配置位于 `lua/plugins/theme.lua`：

- 默认变体：`kanagawa-wave`；
- 普通文本：`#dcd7ba`；
- 背景：`#1f1f28`；
- gutter 背景透明；
- 浮窗、补全菜单、分隔线和当前行使用统一的 Kanagawa UI 色；
- 插件加载失败时保留内置 `habamax`，避免无主题可用。

### 终端与 Neovide

两套动画不会同时运行：

- Kitty 等终端：启用 `smear-cursor.nvim`，使用偏快速、低弹性的拖尾；
- Neovide：禁用 smear-cursor，保留 Neovide 原生 ripple 光标和原生动画参数。

命令：

```vim
:SmearCursorToggle
```

## 完整快捷键

### 通用编辑

| 按键 | 模式 | 作用 |
|---|---|---|
| `jk` | 插入 | 返回普通模式 |
| `<C-s>` | 普通/插入/可视 | 保存并返回普通模式 |
| `<leader>s` | 普通 | 保存文件 |
| `<Esc>` | 普通 | 清除搜索高亮 |
| `L` | 普通/可视/操作符 | 跳到当前行末尾；覆盖 Vim 默认 `L` |

### 补全与 snippets

`<Tab>` 按以下优先级处理：

```text
补全菜单 → LuaSnip 展开/下一跳点 → Neovim 原生 snippet → 普通 Tab
```

| 按键 | 模式 | 作用 |
|---|---|---|
| `<Tab>` | 插入/选择 | 下一补全项、展开 snippet 或跳到下一占位符 |
| `<S-Tab>` | 插入/选择 | 上一补全项或返回上一占位符 |
| `<CR>` | 插入 | 补全菜单存在时确认，否则正常换行 |
| `<C-Space>` | 插入 | 手动触发 LSP 补全 |

### 窗口

| 按键 | 作用 |
|---|---|
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | 转到左/下/上/右窗口 |
| `<leader>wv` | 垂直分屏 |
| `<leader>ws` | 水平分屏 |
| `<leader>wd` | 关闭当前窗口 |
| `<leader>w=` | 等分窗口 |

### 缓冲区与文件

| 按键 | 作用 |
|---|---|
| `<leader>bn` / `<leader>bp` | 下一个/上一个缓冲区 |
| `<leader>bd` | 删除当前缓冲区但保留窗口布局 |
| `<leader>e` | 文件树 |
| `<leader>ff` | 查找文件 |
| `<leader>fb` | 查找缓冲区 |
| `<leader>fr` | 最近文件 |

### 搜索、导航与 UI

| 按键 | 作用 |
|---|---|
| `<leader><space>` | Snacks 智能查找 |
| `<leader>fg` | 全文搜索 |
| `<leader>fh` | 查找帮助 |
| `<leader>sd` | 全部诊断 |
| `<leader>sk` | 搜索快捷键 |
| `<leader>ss` | 当前文档符号 |
| `<leader>gg` | LazyGit |
| `<leader>z` | 专注模式 |
| `<leader>n` | 通知历史 |

### 标题与代码大纲（Aerial）

普通模式按 `<leader>a`（空格后按 `a`）打开右侧大纲并进入；再次按下关闭。
Markdown 默认展开所有层级，大纲折叠会同步收起正文中的整个章节（包括子标题及内容），不会删除文字。
其他语言仍可浏览代码符号，但不接管正文折叠。

以下按键仅在大纲窗口中生效：

| 按键 | 作用 |
|---|---|
| `j` / `k` | 向下/向上选择可见标题，包含不同层级 |
| `<Enter>` | 跳到所选标题并回到正文 |
| `p` | 正文滚动到所选标题，焦点留在大纲 |
| `h` / `l` | 收起/展开当前节点 |
| `zC` / `zO` | 递归收起/展开当前节点及全部子节点 |
| `za` / `zA` | 切换当前节点/递归切换 |
| `zM` / `zR` | 收起/展开整个大纲 |
| `q` | 关闭大纲 |
| `?` | 查看大纲快捷键 |

保留全局 `Ctrl-h/j/k/l` 窗口切换、`Ctrl-s` 保存和 `L` 行尾映射；
大纲是只读窗口，保存正文前先用 `Ctrl-h` 返回正文。
未采用上游示例的 `{` / `}` 标题跳转映射，避免覆盖原有段落移动。

### Markdown

| 按键 | 作用 |
|---|---|
| `<leader>mr` | 切换文本渲染 |
| `<leader>mi` | 切换图片显示；仅 Kitty 中可用 |

### LSP

这些键仅在 LSP 已附加的缓冲区生效。

| 按键 | 作用 |
|---|---|
| `gd` | 定义 |
| `gD` | 声明 |
| `gr` | 引用 |
| `gI` | 实现 |
| `gy` | 类型定义 |
| `K` | 悬停文档 |
| `<leader>ca` | 代码操作 |
| `<leader>cr` | 重命名符号 |
| `<leader>cf` | 异步格式化 |
| `<leader>cd` | 当前诊断浮窗 |
| `[d` / `]d` | 上一个/下一个诊断 |

### 可视模式

| 按键 | 作用 |
|---|---|
| `J` / `K` | 选区整体下移/上移并保持选中 |
| `<` / `>` | 减少/增加缩进并保持选中 |

### mini.surround

| 按键 | 作用 | 示例 |
|---|---|---|
| `sa` + 动作 + 字符 | 添加环绕 | `saiw"` 给单词加双引号 |
| `sd` + 字符 | 删除环绕 | `sd"` 删除双引号 |
| `sr` + 旧字符 + 新字符 | 替换环绕 | `sr"'` 将双引号改为单引号 |
| `sf` / `sF` | 向右/左查找环绕 |  |
| `sh` | 高亮环绕 |  |
| `sn` | 调整搜索行数 |  |

## Markdown 写作

### 文本渲染

打开 `.md` 文件时 `render-markdown.nvim` 自动启用。它使用 Treesitter 与 extmarks 美化标题、列表、任务框、引用、代码块和表格；源码没有被修改。

```vim
:RenderMarkdown toggle
:RenderMarkdown enable
:RenderMarkdown disable
```

### 图片显示

image.nvim 使用 Kitty Graphics Protocol：

- Markdown 中本地图片和远程图片均可显示；
- 图片最大宽度为窗口的 80%，最大高度为窗口的 40%；
- 图片在插入模式和编辑器失焦时保持显示；
- 不因临时浮窗自动清除，避免图片短暂出现后退化为 Markdown 链接；
- 直接打开 PNG、JPEG、GIF、WebP、AVIF 文件也会尝试显示。

示例：

```markdown
![本地图片](./images/example.png)
![远程图片](https://example.com/example.png)
```

诊断命令：

```vim
:ImageReport
```

限制：当前后端只在 Kitty 或兼容 Kitty Graphics Protocol 的终端内启用。Neovide 不实现该协议，所以 Neovide 中仍显示 Markdown 图片语法文本。

安全说明：配置允许下载远程图片；打开不可信 Markdown 时可能向远程服务器发起请求。如不需要远程图片，将 `download_remote_images` 改为 `false`。

### Markdown TeX 公式 snippets

这里只支持 **Markdown 中的 TeX 数学语法输入**，没有配置 `.tex` 工程、VimTeX、texlab 或自动编译。

#### 自动展开

输入触发词后立即展开，不需要按 Tab。`wordTrig=true`，只匹配独立单词，不会替换较长单词中的字符。

| 触发词 | 结果 | 光标位置 |
|---|---|---|
| `mk` | `$…$` | 两个 `$` 之间 |
| `dm` | 块级 `$$` 数学环境 | 中间空行 |

#### 手动展开

输入触发词后按 `<Tab>`：

| 触发词 | 模板 |
|---|---|
| `fr` | `\frac{分子}{分母}` |
| `sq` | `\sqrt{内容}` |
| `sum` | `\sum_{i=1}^{n}` |
| `int` | `\int_{a}^{b} f(x) \,\mathrm{d}x` |
| `lim` | `\lim_{x \to 0}` |
| `vec` | `\vec{v}` |
| `bf` | `\mathbf{x}` |
| `lr` | `\left( … \right)` |
| `mat` | 2×2 `bmatrix` |
| `cases` | 分段函数 `cases` |
| `aln` | Markdown 块级公式内的 `aligned` 多行等式 |

展开后用 `<Tab>` 前进，`<S-Tab>` 后退。片段定义集中在 `lua/snippets/markdown.lua`。

## 编辑器行为

### 显示与缩进

- 绝对行号 + 相对行号；
- 当前行高亮，符号列始终显示；
- `scrolloff=8`，长距离移动仍保留上下文；
- 4 空格缩进，Tab 转为空格；
- 显示 Tab、行尾空格和不换行空格；
- 全局状态栏，水平/垂直分屏默认在下方/右侧。

### 中文文本

- 使用软换行，不改变物理行；
- 在中文标点 `，。！？；：、` 处优先换行；
- 续行以 `↳` 标记；
- 如果存在 `fcitx5-remote`：退出插入模式切回英文，重新进入插入模式时恢复之前的中文状态。

### 搜索、撤销与文件同步

- 全小写搜索忽略大小写；出现大写字符时自动区分大小写；
- 持久化撤销，关闭 swapfile；
- 退出插入模式或文本变化后自动写盘（`auto-save.nvim`）：断电或窗口被强杀时最多丢失一次防抖窗口内的改动；
- 重新打开文件恢复上次光标位置；
- yank 后高亮 150 ms；
- 回到编辑器或离开终端后自动检测磁盘上的文件变化；
- 检测到 `wl-copy` 或 `xclip` 时启用系统剪贴板。

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

## 管理命令

| 命令 | 作用 |
|---|---|
| `:Lazy` | 插件状态与管理界面 |
| `:Lazy sync` | 安装缺失插件、更新并清理 |
| `:Mason` | 外部语言服务器管理 |
| `:TSUpdate` | 更新 Treesitter parser |
| `:RenderMarkdown toggle` | 切换 Markdown 文本渲染 |
| `:ImageReport` | 输出 image.nvim 环境、后端与图片状态 |
| `:SmearCursorToggle` | 切换终端光标动画 |
| `:VimBeGood` | 启动 Vim 操作训练 |
| `:checkhealth` | 检查 Neovim 环境 |

## 修改指南

| 需求 | 文件 |
|---|---|
| 修改基础选项 | `lua/config/options.lua` |
| 修改通用快捷键 | `lua/config/keymaps.lua` |
| 修改自动命令或输入法行为 | `lua/config/autocmds.lua` |
| 修改主题 | `lua/plugins/theme.lua` |
| 修改 UI、查找或光标动画 | `lua/plugins/ui.lua` |
| 修改 Markdown 渲染或图片 | `lua/plugins/markdown.lua` |
| 增删数学 snippets | `lua/snippets/markdown.lua` |
| 修改 parser 列表 | `lua/plugins/syntax.lua` |
| 修改 LSP server | `lua/plugins/lsp.lua` |

纯 Lua 改动可重启 Neovim，或执行：

```vim
:source $MYVIMRC
```

插件 spec 改动后执行 `:Lazy sync`。插件版本由 `lazy-lock.json` 锁定。

## 备份与恢复

本配置同时同步到：

```text
~/Documents/GitHub/cachyos-config/configs/home/.config/nvim/
```

该路径已列入 `cachyos-config/manifests/home-paths.txt`，会随 CachyOS 用户配置快照一起恢复。修改实时配置后，应同步整个 nvim 目录，包括 `README.md`、`lazy-lock.json`、`lua/plugins/` 和 `lua/snippets/`。
