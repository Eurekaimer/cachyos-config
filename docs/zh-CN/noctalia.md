# Noctalia

[English](../en/noctalia.md)

当前桌面外壳是原生 `/usr/bin/noctalia`，2026-10-10 实测版本
`v5.2.1 (5.2.1-1-dirty)`，不是已淘汰的 QuickShell `noctalia-shell` UI。
它在 Niri 之上提供顶栏、启动器、控制中心、通知、配色集成与会话界面；
本次迁移不调整 UI 设计。

`configs/apps/noctalia/` 为权威快照源：

+ `.config/noctalia/config.toml` 与 `widgets.toml`：原生底层配置。
+ `.local/state/noctalia/settings.toml`：GUI 保存的覆盖，优先于底层值；
  当前采集状态包括 UI scale 1.25、圆角比例 1.35、控制中心 full 侧栏。
+ `.local/share/noctalia/plugins/storage-gb/`：本地 `storage_gb` 插件。

`configs/home/` 是生成副本。`restore-user.sh` 复制部署，**不是软链接或自动同步**；
GUI 修改不会自动更新 Git。确认设置已保存后运行 `./scripts/capture.sh`，
再 `./scripts/audit.sh` 检查后发布。GUI 覆盖应单独保留，不直接合并到底层配置。
历史记录、缓存、凭据及其他私有运行状态不纳管。

原生命令：

```bash
noctalia msg status
noctalia msg config-reload
noctalia msg panel-toggle launcher
noctalia msg session lock
noctalia msg wallpaper-get
noctalia msg wallpaper-set ~/Pictures/Wallpapers/project_mifeng.png
```

Niri 的 `Super+Shift+L` 转发到 `noctalia msg session lock`。
不要启动 `qs -c noctalia-shell`，也不要从旧备份回填 `settings.json`、
`colors.json`、旧 QML 插件/配色目录或旧 `config.toml`。
Stage 6 不再回填 Noctalia 配置。profile 显式请求原生 `noctalia`，
不再请求旧 `noctalia-shell`/`noctalia-qs`；已安装系统包与 CachyOS meta 包不改动。
