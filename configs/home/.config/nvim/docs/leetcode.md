# LeetCode 刷题

[返回首页](../README.md) · [Java 工具](languages.md#java)

依赖：curl；Java 编辑工具需要 JDK 21+。配置入口：`lua/plugins/leetcode.lua`。

`lua/plugins/leetcode.lua` 把 leetcode.nvim 指向国内站点，只在执行 `:Leet` 时加载。

| 配置 | 值 | 效果 |
|---|---|---|
| `lang` | `java` | 新题目默认用 Java 模板打开 |
| `cn.enabled` | `true` | 使用 `leetcode.cn` 而不是 `leetcode.com` |
| `cn.translator` | `true` | 插件自身界面文案显示为中文 |
| `cn.translate_problems` | `true` | 题目标题与描述使用中文 |
| `description.position` | `left` | 左侧题目描述、右侧代码 |
| `description.width` | `50%` | 初始左右等分；打开题目及终端尺寸变化后重新等分 |

`picker.provider` 保持未设置，由插件自行解析第一个可用 provider（顺序为
snacks-picker、fzf-lua、telescope、mini-picker）；本配置已有 Snacks，因此不再安装第二个
picker。

`lua/plugins/syntax.lua` 额外安装了 `html` 解析器：存在 `parser/html.so` 时
leetcode.nvim 用它格式化题目描述，否则退回纯文本。

登录由 `:Leet cookie update` 完成：把浏览器请求头里的 `Cookie` 粘进输入框，插件写到
`~/.cache/nvim/leetcode/cookie_cn`。本配置不保存任何 Cookie，该缓存目录也不入快照。

`cn.enabled` 决定缓存文件名：关闭时同一输入框写的是 `cookie`，而两个站点的会话不通用。

## 常用命令

| 命令 | 作用 |
|---|---|
| `:Leet` | 打开刷题面板 |
| `:Leet list` / `:Leet daily` | 选题 / 每日一题 |
| `:Leet lists` | 打开题库内题单管理页，包含内置 Hot100 |
| `:Leet run` / `:Leet submit` | 运行 / 提交当前题目 |
| `:Leet cookie update` | 输入或更新 Cookie |
| `:Leet cache update` | 更新本地题库缓存 |

Cookie 是登录凭据，不要提交到仓库或写入文档。

## 题库中的 Hot100 与题单

登录后，从主菜单按 `p` 进入「题库 / Problems」：

- 按 `h` 直接打开 **Hot100 (100)**，选题后沿用插件原生的题目描述与代码窗口。
- 按 `l` 打开「题单」页，其中也保留 Hot100；`n` 按题号新建，
  `f` 导入题号文件，`u` 导入在线题单，`r` 刷新在线题单，`x` 删除本地题单。

Hot100 内置于 `lua/config/leetcode_hot100.lua`，采用
[官方热题 100 学习计划](https://leetcode.cn/studyplan/top-100-liked/) 的网页题号。
选题按缓存的 `frontend_id` 匹配，不使用内部数据库 ID；不依赖用户先导入或创建题单。
缺少缓存的题号仍显示并提示 `:Leet cache update`，不会悄悄从题单消失。

自定义题单保存于 `~/.local/share/nvim/leetcode/problem_lists.json`，国内站与国际站分开；
内置 Hot100 不可覆盖或删除。在线导入支持国内站 `/problem-list/<slug>/`、
`/studyplan/<slug>/` 和旧式 `/favorite/<slug>/`，复用插件的登录凭据，
使用网页内部 GraphQL API，不保证接口长期稳定，也不同步网站学习进度。

## 左右等分与全屏

左侧为题目描述，右侧为代码。`lua/plugins/leetcode.lua` 在题目打开时及
`VimResized` 后，按这两个窗口可用列数重新计算描述窗宽度；全屏、退出全屏及
终端尺寸变化后仍保持等分。分隔线不计入两侧宽度；可用列数为奇数时最多相差一列。
不修改其他编辑窗口的全局分屏选项，也不修改插件安装目录。
