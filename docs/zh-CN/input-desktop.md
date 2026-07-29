# 输入法与桌面集成

[English](../en/input-desktop.md)

Fcitx5 中文输入法配置位于 `configs/home/.config/fcitx5/`。GTK 3/4、Qt、XDG 用户目录、MIME 关联以及白名单中的 Clash Verge 自启动项一并纳管。

桌面应用约定如下：

+ Nautilus 是主要图形文件管理器，也是 `Super+E` 的目标。
+ Thunar 仍保留安装，但不绑定 `Super+E`。
+ 图片默认用 imv 打开。
+ Markdown 使用仓库中的 `neovim-markdown.desktop` 启动器。
+ 壁纸从 `configs/home/Pictures/Wallpapers/` 恢复。

二进制 dconf 数据库不会直接复制；`dconf dump` 的文本结果保存为 `configs/dconf/user.ini`，由用户恢复脚本载入，便于跨机器审阅与恢复。
