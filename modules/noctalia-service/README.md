# noctalia-service：用 systemd 托管状态栏与壁纸

原生 Noctalia（`/usr/bin/noctalia`，v5）同时绘制状态栏、壁纸和面板。它原本由
niri 的 `spawn-at-startup "noctalia"` 拉起，**没有任何进程监管**：一旦段错误退出，
状态栏、面板、壁纸会同时消失，只能手开终端再起一次（本机 v5.5.0 曾在打开控制中心
时 SIGSEGV 崩过一次）。

本模块把 Noctalia 交给 systemd user 单元托管，`Restart=always` + `RestartSec=2`
让它在崩溃后约 2 秒自动重生。

## 安装

```bash
./scripts/module.sh install noctalia-service
```

安装会：投放 `~/.config/systemd/user/noctalia.service`，覆盖前备份到
`~/.local/state/cachyos-config/module-backups/noctalia.service`（同名只保留一份），
然后 `daemon-reload` + `enable --now`，并校验服务确实处于 active。

若 `~/.config/niri/cfg/autostart.kdl` 里还留着 `spawn-at-startup "noctalia"`，
安装器会打印警告——不删那行，重新登录会同时被 niri 和 systemd 各拉起一个实例。

## 使用

```bash
pgrep -cx noctalia                                  # 期望恰好 1
systemctl --user show -p MainPID -p NRestarts --value noctalia.service
systemctl --user restart noctalia.service           # 手动重启（等价于 Mod+CTRL+Shift+R）
niri msg layers | grep -E 'noctalia-(bar-main|wallpaper)'
```

`Mod+CTRL+Shift+R` 绑定到同一条 `systemctl --user restart noctalia.service`，
见 `configs/apps/niri/.config/niri/cfg/keybinds.kdl`。

## 单元设计取舍

- `Type=simple` 而不是包内模板 `/usr/share/noctalia/assets/noctalia.service` 的
  `Type=notify`：notify 的 readiness 若没送达，会在 `TimeoutStartSec`(90s) 后被判定
  启动失败并进入重启循环；`noctalia` 不加 `-d` 就是前台运行，`simple` 零依赖。
- 不设 `StartLimitIntervalSec`，保留默认 5 次/10s 上限：真出现启动失败风暴时由 systemd
  停止重试，而不是无限重启烧 CPU；止血用 `systemctl --user stop noctalia.service`。
- 不写 `After=niri.service`：`graphical-session.target` 已经保证合成器就绪，且 systemd
  user 环境里已有 `WAYLAND_DISPLAY`、`NIRI_SOCKET`。

## 崩溃后取证

```bash
journalctl --user -b -u noctalia.service --no-pager | tail -40
tail -60 ~/.cache/noctalia/noctalia.log
coredumpctl list | grep noctalia
```

崩溃栈当前无符号（`libLLVM.so` 缺 build-id），不要据此改配置；先把日志里崩溃前最后一条
`[panel]`/`[texcache]`/`[plugins]` 记录留存再上报 `noctalia-dev/noctalia`。

## 卸载

```bash
./scripts/module.sh uninstall noctalia-service   # disable --now + 删除单元
```

卸载后 Noctalia 不再自启，需要时手工 `noctalia &` 或把 `spawn-at-startup` 加回 niri。
