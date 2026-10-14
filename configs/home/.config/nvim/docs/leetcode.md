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
| `:Leet lists` | 打开插件内的题单页面，与“题库 → 题单”入口相同 |
| `:Leet run` / `:Leet submit` | 运行 / 提交当前题目 |
| `:Leet cookie update` | 输入或更新 Cookie |
| `:Leet cache update` | 更新本地题库缓存 |

Cookie 是登录凭据，不要提交到仓库或写入文档。

## 题库内的题单

重启 Neovim 后执行 `:Leet`，等待登录完成。在“题库 / Problems”页面按 `l`
进入“题单”，或执行 `:Leet lists`。原先独立的 `:LeetHot100` 已整合到此入口。

| 按键 | 作用 |
|---|---|
| `h` | 打开内置 Hot100 |
| `n` | 粘贴网页题号创建题单，数字题号可用空格或逗号分隔 |
| `f` | 导入题号文本文件，每行一个题号或逗号分隔 |
| `u` | 导入力扣题单或学习计划链接 |
| `r` | 选择已导入的在线题单，重新获取并更新题号 |
| `x` | 删除本地自定义题单，不影响力扣网站 |
| `q` | 返回题库页面 |

题单按网页题号 `frontend_id` 匹配插件缓存，不使用内部数据库 `id`，不复制题目内容。
正常条目复用插件的题目打开、运行、提交和完成状态；缓存缺少的题号仍显示，
标记“缺少缓存，暂无法打开”，选中时提示 `:Leet cache update`，不阻止打开其他题目。

在线导入支持 `https://leetcode.cn/problem-list/<slug>/`、
`https://leetcode.cn/studyplan/<slug>/` 和旧式 `/favorite/<slug>/` 链接。
使用网页客户端的 GraphQL 接口与插件当前登录凭据，不是保证长期稳定的开放 API。
私有题单需要当前账号有权限；请求异步分页，不抓取网页。在线题单保留来源链接，
刷新替换题号但保留本地名称，请求失败保留旧题单；刷新题单与更新题库缓存是不同操作。

自定义题单保存于 `~/.local/share/nvim/leetcode/problem_lists.json`，国内站与国际站分开；
同名保存会替换，内置 Hot100 不可覆盖或删除。内置题号来自
[官方热题 100 学习计划](https://leetcode.cn/studyplan/top-100-liked/)，保持获取时的顺序，
存放在 `lua/config/leetcode_hot100.lua`；需要在线更新时可导入该学习计划链接。
不修改插件安装目录、不保存第二份登录凭据、不同步网站学习计划进度。

