# Yazi 文件管理器

[English](../en/yazi.md)

Yazi 是工作站的终端文件管理器。配置文件 `~/.config/yazi/yazi.toml` 由本仓库通过 `manifests/home-paths.txt` 中的 `.config/yazi` 条目管理。

## PDF 多窗口打开

**问题**：Sioyek 是单实例应用。第一次打开 PDF 正常，后续打开时新进程只把路径发给已有实例后退出，已有实例不开新窗口——想开新窗口必须先关掉全部现有窗口。

**修复**：为 `application/pdf` 配置专用 opener，用 `--new-instance` 让每个文档获得独立进程与窗口：

```toml
[open]
rules = [
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

## Yazi 26 配置语法注意

升级到 Yazi 26 后，opener 配置有三处变化，沿用旧版写法会导致打开静默失败：

1. **opener 定义并入 `yazi.toml` 的 `[opener]` 段**，独立的 `openers.toml` 不再被读取。
2. **opener 的值必须是数组**：`name = [{ run = …, desc = … }]`，而不是对象形式。
3. **文件占位符改用 `%s1`（第 1 个文件）/ `%s`（spread 展开）**；`$@`、`$n` 已废弃。

## 预览

Yazi 的 PDF 预览依赖 `pdftoppm`（poppler 提供，已在包清单中）；其他文件类型的预览使用 Yazi 内置预载器或插件。预览图片缓存位于 `/tmp/yazi-<uid>/`。

## 恢复行为

`restore-user.sh` 会按 allowlist 恢复 `~/.config/yazi/`。恢复后 `yazi` 即可获得 PDF 多窗口打开行为，无需额外步骤。
