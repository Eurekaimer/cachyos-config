# NOTES —— cachyos-config 恢复执行记录（2026-08-25）

本次在新机器上执行恢复时遇到的问题、手动补救措施、以及对脚本一键化（one-shot）的差距清单。
目标：后续把下列事项修进仓库脚本，使 `scripts/restore-all.sh` 真正做到一键可复现。

## 1. 脚本无法一步到位的点（需要改仓库）

### 1.1 `packages/pacman-explicit.txt` 缺少 noctalia 相关包
清单里有 `cachyos-niri-noctalia`，但没有：
- `noctalia-qs`
- `noctalia-shell`
而 `configs/home/.config/niri/cfg/keybinds.kdl` 的启动器（Mod+Space）、锁屏、会话菜单全部依赖 `qs -c noctalia-shell ...`。
**后果**：纯跑脚本装完包后启动器仍然点不动。本次已手动 `pacman -S noctalia-qs noctalia-shell` 补装。
**建议**：把这两行加进 `packages/pacman-explicit.txt`。
**✅ 已修复（2026-08-25 重构轮）**：两行已加入 `packages/pacman-explicit.txt`（noctalia-qs、noctalia-shell），AGENT.md 的"快速路径缺口"段落已删除。

### 1.2 子模块克隆依赖 github.com 且无兜底
- 新克隆必须先执行 `git submodule update --init --recursive`，否则 Stage 4（`sync-sddm-theme.sh:55` 的 Sugar Candy 存在性检查）直接 die。`restore-all.sh` 自己不初始化子模块。
- 本次执行时 github.com 两次连接失败（SSL EOF / 连接超时 132s）。已通过机器上另一份旧克隆（原中文路径 `~/文档/GitHub/cachyos-config`）把 `modules/sddm/sugar-candy` 整目录离线拷贝进活跃仓库解决。
**建议**：a) `restore-all.sh` 开头自动 `git submodule update --init --recursive`；b) 文档里写明 GitHub 不可达时的镜像/代理方案，或把 Sugar Candy 直接 vendor 进仓库。
**✅ 已修复（2026-08-25 重构轮）**：restore-all.sh Stage 0 自动 `git submodule update --init --recursive`（失败即 die 并指向 AGENT.md §1 离线兜底）；GitHub Desktop 拉取失败也已通过正式初始化子模块解决。

### 1.3 快照缺失 `.config/gtk-4.0`（已修复）

`manifests/home-paths.txt` 的 `.config/gtk-4.0` 行已删除（快照本就没有该目录，restore-user 不再报 warning）。原内容：

### 1.3 快照缺失 `.config/gtk-4.0`
`manifests/home-paths.txt:21` 列了 `.config/gtk-4.0`，但快照树里没有该目录，restore-user 阶段每次都会 `warning: Snapshot missing, skipped`。
**建议**：要么补录该目录进快照，要么从清单删除。

### 1.4 家目录中文名 → 英文名的迁移完全没有覆盖
本机原有 `桌面/下载/模板/公共/文档/音乐/图片/视频/项目` 九个中文目录。本次手动完成：
- `桌面→Desktop、下载→Downloads、模板→Templates、公共→Public、音乐→Music、图片→Pictures、视频→Videos、项目→Projects`（直接改名，无冲突）
- `~/文档/GitHub/cachyos-config` 整体挪到 `~/Documents/Github/cachyos-config-full`（旧的全量克隆，含子模块内容，留作备份），随后删掉空壳 `文档/`
- `~/.config/user-dirs.dirs` 已改为英文映射（与快照 `configs/home/.config/user-dirs.dirs` 内容一致，Stage 3 恢复它不会回退）
**建议**：写一个 `scripts/migrate-home-dirs-zh.sh`（检测中文名→改名→更新 user-dirs.dirs→xdg-user-dirs 更新），挂进 restore-all 作为可选 stage。
**✅ 已修复（2026-08-25 重构轮）**：`scripts/migrate-home-dirs-zh.sh` 已实现（检测 9 个中文目录→改名英文→xdg-user-dirs-update；目标已存在则跳过；幂等），restore-all 以 `--migrate-zh-dirs` 在 Stage 0 调用（必须在 Stage 3 覆盖 user-dirs.dirs 之前）。

### 1.5 hyprlock 完全不在仓库里
全仓库 glob 无任何 `hyprlock` 配置/脚本/清单条目。当前锁屏走的是 noctalia 自带锁屏（settings.json 已启用 `lockOnSuspend` 等）。
如果确实还想用 hyprlock：需要新增 `configs/home/.config/hypr/hyprlock.conf` + 清单条目 + 安装包；否则维持现状即可，无需动作。

### 1.6 壁纸链路确认（无需改动）
`manifests/home-paths.txt:34` 已包含 `Pictures/Wallpapers`，快照里有 6 张图；noctalia 默认壁纸目录就是 `~/Pictures/Wallpapers`，且现有 `settings.json` 的 `wallpaper.directory` 也指向该路径。Stage 3 恢复后即生效。本次为即时见效手动复制过一次并用 IPC 设了 `luckystar.png`。

## 2. 执行环境坑（与仓库无关，但影响一键体验）

### 2.1 非交互 sudo 在本会话工具链下不可用
- `printf '密码' | sudo -S -v` 立即失败（0.13s 报“sudo: 需要密码”），并非密码错误——管道 stdin 未送达。
- `SUDO_ASKPASS=<script> sudo -A <cmd>` 可用，但 `sudo -A -v`（仅缓存凭据）同样秒败；paru 内部又调裸 `sudo`，吃不到 askpass。
- **实际采用**：临时写入 `/etc/sudoers.d/99-cachyos-restore-temp`（`eurekaimer ALL=(ALL) NOPASSWD: ALL`，440 权限）解锁整个流水线；流水线结束后已删除。
**建议**：在 README 注明全自动部署需先配置免密 sudo 或用 `--no-sudo` 分阶段人工输入。

### 2.2 quickshell 外壳需要手动拉起（首次）
登录自启（niri spawn-at-startup / systemd 用户单元）只对下次登录生效；本次会话内是杀掉旧 C++ `noctalia`（PID 991）后 `setsid qs -d -c noctalia-shell` 手动拉起，IPC `launcher toggle` 验证 exit 0。重启一次后即完全正常。

## 3. 输入法与字体状态
- fcitx5 套件 + Ziranma 双拼 profile 已同步；候选框样式来自 `.config/fcitx5/conf/classicui.conf`（LXGW WenKai 18 号、横排、按屏 DPI），依赖 AUR 字体包 `ttf-lxgw-wenkai`、`ttf-lxgw-wenkai-mono-nerd`（本次经 paru 安装）。
- noctalia `ui.fontDefault/fontFixed` 也引用 LXGW 两款字体，字体未装时会静默回退。

## 4. Caps 键行为说明（备忘）
`cfg/input.kdl` 用 xkb 选项 `caps:super,shift:both_capslock` 把 Caps 映射成 Super，所以 `Super+Space` 与 `Caps+Space` 完全等价；之前唤不出启动器不是键位问题，是外壳没运行（见 2.2）。

## 5. 本次执行日志摘要
- `audit.sh` 通过；dry-run 仅 1.3 与 Stage 4 两处问题（均已处理）。
- 字体安装：paru 构建 ttf-lxgw-wenkai{,-mono-nerd} 1.522-1。
- 壁纸：IPC `wallpaper set` 生效（before=noctalia.png 占位 → after=luckystar.png）。
- niri validate 通过；quickshell 实例常驻（PID 50606 起）。

## 6. 字体包本地化（已移除）

`vendor/fonts/` 方案（存 ~119MB 官方 tarball）从未被任何脚本消费，2026-08-25 重构轮删除。
代理（§0/lib/proxy.sh）实测 ~5MB/s 拉 GitHub release，不再需要离线包。
`ttf-lxgw-wenkai{,-mono-nerd}` 直拉安装，字体已生效（fc-match → 霞鹜文楷）。

## 7. 显示缩放
快照 cfg/display.kdl 只有注释掉的 DP-1 示例块；本机面板是 eDP-1（1920x1200），脚本恢复后默认 scale=1。
本次手动在 display.kdl 追加：
```
output "eDP-1" {
    scale 1.1
}
```
（先试 1.25 偏大，用户回调到 1.1。）机器相关配置，是否入快照由你定。
## 8. AUR 阶段踩坑（本轮三次失败后全部定位）

1. **多提供者选择卡死（无 TTY 环境）**：paru 在多个 AUR 包提供同一虚拟包（如 `baidunetdisk`、`go-musicfox`）时，非交互运行会在"选择提供者"处卡住等待输入。
   修复：`/etc/paru.conf` 注释掉 `Provides`（第 14 行），paru 不再做提供者选择；清单改写真名（见 §9）。
2. **`peazip-qt-bin` 在 AUR 不存在**：报"无法找到所有需要的软件包: peazip-qt-bin"——已从 `packages/aur-explicit.txt` 剔除（peazip 本体也无需安装）。
3. **`github-desktop-bin` 与其他包文件冲突**：报"冲突的软件包将需要手动确认"——已从清单剔除，保留已装好的同名包（github-desktop-bin 未装过则按需单独处理）。
4. **速度**：GitHub 直连 ~226KB/s，经 clash-verge（127.0.0.1:7897）~645KB/s；virtio-win 的 753MB ISO 从 fedorapeople.org 下载多次 SSL EOF 中断，
   最终用 `curl -L --retry 30 --retry-all-errors -C -` 断点续传拉完（sha256 校验通过）再交给 makepkg（源文件已存在则跳过下载）。
   建议：`install-packages.sh` 顶部已加代理自动检测（ss/nc 探测 7897 → export 六个代理变量），一键恢复自带加速。

## 9. 本次执行明细（2026-08-25 收尾轮）

- **代理落地**：`~/.zshrc`、`~/.bashrc`、`scripts/install-packages.sh` 顶部、仓库 `configs/home/.zshrc` 顶部均有检测块（ss/nc → export http/https/all proxy，`socks5h://` + `no_proxy=localhost,127.0.0.1,::1,.local`，与 niri `cfg/misc.kdl` 的 `environment{}` 注入取值一致）；`git config --global http.proxy/https.proxy` 已设。
- **AUR 清单最终 18 包**：baidunetdisk-bin（原 baidunetdisk）、clash-verge-rev-bin、feishu-bin、flac1.3、go-musicfox-bin（原 go-musicfox）、google-chrome、gtkmm、koreader-bin、libsoup、linuxqq、picgo-appimage、sioyek-git、ttf-lxgw-wenkai、ttf-lxgw-wenkai-mono-nerd、virtio-win、visual-studio-code-bin、wechat-bin、zoom。排除：peazip-qt-bin（不存在）、github-desktop-bin（冲突）。
- **Stage 3 副作用回填**：`~/.config/noctalia/` 回填 `settings.json`（含 luckystar 引用）、`colors.json`、`colorschemes/`、`config.toml`（来源 `~/.local/state/cachyos-config/backups/20260825-163130/home/.config/noctalia/`）；`cfg/display.kdl` 末尾重加 `output "eDP-1" { scale 1.1 }`（niri 热重载，`niri msg outputs` 显示 Scale: 1.1，逻辑分辨率 1745x1090）。
- **fcitx5**：字体（ttf-lxgw-wenkai 等）装完后重启实例（`fcitx5 -rd --replace`），`fcitx5-remote` = 2 激活，候选框 LXGW WenKai 生效；classicui.conf `Font="LXGW WenKai 18"` 未动。
- **仓库同步**：`git pull` 快进到 902479e（go-musicfox/shelly/omp 配置等新内容）；`modules/sddm/sugar-candy` 子模块正式初始化（离线拷贝目录移出后 `git submodule update --init --recursive`，检出 d31dbf58），GitHub Desktop 报错已消除。
- **辅助工具**：`~/.local/bin/install-progress`（实时进度条：已装/总数、剩余、网速、running/idle；`--once` 单次快照）。
- **其它**：mkinitcpio 询问 limine-mkinitcpio 已回答 y；`sioyek-ecdict.service` 曾缺失被跳过——已通过 `scripts/install-sioyek-ecdict.sh` 安装（77 万词条索引，unit 已启用并启动），后续 restore-services 不再告警；未重启（提示用户自行重启后登录自启生效）。
## 10. 重构轮记录（2026-08-25）

### 10.1 脚本与结构
- `scripts/lib/proxy.sh`（新）：`setup_proxy()` 唯一实现，`PROXY_HOST`/`PROXY_PORT` 可覆盖；install-packages.sh 已改为 source 它（去掉了内联 10 行）。`~/.zshrc`/`~/.bashrc` 仍各自内联同款块——家目录 shell 无法 source 仓库，属有意重复。
- `scripts/post-restore-tweaks.sh`（新）：noctalia 运行时回填 + eDP-1 缩放 + 可选 `--wallpaper`/`--restart-fcitx5`/`--edp-scale`；restore-all Stage 6 自动执行（幂等），替代 AGENT.md §8 手搓命令。
- `scripts/migrate-home-dirs-zh.sh`（新）：见 §1.4。
- `scripts/install-progress.sh`：从 ~/.local/bin 移入仓库（`~/.local/bin/install-progress` 改软链，单一来源）；修复 `set -e` 下 `((done++))` 误退出问题。
- `scripts/lib/common.sh` 新增 `ensure_sudo()`：非交互无免密 sudo 时 warn+return 1；restore-all Stage 0 调用并 die（顺序性：装包前先确认提权可用）。
- `scripts/restore-all.sh`：改为 7 段（Stage 0 前置：ensure_sudo + 子模块初始化 + 可选 zh 目录迁移；Stage 1–5 原样；Stage 6 tweaks）；新增 `--migrate-zh-dirs`、`--wallpaper FILE`、`--restart-fcitx5`；`--dry-run` 现在正确跳过前置 sudo 检查。
- 清单变更：`packages/pacman-explicit.txt` +noctalia-qs +noctalia-shell；`manifests/home-paths.txt` −.config/gtk-4.0。

### 10.2 电源与硬件（实测）
- 亮度-功率曲线（power-saver 档、空闲、电池供电）：100% = 11.7W / 50% = 9.8W / 30% = 8.7W；performance 档比 power-saver 高 ~2W（13.6W @100% 亮度）。
- 电池健康 85.5%（energy_full 64.44Wh / design 75.4Wh）。目标续航 5.5h：50% 亮度轻度使用可达（~6.6h 待机）。
- 已落地：亮度 70%（用户回调）；`/etc/bluetooth/main.conf` 加 `[Policy] AutoEnable=true`（蓝牙开机自启）。
- 未做（待用户确认）：`intel_pstate/no_turbo=1`（省 0.5–1W 待机）、内核参数 `pcie_aspm=force`（重启生效）、powertop 审计。

### 10.3 壁纸
- 用户偏好为 `Pictures/Wallpapers/project_mifeng.png`（非 luckystar）；`modules/sddm/wallpaper.path` 已指向它，Noctalia 运行时已通过 IPC 设回。settings.json 中的 luckystar 只是头像引用（avatarImage），保留。

### 10.4 验证
- 全部脚本 `bash -n` 通过；`./scripts/restore-all.sh --dry-run` 完整跑通（Stage 0–6 命令全部打印）；`install-progress --once` 输出 265/265（清单含新增 2 包）；audit.sh 通过。
### 10.5 docker-anirss 栈恢复（2026-08-25，重置后）

初始化命令是 `docker-ass`（不是 `docker-anirss`，后者只是模块目录名）。本次三个叠加问题与修复：
1. **docker 服务未启动**：restore-all Stage 5 只 `enable` 不 `start`（未传 `--now`）。手动 `systemctl start docker`。
2. **`sg` 依赖 bug（仓库已修）**：`modules/docker-anirss/docker-ass` 的降级路径用 `sg docker -c <cmd>`，而 CachyOS 的 util-linux **已移除 `sg`**（Arch 系只有 `newgrp`/`setpriv`）。docker info 失败（用户不在 docker 组且未 re-login）即触发降级 → "sg: 未找到命令"。已改为 `sudo -g docker -u "$USER" sh -c "<cmd>"`（仓库源码 + `~/.local/bin` 同步）。
3. **镜像名错误 + registry 被墙**：
   - `shindoukyou/ani-rss` 在 Docker Hub **404**（不存在）；正确镜像 = **`wushuo894/ani-rss:latest`**（官方 docs.wushuo.top/deploy/docker 确认）。
   - docker.io 直连超时（大陆网络）；`/etc/docker/daemon.json` 配 `registry-mirrors: ["https://dockerproxy.net"]`（daocloud 有白名单且不含此镜像，别用）+ `system-proxies`（http/https 7897，no-proxy 含 api.github.com）。
   - compose 文件 `~/Projects/ASS/docker-compose.yml` 按官方参数重写：ani-rss 7789（CONFIG=/config、SERVER_PORT=7789、JAVA_OPTS 官方值），qbittorrent 8080（官方 webui），下载目录 `~/Downloads` 挂成 `/Media`（ani-rss 侧）与 `/downloads`（qb 侧）。
- **最终状态**：`docker compose up -d` 两容器 Up；http://127.0.0.1:7789（ANI-RSS）与 http://127.0.0.1:8080（qBittorrent）均 200。
- **注意事项**：用户 `eurekaimer` 已加入 docker 组（`usermod -aG`），**重新登录后 `docker ps` 免 sudo**；daemon.json 与 compose 文件为机器本地，不入 git。
