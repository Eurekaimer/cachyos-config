# 可选用户脚本

以下三个与机器绑定的脚本刻意不进通用快照恢复（`restore-all.sh`），因为不是
每台机器都需要。每个脚本单独安装；每个模块自带 `uninstall.sh`。

| 脚本 | 用途 | 安装 | 卸载 |
| --- | --- | --- | --- |
| `campus-login` | 隔离临时 Chrome profile 直连打开南开校园网认证页，绕过 Clash/mihomo 代理劫持 | `./scripts/install-campus-login.sh` | `modules/campus-login/uninstall.sh` |
| `docker-ass` | 管理 ANI-RSS + qBittorrent 容器栈并打开 Web 界面 | `./scripts/install-docker-anirss.sh` | `modules/docker-anirss/uninstall.sh` |
| `komari-call` | 从 GitHub 用 cargo 构建 KOMABELIKA 终端聊天程序并链接到 `~/.local/bin` | `./scripts/install-komari-call.sh` | `modules/komari-call/uninstall.sh` |

所有安装脚本支持 `--dry-run` 预览而不改动机器。安装产物在 `~/.local/bin`；
替换前旧版本备份到 `~/.local/state/cachyos-config/module-backups/`。

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
docker 守护进程不可达时自动走 `sg docker`，非 docker 组登录会话也能用。

## komari-call

`cargo install --git https://github.com/Eurekaimer/KOMABELIKA.git --locked
--force komari-call`，再把 `~/.local/bin/komari-call` 链接到
`~/.cargo/bin/komari-call`。需要 Rust 工具链（CachyOS：`sudo pacman -S rust`
或 rustup）。首次构建需要几分钟。
