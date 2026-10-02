# Yazi 文件管理器

[English](../en/yazi.md)

Yazi 是工作站的终端文件管理器。配置文件 `~/.config/yazi/yazi.toml` 由本仓库通过 `manifests/home-paths.txt` 中的 `.config/yazi` 条目管理。

## PDF 多窗口打开

**问题**：Sioyek 是单实例应用。第一次打开 PDF 正常，后续打开时新进程只把路径发给已有实例后退出，已有实例不开新窗口——想开新窗口必须先关掉全部现有窗口。

**修复**：为 `application/pdf` 配置专用 opener，用 `--new-instance` 让每个文档获得独立进程与窗口：

```toml
[open]
prepend_rules = [
  { use = "sioyek-new", mime = "application/pdf" },
]

[opener]
sioyek-new = [
  { run = '~/.local/bin/sioyek --new-instance %s1', desc = "Open with Sioyek (new window)", orphan = true },
]
```

opener 直接调用 `~/.local/bin/sioyek` 而不是 `sioyek`，因为这个包装脚本负责让 Sioyek 在本合成器下正常显示（设置 `QT_QPA_PLATFORM=xcb`）。由 niri 快捷键启动的程序（如 `Super+Y`）继承 niri 的 PATH，其中不含 `~/.local/bin`；裸命令会找到未包装的 `/usr/bin/sioyek`，其原生 Wayland 路径在 Qt 6.11 + niri 下首帧不提交、窗口不出现。

在 Yazi 中选中 PDF 按回车，即可同时打开多个 Sioyek 窗口，互不干扰；`orphan = true` 保证 Yazi 退出后窗口仍保留。

已知限制：`--new-instance` 对同一个文件重复回车会开重复窗口；Sioyek 的 `--new-window`（同实例新窗口、同文件复用）在 2.0.0.r1147 下发送给已有实例后实测无效。

## Markdown 多窗口打开

Markdown MIME 类型和 `*.{md,markdown,mdown,mkd}` 路径使用
`gtk-launch neovim-markdown %s`，直接调用已保存的 Kitty/Neovim 桌面启动器。
每次回车启动独立窗口，`orphan = true` 不阻塞 Yazi。修改配置后需重启 Yazi。
路径规则覆盖被识别为 `text/plain` 的 Markdown；不经 `xdg-open`，避免落到
普通文本默认程序 Kate。其他文本文件的默认程序保持不变。

## HTML 用 Chrome 打开

`text/html` 与 `*.{html,htm}` 走专用的 `chrome` opener：

```toml
[open]
prepend_rules = [
  { use = "chrome", mime = "text/html" },
  { use = "chrome", url = "*.{html,htm}" },
]

[opener]
chrome = [
  { run = 'google-chrome-stable --new-window %s1', desc = "Open in Chrome (new window)", orphan = true },
]
```

对课件/参考资料的 `.html` 按回车即开一个新 Chrome 窗口。裸 `xdg-open` 会走
`google-chrome.desktop`，它复用已有会话，看起来像没反应；`--new-window` 让每次
回车都有可见结果。MIME 规则同时覆盖被识别为 `text/plain` 的 HTML。

## 文件列表显示目录大小

**问题**：内置 `size` linemode 对目录显示的是条目数量，列表里看不到文件夹实际占多少空间；数量与大小混在同一列也参差不齐。

**修复**：`dirsize` 插件在后台测量当前页面里每个目录的大小，并按与内置文件夹 spotter（`<Tab>`）相同的方式写回文件列表。三个文件配合：

| 文件 | 作用 |
| --- | --- |
| `plugins/dirsize.yazi/main.lua` | fetcher：测量目录并发出 `FilesOp::Size` |
| `init.lua` | 插件 setup、`size` linemode 覆写、状态栏子项 |
| `yazi.toml` | `[plugin] fetchers` 规则 `{ url = "*/", run = "dirsize", prio = "low", group = "size" }` |

`size` linemode 只输出大小，列保持右对齐；尚未测出大小的目录留空，不再回退成数量。悬停目录的条目数追加在状态栏文件名之后：`2 items`、`1 item` 或 `empty`。

测量结果按目录缓存、以目录 mtime 失效；正在测量的目录会被抢占标记，并发的 fetcher 不会重复遍历同一棵树；用户切换目录时正在进行的测量会中止。不可读目录会被跳过，并在 `~/.local/state/yazi/yazi.log` 里只记录一行 `dirsize: cannot measure …`。数值是各文件长度之和（与 `sort_by = "size"` 及文件夹 spotter 相同），不是磁盘块占用。

## 更新后 Sioyek 缺少共享库

2026-09-07，`libmupdf` 从 1.28.0 升到 1.28.3 后，原有 AUR
`sioyek-git` 仍链接 `libmupdf.so.28.0`。用当前库重编译并重新安装
同一源码版本后恢复，无需回退库或创建兼容软链接。
完整更新使用 `paru -Syu`，之后运行已安装的 `checkrebuild`。
AUR 包即使没有版本更新，也可能因依赖 ABI 变化而需要重新编译。

## Yazi 26 配置语法注意

升级到 Yazi 26 后，opener 配置有三处变化，沿用旧版写法会导致打开静默失败：

1. **opener 定义并入 `yazi.toml` 的 `[opener]` 段**，独立的 `openers.toml` 不再被读取。
2. **opener 的值必须是数组**：`name = [{ run = …, desc = … }]`，而不是对象形式。
3. **文件占位符改用 `%s1`（第 1 个文件）/ `%s`（spread 展开）**；`$@`、`$n` 已废弃。

## 预览

Yazi 的 PDF 预览依赖 `pdftoppm`（poppler 提供，已在包清单中）；其他文件类型的预览使用 Yazi 内置预载器或插件。预览图片缓存位于 `/tmp/yazi-<uid>/`。

## 恢复行为

`restore-user.sh` 会按 allowlist 恢复 `~/.config/yazi/`。恢复后 `yazi` 即可获得 PDF 多窗口打开行为与目录大小插件，无需额外步骤。
