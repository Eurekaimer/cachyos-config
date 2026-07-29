# Niri 窗口管理器

[English](../en/niri.md)

Niri 是本工作站的 Wayland 合成器和窗口管理器，快照位于 `configs/home/.config/niri/`：

+ `config.kdl`：顶层 include。
+ `cfg/input.kdl`、`cfg/display.kdl`：输入与输出。
+ `cfg/layout.kdl`、`cfg/animation.kdl`、`cfg/rules.kdl`：布局、动画和窗口规则。
+ `cfg/keybinds.kdl`：键盘工作流。
+ `cfg/autostart.kdl`：会话启动项。
+ `cfg/misc.kdl`：环境变量，包括端口 `7897` 的本地 Clash 代理。

辅助脚本保存在 `configs/home/.local/bin/`。代理配置同时设置大小写 HTTP(S)、SOCKS 和 no-proxy 变量，使 Chromium/Electron 与命令行工具获得一致环境；仓库不保存 Clash 订阅、节点或凭据。

修改后执行：

```bash
niri validate
niri msg action load-config-file
```

环境变量变化后还应重启已运行的应用，因为现有进程不会追溯继承新环境。
