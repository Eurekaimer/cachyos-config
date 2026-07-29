# Noctalia Shell

[English](../en/noctalia.md)

Noctalia 在 Niri 之上提供顶栏、启动器、控制中心、通知、配色集成和会话界面。纳管快照位于 `configs/home/.config/noctalia/`：

+ `settings.json`：Shell 行为和模块设置。
+ `colors.json` 与 `colorschemes/`：视觉配色。
+ `plugins.json` 与 `plugins/`：插件选择和随附插件文件。

通过 `./scripts/restore-user.sh` 恢复。不要把自动备份或缓存目录加入 manifest。运行期间修改设置时，应先按 Noctalia 的正常方式重载或重启，确认配置文件已经保存为预期状态后再采集。
