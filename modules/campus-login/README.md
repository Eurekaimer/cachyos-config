# campus-login：校园网认证直连脚本（南开 netauth）

来源：[EurekaimerOS/modules/home/applications/web.nix](https://github.com/Eurekaimer/EurekaimerOS)。

校园网认证页常被 Clash/mihomo 的代理设置劫持而打不开。本脚本清空代理环境变量，
再用一份本次专用的临时 Zen profile 启动独立实例；启动前该 profile 只写入
`user_pref("network.proxy.type", 0);`，让认证页走浏览器直连，同时不读写日常
浏览器 profile。

## 前置条件

默认浏览器必须是 Zen：`xdg-settings get default-web-browser` 返回 `zen.desktop`，
且 `PATH` 中有 `zen-browser`（由 `zen-browser-bin` 提供）。`zen.desktop` 是 MIME
查询用的桌面条目名，不是软件包名。

任一条件不满足（默认浏览器是其他应用、查询失败或找不到 `zen-browser`）时，
脚本只输出“无法为当前默认浏览器创建直连隔离窗口”并以非零状态退出。它不会启动
其他浏览器、不会用普通 `xdg-open` 回退，也不会改动系统默认浏览器。

## 安装

```bash
./scripts/module.sh install campus-login
```

安装后直接运行：

```bash
campus-login
```

每次运行都用 `umask 077` 和 `mktemp -d` 在 `TMPDIR`（默认 `/tmp`）下创建本次
专用的私有目录，写入仅含一条代理设置的 `user.js`，然后执行：

```bash
zen-browser --no-remote --profile "$profile" --new-window 'https://netauth.nankai.edu.cn/'
```

脚本等待该实例退出，再由 EXIT trap 只删除本次目录。关闭认证窗口后临时 profile
随之消失；密码库、书签、扩展数据、浏览记录和日常 Zen profile 均不会被读取或
写入。`TMPDIR` 只决定临时目录的父路径。自定义安装目录可用 `CAMPUS_BIN_DIR`。

直连仅指浏览器自身的代理设置：脚本清空代理环境变量并关闭本次 profile 的代理，
但不会绕过 Clash 的 TUN（透明代理）模式，认证流量仍受系统路由约束。

## 卸载

```bash
./scripts/module.sh uninstall campus-login
```
