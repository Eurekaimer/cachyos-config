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
| `:Leet run` / `:Leet submit` | 运行 / 提交当前题目 |
| `:Leet cookie update` | 输入或更新 Cookie |
| `:Leet cache update` | 更新本地题库缓存 |

Cookie 是登录凭据，不要提交到仓库或写入文档。
