# 输入法与桌面集成

[English](../en/input-desktop.md)

Fcitx5 中日输入法配置位于 `configs/home/.config/fcitx5/`。GTK 3/4、Qt、XDG 用户目录、MIME 关联以及白名单中的 Clash Verge 自启动项一并纳管。

## 中英/日英输入锁

仓库通过两个 Fcitx5 输入法组保证 `Super+R` 始终是双态切换，而不会进入中、英、日三语循环：

| 模式 | Fcitx5 组 | `Super+R` 切换范围 |
|---|---|---|
| 中英（默认） | `Default` | 英文键盘 / 拼音 |
| 日英 | `Japanese` | 英文键盘 / Mozc |

`Super+Shift+R` 调用 `~/.local/bin/fcitx5-toggle-japanese`，在两个组之间切换并显示“当前模式：中英”或“当前模式：日英”通知。脚本不维护额外状态文件；当前 Fcitx5 组是唯一状态源，未知组会回退到 `Default`。

恢复依赖如下：

+ `packages/pacman-explicit.txt` 包含官方仓库包 `fcitx5-mozc`。
+ `manifests/home-paths.txt` 纳管切组脚本；`restore-user.sh` 会将其恢复到 `~/.local/bin/` 并保留执行权限。
+ `configs/home/.config/niri/cfg/keybinds.kdl` 保留原有 `Super+R`，并新增 `Super+Shift+R`。

恢复后重新登录 niri，或在当前会话中重启 Fcitx5，再验证组切换：

```bash
fcitx5 -rd --replace
fcitx5-remote -m mozc
fcitx5-remote -g Default && fcitx5-remote -q
~/.local/bin/fcitx5-toggle-japanese && fcitx5-remote -q
~/.local/bin/fcitx5-toggle-japanese && fcitx5-remote -q
```

Addon 查询应输出 `mozc`，三个组查询结果应依次为 `Default`、`Japanese`、`Default`。最终还需在文本框中分别验证 `Super+R` 的英/中与英/日双态输入，并验证 `Super+Shift+R` 的模式通知。

桌面应用约定如下：

+ Nautilus 是主要图形文件管理器，也是 `Super+E` 的目标。
+ Thunar 仍保留安装，但不绑定 `Super+E`。
+ 图片默认用 imv 打开。
+ Markdown 使用仓库中的 `neovim-markdown.desktop` 启动器。
+ 壁纸从 `configs/home/Pictures/Wallpapers/` 恢复。

二进制 dconf 数据库不会直接复制；`dconf dump` 的文本结果保存为 `configs/dconf/user.ini`，由用户恢复脚本载入，便于跨机器审阅与恢复。
