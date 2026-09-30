# 可选用户脚本

与机器绑定的辅助脚本刻意不进通用快照恢复（`restore-all.sh`），因为不是每台
机器都需要。它们现在都是**模块**：每个位于 `modules/<名字>/`，含 `install.sh`、
`uninstall.sh`、`README.md` 与 `installed-check`，统一通过唯一入口
`scripts/module.sh` 驱动：

```bash
./scripts/module.sh list                        # 列出全部模块与安装状态
./scripts/module.sh status komari-call          # 查看各判定路径是否存在
./scripts/module.sh install komari-call         # 安装；加 --dry-run 只预览
./scripts/module.sh uninstall komari-call       # 卸载
```

| 模块 | 用途 | 安装 | 卸载 |
| --- | --- | --- | --- |
| `bili-live-hime` | 启动 `~/Projects/bili-live-hime` 的发布版构建（B 站直播姬替代：取推流地址/流密钥、改直播间、看弹幕） | `./scripts/module.sh install bili-live-hime` | `./scripts/module.sh uninstall bili-live-hime` |
| `campus-login` | 隔离临时 Chrome profile 直连打开南开校园网认证页，绕过 Clash/mihomo 代理劫持 | `./scripts/module.sh install campus-login` | `./scripts/module.sh uninstall campus-login` |
| `docker-anirss` | 管理 ANI-RSS + qBittorrent 容器栈并打开 Web 界面 | `./scripts/module.sh install docker-anirss` | `./scripts/module.sh uninstall docker-anirss` |
| `komari-call` | 从 GitHub 用 cargo 构建 KOMABELIKA 终端聊天程序并链接到 `~/.local/bin` | `./scripts/module.sh install komari-call` | `./scripts/module.sh uninstall komari-call` |
| `koreader` | 修复 AUR `koreader-bin` 的两个桌面缺陷并复原权威键位配置 | `./scripts/module.sh install koreader` | `./scripts/module.sh uninstall koreader` |
| `sioyek-ecdict` | Sioyek 离线英汉查词插件 | `./scripts/module.sh install sioyek-ecdict` | `./scripts/module.sh uninstall sioyek-ecdict` |
| `touchpad-boot-recovery` | Lenovo 82XF I2C 触摸板开机自恢复：开机后触摸板仍未注册时一次性重绑 `i2c_designware.0`（间歇性故障应对，非内核根因修复） | `./scripts/module.sh install touchpad-boot-recovery` | `./scripts/module.sh uninstall touchpad-boot-recovery` |

所有命令支持 `--dry-run` 预览而不改动机器。用户脚本安装产物在
`~/.local/bin`；`touchpad-boot-recovery` 以 root 安装
`/usr/local/sbin/touchpad-boot-recovery` 与
`/etc/systemd/system/touchpad-boot-recovery.service`。替换前旧版本备份到
`~/.local/state/cachyos-config/module-backups/`。

## bili-live-hime

把 `~/Projects/bili-live-hime`（可用 `BILI_LIVE_HIME_DIR` 覆盖）的发布版构建
封装成 `bili-live-hime` 命令：安装器按需 `git clone`、`npm install`、
`npm run tauri build`，只有缺什么才补什么。日常用 `bili-live-hime` 启动，
拉取上游更新后用 `bili-live-hime --rebuild` 重建。推流侧与 OBS 的配合、
被排除的凭据路径见 [B 站直播（bili-live-hime + OBS）](bili-live-hime.md)。

## campus-login

校园网认证页通常被 Clash/mihomo 系统代理劫持而打不开。脚本清空全部代理环境
变量，用 `--proxy-server=direct://` 的临时 Chrome profile（
`/tmp/chrome-campus-login`，可用 `CAMPUS_CHROME_PROFILE` 覆盖）打开
`https://netauth.nankai.edu.cn/`。

需要 `google-chrome-stable`、`google-chrome` 或 `chromium`。若打开后仍连不上，
检查 Clash 是否开着 TUN 模式：TUN 在网络层劫持流量，Chrome 参数无法绕过。

## docker-ass

`docker compose -f ~/Projects/ASS/docker-compose.yml`（可用
`ANI_RSS_COMPOSE_FILE` 覆盖）的封装，管理 ANI-RSS + qBittorrent 栈：
`start`（默认）、`qbit`、`status`、`stop`、`restart`、`logs`、`update`。
docker 守护进程不可达时自动改用 `sudo -g docker -u "$USER"`，非 docker 组登录会话也能用。

## komari-call

`cargo install --git https://github.com/Eurekaimer/KOMABELIKA.git --locked
--force komari-call`，再把 `~/.local/bin/komari-call` 链接到
`~/.cargo/bin/komari-call`。需要 Rust 工具链（CachyOS：`sudo pacman -S rust`
或 rustup）。首次构建需要几分钟。

## koreader

修复 AUR `koreader-bin` 的两个桌面缺陷——`/usr/lib/koreader/frontend/device.lua`
里的启动设备探测崩溃与 `apps/reader/modules/readerfooter.lua` 里的 PDF 页脚
崩溃——并把 `Eurekaimer/koreader-keystream-config` 的权威键位配置复原到
`~/.config/koreader/`。`uninstall` 把系统 Lua 文件还原为上游原版，不动用户
配置。详见 [KOReader](koreader.md) 与 `modules/koreader/README.md`。

## sioyek-ecdict

把仓库内置的离线英汉查词插件安装进当前用户的原生 Sioyek 配置，并附带一个
常驻 user service 保持 ECDICT 词典热启动。`uninstall` 移除服务与该插件写入的
Sioyek 键位绑定，保留项目目录与词典数据。详见
[Sioyek ECDICT](sioyek-ecdict.md)。

## touchpad-boot-recovery

Lenovo 82XF I2C 触摸板在部分开机时无法注册（`irq 27: nobody cared` →
`i2c_designware.0: controller timed out` → 探测 `-110`）的限定设备应对：
oneshot 服务开机后最多等 10 秒，触摸板仍未注册时一次性重绑
`i2c_designware.0` 并确认输入设备重新出现。这是间歇性故障的持久应对，
**不是内核根因修复**；现象细节、上游报告与边界见
[触摸板开机自恢复](touchpad-boot-recovery.md)。
