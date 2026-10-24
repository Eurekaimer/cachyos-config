# 配置位置与恢复策略

[English](../en/configuration.md)

本文从功能出发，索引实时位置、仓库快照和恢复边界。所有表格都按第一列的
英文名称或路径字母序排列，因此知道软件名时不需要扫描无关内容。真正决定采集
范围的来源仍然是 `manifests/` 下的白名单。

## 用户层

配置只在 `configs/apps/<应用>/` 下编写一次，目录结构镜像该应用拥有的、相对
`$HOME` 的路径。`configs/home/` 是**生成物**：由
`scripts/sync-configs.sh --to-snapshot` 从这些目录重建；
`scripts/restore-user.sh` 只读生成的安装树，因此 `configs/home/` 永不手改。
`manifests/home-paths.txt` 同时由 `configs/apps/*/paths` 生成。
`configs/dconf/user.ini` 是可移植文本导出，不是 dconf 二进制数据库。

| 应用 | 目录 | 拥有的路径 |
| --- | --- | --- |
| AniRSS | `configs/apps/ani-rss/` | `Projects/ASS/config/{ani,config}.v2.json` |
| CachyOS Hello | `configs/apps/cachyos-hello/` | `.config/cachyos-hello.json` |
| Clash Verge | `configs/apps/clash-verge/` | 自启动项、全局 `Script.js` |
| Fastfetch | `configs/apps/fastfetch/` | `.config/fastfetch/` |
| Fcitx5 | `configs/apps/fcitx5/` | `.config/fcitx5/`、`fcitx5-toggle-japanese` |
| Fontconfig | `configs/apps/fontconfig/` | `.config/fontconfig/` |
| Git | `configs/apps/git/` | `.gitconfig` |
| Go-musicfox | `configs/apps/go-musicfox/` | `.config/go-musicfox/` |
| GTK | `configs/apps/gtk/` | `.config/gtk-3.0/` |
| Kitty | `configs/apps/kitty/` | `.config/kitty/` |
| KOReader | `configs/apps/koreader/` | `.config/koreader/` |
| Micro | `configs/apps/micro/` | 设置与配色（不含 `syntax/`） |
| MIME 默认 | `configs/apps/mimeapps/` | `.config/mimeapps.list` |
| MPV | `configs/apps/mpv/` | `.config/mpv/` |
| Niri | `configs/apps/niri/` | `.config/niri/`、niri 辅助脚本、热键文本 |
| Noctalia | `configs/apps/noctalia/` | 原生 `.config/noctalia/`、`.local/state/noctalia/settings.toml`、`.local/share/noctalia/plugins/storage-gb/` |
| Neovim | `configs/apps/nvim/` | `.config/nvim/`、Markdown 桌面项 |
| OBS Studio | `configs/apps/obs-studio/` | `.config/obs-studio/`（不含 `service.json`） |
| OMP | `configs/apps/omp/` | `.omp/agent/config.yml`、`.omp/agent/models.yml`、`.omp/agent/themes/*.json` |
| Pi（pi coding agent） | `configs/apps/pi/` | `.pi/agent/settings.json`、`.pi/agent/models-store.json`、`.pi/agent/npm/package.json` |
| Qt | `configs/apps/qt/` | `.config/QtProject.conf` |
| Shell | `configs/apps/shell/` | `.zshrc`、`.zshenv`、`.bashrc`、`.bash_profile`、`.bash_logout` |
| Sioyek | `configs/apps/sioyek/` | `.local/bin/sioyek` |
| Starship | `configs/apps/starship/` | `.config/starship.toml` |
| Thunar | `configs/apps/thunar/` | `.config/Thunar/uca.xml` |
| Timewarrior | `configs/apps/timewarrior/` | `.config/timewarrior/` 配置与扩展 |
| Wallpapers | `configs/apps/wallpapers/` | `Pictures/Wallpapers/` |
| WeChat | `configs/apps/wechat/` | `wechat.desktop` |
| XDG 用户目录 | `configs/apps/xdg-user-dirs/` | `.config/user-dirs.{dirs,locale}` |
| Yazi | `configs/apps/yazi/` | `.config/yazi/` |

每个应用目录下的 `paths` 文件声明它拥有的、相对 `$HOME` 的路径；采集与恢复都以
该清单为准。各应用的改动要点见 `docs/agents/MEMORY.md`，数据流见
`docs/agents/ARCHITECTURE.md`。

| 功能 | 当前实际位置 | 仓库位置 |
| --- | --- | --- |
| AniRSS（追番 RSS） | `~/Projects/ASS/config/` 下的 `ani.v2.json`、`config.v2.json` | `configs/home/Projects/ASS/config/`；下载器密码/API Key/登录密码/实例 UUID 从公开快照移除 |
| Autostart（自动启动） | `~/.config/autostart/` 下的白名单文件 | `configs/home/.config/autostart/` |
| Bash | `~/.bashrc`、`~/.bash_profile`、`~/.bash_logout` | `configs/home/` |
| CachyOS Hello | `~/.config/cachyos-hello.json` | `configs/home/.config/cachyos-hello.json` |
| Dconf | `~/.config/dconf/user` 二进制数据库 | `configs/dconf/user.ini` 文本导出 |
| Docker helper | `~/.local/bin/docker-ass` | 不入快照；用 `scripts/module.sh install docker-anirss` 单独安装 |
| Fastfetch | `~/.config/fastfetch/` | `configs/home/.config/fastfetch/` |
| Fcitx5 | `~/.config/fcitx5/` | `configs/home/.config/fcitx5/` |
| Fontconfig | `~/.config/fontconfig/` | `configs/home/.config/fontconfig/` |
| Git | `~/.gitconfig` | `configs/home/.gitconfig`；公开快照移除邮箱 |
| Go-musicfox | `~/.config/go-musicfox/config.toml` | `configs/home/.config/go-musicfox/` |
| GTK | `~/.config/gtk-3.0/`、`~/.config/gtk-4.0/` | `configs/home/.config/` |
| Kitty | `~/.config/kitty/` | `configs/home/.config/kitty/` |
| Micro | `~/.config/micro/settings.json`、`~/.config/micro/colorschemes/` | `configs/home/.config/micro/` |
| MIME defaults（默认应用） | `~/.config/mimeapps.list` | `configs/home/.config/mimeapps.list` |
| KOReader | `~/.config/koreader/` | `configs/home/.config/koreader/`（剔除运行态） |
| MPV | `~/.config/mpv/` | `configs/home/.config/mpv/` |
| Neovim | `~/.config/nvim/`、Neovim Markdown desktop entry | `configs/home/.config/nvim/`、`configs/home/.local/share/applications/neovim-markdown.desktop` |
| Niri | `~/.config/niri/` | `configs/home/.config/niri/` |
| Niri helpers（辅助脚本） | `~/.local/bin/niri-hotkeys-zh`、`~/.local/bin/niri-stack-column`、快捷键文本 | `configs/home/.local/bin/`、`configs/home/.local/share/niri/` |
| Noctalia | `~/.config/noctalia/`、`~/.local/state/noctalia/settings.toml`、`~/.local/share/noctalia/plugins/storage-gb/` | `configs/home/` 下对应路径；GUI 覆盖优先于底层配置，历史/缓存/私有状态不纳管 |
| OBS Studio | `~/.config/obs-studio/`（`global.ini`、`user.ini`、`basic/scenes/`、`basic/profiles/`、`plugin_manager/modules.json`） | `configs/home/.config/obs-studio/`；`service.json`（推流密钥）发布前删除，日志与 profiler 数据不入快照 |
| OMP（Oh My Pi 配置） | `~/.omp/agent/config.yml`、`~/.omp/agent/models.yml`、`~/.omp/agent/themes/*.json` | `configs/home/.omp/agent/` 下对应路径；运行态不入，`models.yml` 的密钥必须是环境变量引用 |
| Pi（pi coding agent） | `~/.pi/agent/settings.json`、`~/.pi/agent/models-store.json`、`~/.pi/agent/npm/package.json` | `configs/home/.pi/agent/` 下对应路径；`auth.json`、会话记录与 `node_modules/` 不纳管，`settings.json` 会剥掉 `deviceId` |
| Qt | `~/.config/QtProject.conf` | `configs/home/.config/QtProject.conf`；最近路径元数据会被移除 |
| Starship | `~/.config/starship.toml` | `configs/home/.config/starship.toml` |
| Thunar | `~/.config/Thunar/uca.xml` | `configs/home/.config/Thunar/uca.xml` |
| Wallpapers（壁纸） | `~/Pictures/Wallpapers/` | `configs/home/Pictures/Wallpapers/` |
| XDG user directories（用户目录） | `~/.config/user-dirs.dirs`、`~/.config/user-dirs.locale` | `configs/home/.config/` |
| Zsh | `~/.zshrc`、`~/.zshenv` | `configs/home/.zshrc`、`configs/home/.zshenv`；导出变量里的凭据值会被清空 |

用户层恢复入口：

```bash
./scripts/restore-user.sh --dry-run
./scripts/restore-user.sh
```

## 系统可移植层

`configs/system/portable/` 镜像经过选择、可以在另一套已评审 CachyOS 安装上应用的
`/etc` 文件。

| 功能 | 位置 |
| --- | --- |
| Console and locale（控制台与语言） | `/etc/locale.conf`、`/etc/locale.gen`、`/etc/vconsole.conf` |
| DDC/CI | `/etc/modules-load.d/i2c-dev.conf`；运行工具为 `ddcutil` |
| Environment（全局环境） | `/etc/environment` |
| Initramfs | `/etc/mkinitcpio.conf` |
| Libvirt network（默认网络） | `/etc/libvirt/qemu/networks/default.xml` |
| Makepkg | `/etc/makepkg.conf` |
| Pacman | `/etc/pacman.conf` |
| SDDM | `/etc/sddm.conf.d/10-eurekaimer-theme.conf` |
| Snapper | `/etc/snapper/configs/root`、`/etc/conf.d/snapper` |
| UFW | `/etc/default/ufw`、`/etc/ufw/ufw.conf`、`user.rules`、`user6.rules` |
| X11 keyboard（键盘） | `/etc/X11/xorg.conf.d/00-keyboard.conf` |

系统层恢复入口：

```bash
./scripts/restore-system.sh --dry-run
./scripts/restore-system.sh
```

复制后，恢复脚本会重新加载 systemd、生成 locale 并重建 initramfs。

## 硬件/主机层

这些文件保存在 `configs/system/hardware/`，默认恢复流程不会应用。

| 功能 | 位置 | 风险 |
| --- | --- | --- |
| Filesystem table（文件系统表） | `/etc/fstab` | 包含磁盘 UUID、挂载点和 Btrfs 子卷 |
| Hostname（主机名） | `/etc/hostname` | 包含主机身份 |

只有确认目标机器具有相同磁盘、子卷、挂载点和预期主机身份，并与
`state/hardware/{lsblk,findmnt,lspci}.txt` 对照后，才可以使用
`--with-hardware`。

## 仅供比较层

| 参考项 | 位置 | 恢复行为 |
| --- | --- | --- |
| Hardware inventory（硬件清单） | `state/hardware/` | 只供比较，不作为配置复制 |
| Pacman mirror list（镜像列表） | `configs/system/reference/etc/pacman.d/mirrorlist` | 与位置和时间相关，永不自动恢复 |

## 软件与服务

`packages/` 分为"安装输入"与"采集产物"两类。第一列是实际路径，按路径字母序排列。

| 清单 | 角色 | 内容 |
| --- | --- | --- |
| `packages/profiles/full.txt` | **安装输入** | 当前工作站档：NVIDIA 独显、游戏、容器、通讯、重型 IDE |
| `packages/profiles/minimal.txt` | **安装输入** | ThinkPad T480 级档：Intel 核显、无游戏/容器、中英精简 TeX |
| `packages/inventory/pacman-explicit.txt` | 采集产物 | 当前显式安装且来自已配置仓库的软件 |
| `packages/inventory/aur-explicit.txt` | 采集产物 | 当前显式 AUR 或外部软件 |
| `packages/services/system.txt` | 采集产物 | 已启用系统服务 |
| `packages/services/user.txt` | 采集产物 | 已启用用户服务 |
| `packages/toolchains/rustup.txt` | 采集产物 | Rust 工具链 |
| `packages/toolchains/bun.txt` | 采集产物 | Bun 全局工具，包括 Oh My Pi Agent |
| `packages/required-extra.txt` | **安装输入** | 托管配置或恢复脚本自身依赖的软件 |

只有 `profiles/` 与 `required-extra.txt` 是安装输入；`inventory/`、`services/`、
`toolchains/` 记录采集机器当时的实际状态。用 `scripts/profile.sh use NAME`
选择档位，用 `scripts/profile.sh diff full minimal` 查看两档差异。

### Clash Verge 国内直连

托管文件
`~/.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles/Script.js`
是全局扩展脚本：B 站网页、视频、图片和 API 域名及 `GEOSITE,cn` 优先直连，
缺少中国 IP 直连规则时补充兜底，保留订阅其余规则和海外节点选择。
订阅更新不会覆盖该脚本，切换订阅也会应用。

采集和恢复只管理这个文件，不覆盖整个 Clash 目录。恢复前退出 Clash Verge，
恢复后重新打开应用以生成生效配置。须使用「规则模式」，「全局模式」会绕过这些规则。
订阅和凭据需要单独恢复。

## 明确不进入公开仓库

SSH/GPG 密钥、浏览器目录、Clash profiles、NetworkManager connections、
`~/.omp` 运行状态（agent.db、logs、install-id、sessions）、Cookie、登录数据库、
历史、日志和缓存必须通过密码管理器或加密备份单独迁移，不是本公开仓库的恢复输入。
`~/.omp` 中可入库的仅限 `agent/config.yml`、`agent/models.yml`（API 密钥只写
环境变量名，绝不写明文）和 `agent/themes/*.json`；其余任何 `.omp` 内容均被
`audit.sh` 拒绝。
同理，`~/.pi` 可入库的仅限 `agent/settings.json`、`agent/models-store.json` 与
`agent/npm/package.json`；`agent/auth.json`（含在线 OAuth 令牌与 API 密钥）、
`agent/sessions/` 会话记录、`agent/npm/node_modules/` 一律排除，`settings.json`
中的 `deviceId` 会被剥掉，其余任何 `.pi` 内容均被 `audit.sh` 拒绝。
