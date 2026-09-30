# 架构与编辑器行为

[返回首页](../README.md) · [完整快捷键](keymaps.md)

## 配置结构

```text
~/.config/nvim/
├── init.lua                    # 入口：leader、核心配置加载顺序
├── lazy-lock.json              # 插件版本锁定
├── README.md                   # 快速开始与文档索引
├── docs/                       # 架构、键位及各功能详细说明
└── lua/
    ├── config/
    │   ├── options.lua         # 编辑器选项、PATH、Neovide 参数、状态栏、主题兜底
    │   ├── statusline.lua      # 状态栏字符数片段（按 changedtick 缓存）
    │   ├── keymaps.lua         # 全局快捷键和 Tab/snippet 调度
    │   ├── autocmds.lua        # 自动命令、fcitx5、光标恢复
    │   └── lazy.lua            # lazy.nvim 引导与插件导入
    ├── plugins/
    │   ├── theme.lua           # Kanagawa Wave 与括号逐层配色
    │   ├── ui.lua              # Snacks、Aerial、which-key、smear-cursor
    │   ├── editing.lua         # mini.pairs/surround、auto-save、clang-format、LuaSnip、vim-be-good
    │   ├── syntax.lua          # Treesitter parsers、rainbow-delimiters
    │   ├── markdown.lua        # render-markdown、image.nvim
    │   ├── java.lua            # nvim-jdtls（eclipse.jdt.ls）
    │   ├── leetcode.lua        # leetcode.nvim（leetcode.cn 刷题面板）
    │   └── lsp.lua             # Mason、LSP、补全与 buffer-local 键位
    └── snippets/
        └── markdown.lua        # Markdown 专用 TeX 公式与 callout 片段
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
| [mini.pairs](https://github.com/nvim-mini/mini.pairs) | 括号/引号自动成对、`<BS>` 整对删除、`<CR>` 展开成块 | 常驻 |
| [auto-save.nvim](https://github.com/okuuva/auto-save.nvim) | 离开插入模式或文本变化后自动写盘，防止断电丢稿 | `InsertLeave`、`TextChanged` |
| [vim-clang-format](https://github.com/rhysd/vim-clang-format) | 调用系统 `clang-format` 格式化 C/C++/Java 等语言 | C 系与 Java 文件类型 |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | Markdown TeX 公式与 Obsidian callout snippets | 仅 `markdown` |
| [vim-repeat](https://github.com/tpope/vim-repeat) | 让 snippet 展开正确接入重复操作 | LuaSnip 依赖 |
| [rainbow-delimiters.nvim](https://github.com/HiPhish/rainbow-delimiters.nvim) | 按嵌套层级给 `()` `[]` `{}` 逐层着色 | 启动加载 |
| [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) | 标题、列表、表格、代码块等编辑器内渲染 | 仅 `markdown` |
| [image.nvim](https://github.com/3rd/image.nvim) | Markdown 内联图片及图片文件显示 | 仅 Kitty + `markdown` |
| [vim-be-good](https://github.com/ThePrimeagen/vim-be-good) | Vim 操作训练 | `:VimBeGood` 时加载 |
| [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls) | Java 的 eclipse.jdt.ls 客户端扩展（整理 import、提取变量/常量/方法、编译命令） | 仅 `java` |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP server 配置来源 | 按需 |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | 外部语言服务器管理 | LSP 依赖 |
| [mason-lspconfig.nvim](https://github.com/mason-org/mason-lspconfig.nvim) | Mason 与 Neovim LSP 对接 | LSP 依赖 |
| [leetcode.nvim](https://github.com/kawre/leetcode.nvim) | leetcode.cn 刷题面板：浏览、运行、提交题目 | `:Leet` 时加载 |
| [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) | leetcode.nvim 的路径与 curl 工具库 | leetcode.nvim 依赖 |
| [nui.nvim](https://github.com/MunifTanjim/nui.nvim) | leetcode.nvim 的弹窗/布局/输入框组件 | leetcode.nvim 依赖 |

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


## 撰写辅助

### 成对括号（mini.pairs）

| 输入 | 结果 |
|---|---|
| `(` `[` `{` | 同时插入配对的另一半，光标停在中间 |
| `"` `'` `` ` `` | 插入成对引号 |
| 已自动补全的闭括号处再输入闭括号 | 跳过而不重复插入 |
| `<BS>` 在空对中间 | 一次删除整对 |
| `<CR>` 在空对中间 | 展开为缩进块，光标停在块内 |

反斜杠后不触发（`\(` 保持原样）；单引号前是字母时也不触发，避免 `don't` 被拆开。
需要原样输入单个符号时用 `<C-v>` 前缀。

### 括号层级配色（rainbow-delimiters.nvim）

基于 Treesitter，按嵌套深度循环使用七种颜色，相邻两层的色相刻意拉开：

```text
第 1 层 RainbowDelimiterRed     第 5 层 RainbowDelimiterGreen
第 2 层 RainbowDelimiterYellow  第 6 层 RainbowDelimiterViolet
第 3 层 RainbowDelimiterBlue    第 7 层 RainbowDelimiterCyan
第 4 层 RainbowDelimiterOrange
```

颜色取自 Kanagawa palette（`waveRed`、`carpYellow`、`crystalBlue`、`roninYellow`、
`springGreen`、`oniViolet`、`waveAqua2`），定义在 `lua/plugins/theme.lua` 的
`overrides` 中，随主题切换一起生效。需要对应语言的 Treesitter 解析器；
`java`、`c`、`cpp` 已在 `syntax.lua` 的安装列表里。

需要临时关闭时：

```vim
:lua require("rainbow-delimiters").disable(0)   -- 当前缓冲区
:lua require("rainbow-delimiters").enable(0)
```

## 编辑器行为

### 显示与缩进

- 绝对行号 + 相对行号；
- 当前行高亮，符号列始终显示；
- `scrolloff=8`，长距离移动仍保留上下文；
- 4 空格缩进，Tab 转为空格；
- 显示 Tab、行尾空格和不换行空格；
- 全局状态栏，水平/垂直分屏默认在下方/右侧；
- 状态栏保留 Neovim 默认段（文件标志、诊断、搜索计数、ruler），末尾追加光标位置
  `Line:当前行/总行数` 与全文 `Chars:字符数`。

状态栏里的字符数走 `lua/config/statusline.lua`，不是直接写
`%{wordcount().chars}`：`wordcount()` 要扫描整个缓冲区，而 `%{}` 片段在**每次重绘**都会
重新求值——实测 100k 行文件每次击键 16 ms、200k 行 33 ms。该模块按 `changedtick`
缓存结果，因此光标移动、滚动这类不改变文本的重绘不产生开销；缓存值在每次文本变化
时失效，撤销、重做、`:edit!` 重新载入都会命中新值。缓冲区超过 1.5 MiB 时（与 Snacks
`bigfile` 判定一致）跳过计数，只保留 O(1) 的 `Line:` 段，避免在大文件里每次击键都付
扫描成本。

### 中文文本

- 使用软换行，不改变物理行；
- 在中文标点 `，。！？；：、` 处优先换行（由 Neovim 的 Unicode 折行处理，`'breakat'` 只接受 ASCII，未改）；
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
