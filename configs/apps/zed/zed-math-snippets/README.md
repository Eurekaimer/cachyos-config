# Zed Math Snippets

用一套快捷键在 Markdown、LaTeX、Typst 里输入同一套数学记号：`@a` → `\alpha` / `alpha`，`ff` → `\frac{}{}` / `frac(, )`。配置源是 8 个按数学模块拆分的 TOML，`generate.py` 生成三份 Zed snippets JSON。

## 目录

```text
zed-math-snippets/
├── modules/            # 唯一配置源（按知识模块拆分）
│   ├── greek.toml
│   ├── symbols.toml
│   ├── operators.toml
│   ├── algebra.toml
│   ├── calculus.toml
│   ├── linear_algebra.toml
│   ├── probability.toml
│   └── templates.toml
├── generate.py         # 标准库生成器（校验 + JSON + 安装）
├── dist/               # 本地生成结果（不跟踪，generate.py 重建）
└── README.md
```

安装目标是 `~/.config/zed/snippets/{markdown,latex,typst}.json`；不生成全局 `snippets.json`。

## 安装 / 更新

```bash
cd ~/Documents/GitHub/cachyos-config/configs/apps/zed/zed-math-snippets
python3 generate.py --install
```

- `--install` 会把 `dist/*.json` 复制到 `~/.config/zed/snippets/`；若已有同名文件，先备份到 `~/.config/zed/snippets-backup/`（每次覆盖，只保留一份；不放进被纳管的 snippets 目录）。
- Zed 监视该目录，保存后自动重载；用命令面板 `snippets: open folder` 可直接打开。
- 不需要改 `settings.json` / `keymap.json`。

语言文件对应关系：

| 文件 | Zed 语言 | 前提 |
|---|---|---|
| `markdown.json` | Markdown | 内置 |
| `latex.json` | LaTeX | 需在 `zed: extensions` 安装 **LaTeX** 扩展 |
| `typst.json` | Typst | 已装 Typst 扩展 |

## 模块与数量

| 模块 | 条数 | 内容 |
|---|---:|---|
| greek | 34 | 希腊字母（含大小写、变体） |
| symbols | 17 | 无穷、偏导、集合、数集 |
| operators | 12 | 常用运算符、关系、箭头 |
| algebra | 32 | 分数、根号、上下标、括号、accent |
| calculus | 14 | 极限、导数、积分、求和、连乘 |
| linear_algebra | 14 | 矩阵、向量、行列式、迹、内积 |
| probability | 9 | 测度/概率空间、期望、方差、协方差 |
| templates | 5 | 行内、行间、cases、align、env |
| **合计** | **137** | Markdown / LaTeX 各 137，Typst 135（缺 `array`、`beg`） |

## 快捷键速查

| 触发 | Markdown / LaTeX | Typst | 说明 |
|---|---|---|---|
| `mk` | `$…$` | `$…$` | 行内公式 |
| `dm` | `$$…$$` / `\[…\]` | `$ … $`（空白分行间） | 行间公式 |
| `@a` `@b` `@G` `@l` | `\alpha` `\beta` `\Gamma` `\lambda` | `alpha` `beta` `Gamma` `lambda` | 希腊字母 |
| `ff` | `\frac{}{}` | `frac(, )` | 分数 |
| `sq` | `\sqrt{}` | `sqrt()` | 根号 |
| `sum` | `\sum_{i=1}^{n}` | `sum_(i=1)^n` | 求和 |
| `prod` | `\prod_{i=1}^{n}` | `product_(i=1)^n` | 连乘 |
| `int` | `\int … \, dx` | `integral … dif x` | 积分 |
| `lim` | `\lim_{x \to \infty}` | `lim_(x -> oo)` | 极限 |
| `mat` | `pmatrix` 2×2 | `mat(1,2;3,4)` | 矩阵 |
| `cases` | `cases` 环境 | `cases(...)` | 分段函数 |
| `RR` `NN` `ZZ` | `\mathbb{R}` … | `bb(R)` … | 数集 |
| `->` `=>` | `\to` `\implies` | `arrow.r` `arrow.r.double.long` | 箭头 |

完整的 137 条见 `modules/*.toml`，每条都带中文说明。

## 修改流程

1. 编辑对应模块的 `[[snippet]]`：

   ```toml
   [[snippet]]
   prefix = "sq"              # 触发词，不能含空白，全局唯一
   description = "平方根"      # 补全菜单说明
   latex = '\sqrt{${1}}$0'    # Markdown 默认复用
   typst = 'sqrt(${1})$0'
   ```

   可选字段：`markdown`（覆盖 Markdown 输出）、`langs`（限制生效语言）。

2. 运行 `python3 generate.py --install`。
3. 若改了安装结果，再按“同步到 cachyos-config”一节更新仓库。

写法约定：

- body 里字面量 `$` 必须写 `\$`；占位符是 `${1}`、`${2:默认值}`、`$0`。
- 多行 body 用 TOML 多行字面量 `'''`，反斜杠不会被 TOML 转义。
- LaTeX 换行 `\\` 要写 4 个反斜杠：`\\\\`（snippet 解析器会把 `\\` 折叠成一个 `\`）。
- 输出 `\}` 会被解析器吞掉反斜杠，所以花括号用 `\lbrace` / `\rbrace`。
- 每条 body 都带 `$0`；生成器会校验这一点以及占位符语法。

## Zed 行为与限制

- **`@` 前缀可用**：本机 `1.26.2+stable` 的 `crates/editor/src/completions.rs` 已包含多词前缀匹配（`snippet_candidate_suffixes`、`match_start`），输入 `@a` 会整段匹配并替换，不会残留 `@`。
- **以标点结尾的前缀不会自动弹菜单**：`->`、`>=`、`lr(`、`sub=` 等需要先按 `ctrl-space`，再按 `tab` 接受。以字母/数字/`_` 结尾的前缀（`@a`、`ff`、`sum`、`cases`）会自动弹出。
- **Tab**：菜单打开时 `tab` 接受补全；snippet 展开后 `tab` 跳到下一个占位符，`shift-tab` 回退。
- **一个 snippet 只能有一个 prefix**：同一输出已去重，每条只保留一个触发词（例如分数只保留 `ff`）。
- **不支持**：LaTeX Suite 的正则触发、自动展开、数学环境感知；这些不在 Zed 原生 snippets 能力内。
- `latex.json` 在安装 LaTeX 扩展之前不会生效；装好后重新打开 `.tex` 文件即可。
- 若某条 snippet 不出现，先看 `~/.local/share/zed/logs/Zed.log` 是否有 `Invalid snippet`，再检查语言文件名。

## 同步到 cachyos-config

`configs/apps/zed/.config/zed/snippets/` 是唯一副本（没有 `configs/home/` 生成树）：

```bash
cd ~/Documents/GitHub/cachyos-config

# 1) 生成并安装到 ~/.config/zed/snippets/
python3 configs/apps/zed/zed-math-snippets/generate.py --install

# 2) 把生成的 JSON 收进仓库
./scripts/sync-configs.sh --to-snapshot

# 3) 自检
./scripts/audit.sh
```

确认新增路径无漂移：

```bash
./scripts/sync-configs.sh --check 2>&1 | grep -F '.config/zed/snippets'
# 期望无输出
```
