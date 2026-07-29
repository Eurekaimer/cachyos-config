# MPV 媒体栈

[English](../en/mpv.md)

`configs/home/.config/mpv/` 中的快照包含播放器选项、快捷键、profiles、字体、脚本选项和 Lua 脚本，包括 uosc 界面以及 thumbfast、autoload、autodeint、evafast、inputevent、memo 和 webtorrent 等辅助组件。

运行状态不是配置。`capture.sh` 会删除 `memo-history.log` 和 MPV 的 `cache/` 目录（包括 watch-later 条目），避免公开文件名与播放历史；`audit.sh` 会拒绝这些路径重新出现。

使用 `./scripts/restore-user.sh` 恢复。调整窗口行为后，应重启 MPV 再验证 Niri 堆叠，因为现有窗口会保留进程状态。
