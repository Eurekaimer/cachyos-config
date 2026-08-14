# campus-login：校园网认证直连脚本（南开 netauth）

来源：[EurekaimerOS/modules/home/applications/web.nix](https://github.com/Eurekaimer/EurekaimerOS)。

校园网认证页通常会被 Clash/mihomo 系统代理劫持导致打不开。本脚本清空代理
环境变量、用独立临时 Chrome profile 强制直连，打开南开校园网认证页
`https://netauth.nankai.edu.cn/`，不污染日常浏览器 profile。

## 安装

```bash
./scripts/install-campus-login.sh
```

需要已安装 `google-chrome-stable`、`google-chrome` 或 `chromium`（缺浏览器时
脚本会提示）。安装后直接运行：

```bash
campus-login
```

认证窗口使用 `/tmp/chrome-campus-login` 作为临时 profile，可用
`CAMPUS_CHROME_PROFILE` 环境变量覆盖。如需自定义安装目录，可用
`CAMPUS_BIN_DIR`。

## 卸载

```bash
modules/campus-login/uninstall.sh
```
