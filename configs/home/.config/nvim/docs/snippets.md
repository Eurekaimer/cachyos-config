# Markdown 数学 snippets 与 callouts

[返回首页](../README.md) · [Markdown 渲染与图片](markdown.md)

这里只支持 **Markdown 中的 TeX 数学语法与 Obsidian callout 输入**，没有配置 `.tex` 工程、
VimTeX、texlab 或自动编译。片段定义集中在 `lua/snippets/markdown.lua`，触发词与选项移植自
Obsidian 的 LaTeX Suite 配置（`Math/.obsidian/plugins/obsidian-latex-suite/data.json`）：
原配置的 `m`（仅数学模式）对应 `in_math()` 门控，`A`（自动展开）对应该片段是否边打边展开。

当前共 154 条自动片段（含 `mk` / `dm`）与 28 条手动片段（7 条数学片段、
`aln` 和 20 条 callout）。`mk` / `dm` 输入后自动展开，`aln` 与 callout 按 `<Tab>` 展开。

#### 自动展开

输入触发词后立即展开，不需要按 Tab。纯字母触发词使用 `wordTrig=true`，不会替换较长单词内部的字符；`//`、`@a` 等标点触发词不受此词边界限制。

| 触发词 | 结果 | 光标位置 |
|---|---|---|
| `mk` | 行内 `$…$` | 公式内部 |
| `dm` | 块级 `$$` 数学环境 | 公式内部 |
| `aligned` | `aligned` 环境 | 环境内第一行 |
| `sum` | `\sum_{i=1}^{n}` | 下标 |
| `int` | `\int_{a}^{b}` | 下限 |
| `lim` | `\lim_{x \to 0}` | 变量 |
| `cases` | `cases` 分段函数 | 第一行 |
| `avg` | `\langle … \rangle` | 内容 |
| `@a` `@b` `@g` … | 对应希腊字母 | 字母之后 |

#### 手动展开

输入触发词后按 `<Tab>`：

| 触发词 | 模板 |
|---|---|
| `aln` | Markdown 块级公式内的 `aligned` 多行等式 |
| `align` | `align` 环境 |
| `mat` | 2×2 `bmatrix` |
| `scrf` | σ-代数 |
| `lr` | `\left( … \right)` |
| `par` | 偏导数 |
| `limt` | 极限 |
| `tayl` | Taylor 展开 |
| `callouts-<类型>` | 20 种 Obsidian callout |

展开后用 `<Tab>` 前进，`<S-Tab>` 后退。片段定义集中在 `lua/snippets/markdown.lua`。

#### 数学模式门控

绝大多数片段只在 `$…$` 或 `$$…$$` 内部触发：`in_math()` 扫描光标之前的所有行，按未转义的
`$$` 配对判断是否处于块级公式（可跨行），再在本行内按单个 `$` 的奇偶判断行内公式。
`mk` / `dm` 不受门控（它们正是用来创建数学环境的），在正文中打 `@a` 会保留字面量。

#### 自动展开与前缀冲突

自动片段在触发词打完后立即展开；若短触发词是长词的前缀，长词可能还没打完就被截断。
`priority` 只能选择同时匹配的片段，不能阻止短词提前展开。
当前 `scr` / `scrf`、`lim` / `limt` 存在这类冲突：长触发词无法自然逐字输入；
上面的手动片段表保留其定义，但要解决输入冲突，需要改名或将对应短词改为手动展开。

#### 常用触发词

| 类别 | 触发词 |
|---|---|
| 数学环境 | `mk` `dm`（自动）；`aln`（Tab）；`beg` `aligned` `pmat` `bmat` `cases` `matrix` |
| 希腊字母 | `@a` `@b` `@g` `@G` `@d` `@D` `@e` `@z` `@t` `@T` `@i` `@k` `@l` `@L` `@s` `@S` `@u` `@U` `@o` `@O` `@m` `@n` `@p` `@r` `@f` `@c` `@x` `@y`、`:e`、`:t` |
| 分数与幂 | `//` `bino` `sr` `cb` `rd` `ee` `invs` `conj` |
| 关系符号 | `**` `xx` `+-` `-+` `...` `->` `<->` `!>` `=>` `=<` `===` `!=` `>=` `<=` `>>` `<<` `sub=` `sup=` |
| 集合与字母表 | `inn` `notin` `emp` `sete` `RR` `CC` `QQ` `ZZ` `NN` `EE` `KK` `PP` `LL` `HH` `AA` |
| 分析 | `sum` `prod` `bigcup` `bigcap` `int` `dint` `oinf` `infi` `lim` `limt` `suplim` `inflim` `par` `ddt` `tayl` |
| 概率统计 | `measpace` `probspace` `scrf` `IID` `meato` `holder` |
| 括号 | `avg` `norm` `Norm` `ceil` `floor` `mod` `lr(` `lr[` `lr{` `lr|` |

展开后用 `<Tab>` 前进到下一个占位符，`<S-Tab>` 后退。

#### Obsidian callouts

`callouts-<类型>` 覆盖 20 种 callout，展开后光标停在正文行，该行已带 `> `：

```markdown
> [!todo] 第一章
> - [ ] 作业1
```

在正文行内按 `Enter` 自动续 `> `。当出现**空 `>` 行**（即只有引用符号、后面没有内容）时，
再按一次 `Enter` 会把整段连续空 `>` 行折叠为**一个空行**，光标落到下一行，callout 到此结束：

```markdown
> [!note] 标题
> 正文

下一段从这里开始
```

支持的 20 种类型：`note` `tip` `important` `warning` `question` `todo` `info` `success`
`danger` `failure` `bug` `example` `quote` `abstract` `summary` `tldr` `hint` `caution`
`attention` `cite`。

callout 的续行与折叠依赖 `'formatoptions'` 的 `r` 标志。Markdown 自带的 ftplugin 会执行
`formatoptions-=r`（实测为 `tcqjln`），`lua/config/autocmds.lua` 在 `FileType markdown` 时加回
`r`（最终 `tcqjlnr`）。折叠逻辑在 `lua/config/keymaps.lua`：`<CR>` 检测光标行是否为空白引用行，
是则调用 `collapse_quote_run()`；普通正文行仍走 mini.pairs 的成对展开。

`render-markdown.nvim` 的内置补全源同时提供 callout 类型：在引用行输入 `> [!` 会弹出
类型列表，`<Tab>` / `<S-Tab>` 选择、`<Enter>` 接受。补齐 `[` `!` 的编辑范围需要显式指定，
`lua/plugins/markdown.lua` 里的 `markdown_completions()` 负责给出该范围，并复用 mini.pairs
已插入的 `]`，因此结果为 `> [!NOTE]` 而不是嵌套或重复的方括号。
