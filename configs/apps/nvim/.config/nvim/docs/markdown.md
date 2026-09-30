# Markdown 渲染与图片

[返回首页](../README.md) · [数学 snippets 与 callouts](snippets.md)

配置入口：`lua/plugins/markdown.lua`。`<leader>mr` 切换文本渲染，`<leader>mi` 切换图片显示。图片功能需要 Kitty 与 ImageMagick，远程图片还需要 curl。

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
- 进入插入模式时暂时隐藏图片，退出插入模式后恢复；
- 浮窗覆盖图片时自动清理，编辑器失焦时隐藏；
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

远程图片由配置内的下载器替换 `image.nvim` 的默认实现：默认实现在 curl 的 stdout 关闭时就
写入缓存、从不检查退出码，并从异步回调里直接抛错，所以一次被截断的下载会让该 URL 永久
渲染失败。替换后按退出码判定成功，失败会删除临时文件、清理缓存并给出可读错误，重试仍可
成功；并发请求各用独立临时文件，不再互相覆盖。

同一个下载器还负责两件事：

- **瞬断重试与去重提示**：Markdown 集成在每次渲染 pass 都会对可视区内的远程图片重新请求，
  所以代理偶发 TLS 中断（curl 退出码 35/56）时，同一 URL 会反复触发失败通知，哪怕后续
  重试已成功、图片也已渲染。现在 curl 带 `--retry 3 --retry-delay 1 --retry-max-time 60
  --retry-all-errors` 自行重试瞬断，并且同一 URL 每次会话最多只提示一次失败。
- **带尾部数据的 JPEG**：`image.nvim` 的 `magic.lua` 只读文件最后两个字节判断 JPEG 结束标记
  （要求 `FF D9` 恰好位于 EOF），因此「JPEG 正常结束（`FF D9`）之后还附着少量数据」的图片
  ——QQ/微信等导出图的常见形态——会被判为"不是图片"而完全不渲染，尽管 ImageMagick、
  浏览器、Obsidian 都能正常解码。配置包装了 `magic.detect_format`：先走插件原逻辑
  （PNG/GIF/WebP 等行为不变），仅在其失败时才从文件末尾按 64 KB 分块倒序搜索 `FF D9`。
  截断下载因不含结束标记仍会被正确拒绝。上游同一问题的 PR（3rd/image.nvim#379）选择直接
  删除该校验，本配置的做法保留了截断防护。

限制：当前后端只在 Kitty 或兼容 Kitty Graphics Protocol 的终端内启用。Neovide 不实现该协议，所以 Neovide 中仍显示 Markdown 图片语法文本。

光标拖尾（smear-cursor）会留下隐藏浮窗，`window_overlap_clear_ft_ignore` 已把
`smear-cursor` 列为忽略项，否则这些浮窗会被当作遮挡窗口而跳过整张图片的渲染。

安全说明：配置允许下载远程图片；打开不可信 Markdown 时可能向远程服务器发起请求。如不需要远程图片，将 `download_remote_images` 改为 `false`。
