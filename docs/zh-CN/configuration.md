# 配置位置与恢复策略

[English](../en/configuration.md)

`configs/apps/<应用>/` 是每条托管 `$HOME` 路径的唯一副本：目录结构镜像该应用
拥有的路径，`configs/apps/<应用>/paths` 声明具体有哪些。`manifests/home-paths.txt`
由这些声明生成，永不手改；当两者不一致、同一路径被两个应用声明、或生成副本
`configs/home/` 重新出现时，`scripts/audit.sh` 直接失败。`configs/dconf/user.ini`
是可移植文本导出，不是 dconf 二进制数据库。

采集写入应用目录，恢复从应用目录读出——中间没有生成层。

## 用户层

| 应用 | 目录 | 拥有的路径（相对 `$HOME`） |
| --- | --- | --- |
| AniRSS（追番 RSS） | `configs/apps/ani-rss/` | `Projects/ASS/config/{ani,config}.v2.json` |
| CachyOS Hello | `configs/apps/cachyos-hello/` | `.config/cachyos-hello.json` |
| Clash Verge | `configs/apps/clash-verge/` | `.config/autostart/Clash Verge.desktop`、`.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles/Script.js` |
| Fastfetch | `configs/apps/fastfetch/` | `.config/fastfetch/` |
| Fcitx5 | `configs/apps/fcitx5/` | `.config/fcitx5/`、`.local/bin/fcitx5-toggle-japanese` |
| Fontconfig | `configs/apps/fontconfig/` | `.config/fontconfig/` |
| Git | `configs/apps/git/` | `.gitconfig` |
| Go-musicfox | `configs/apps/go-musicfox/` | `.config/go-musicfox/` |
| GTK | `configs/apps/gtk/` | `.config/gtk-3.0/` |
| Kitty | `configs/apps/kitty/` | `.config/kitty/` |
| KOReader | `configs/apps/koreader/` | `.config/koreader/` |
| Micro | `configs/apps/micro/` | `.config/micro/settings.json`、`.config/micro/colorschemes/` |
| MIME 默认 | `configs/apps/mimeapps/` | `.config/mimeapps.list` |
| MPV | `configs/apps/mpv/` | `.config/mpv/` |
| Neovim | `configs/apps/nvim/` | `.config/nvim/`、`.local/share/applications/neovim-markdown.desktop` |
| Niri | `configs/apps/niri/` | `.config/niri/`、`.local/bin/niri-{hotkeys-zh,screenshot-window,stack-column}`、`.local/share/niri/hotkeys-zh.txt` |
| Noctalia | `configs/apps/noctalia/` | `.config/noctalia/`、`.local/state/noctalia/settings.toml`、`.local/share/noctalia/plugins/storage-gb/` |
| OBS Studio | `configs/apps/obs-studio/` | `.config/obs-studio/{global.ini,user.ini,basic/scenes,basic/profiles,plugin_manager/modules.json}` |
| OMP（Oh My Pi 配置） | `configs/apps/omp/` | `.omp/agent/config.yml`、`.omp/agent/models.yml`、`.omp/agent/themes/` |
| Pi（pi coding agent） | `configs/apps/pi/` | `.pi/agent/settings.json`、`.pi/agent/models-store.json`、`.pi/agent/npm/package.json` |
| Qt | `configs/apps/qt/` | `.config/QtProject.conf` |
| Shell | `configs/apps/shell/` | `.zshrc`、`.zshenv`、`.bashrc`、`.bash_profile`、`.bash_logout` |
| Sioyek | `configs/apps/sioyek/` | `.local/bin/sioyek`、`.config/sioyek/` |
| Starship | `configs/apps/starship/` | `.config/starship.toml` |
| Thunar | `configs/apps/thunar/` | `.config/Thunar/uca.xml` |
| Wallpapers（壁纸） | `configs/apps/wallpapers/` | `Pictures/Wallpapers/` |
| WeChat | `configs/apps/wechat/` | `.local/share/applications/wechat.desktop` |
| Wine | `configs/apps/wine/` | `.local/share/applications/wine.desktop` |
| XDG 用户目录 | `configs/apps/xdg-user-dirs/` | `.config/user-dirs.dirs`、`.config/user-dirs.locale` |
| Yazi | `configs/apps/yazi/` | `.config/yazi/` |
| Zed | `configs/apps/zed/` | `.config/zed/settings.json`、`.config/zed/keymap.json`、`.config/zed/snippets/` |
| Zen | `configs/apps/zen/` | `.config/zen/profiles.ini`、`.config/zen/<profile>/prefs.js`（白名单过滤）、`.config/zen/<profile>/zen-themes.json` |

每次提交前，采集清洗器（`scripts/lib/sanitize.sh`）会作用在每个应用目录上：

- 运行态删除而非入库：mpv 缓存与播放历史、KOReader 阅读历史/缓存/单书数据库、
  壁纸注释元数据、pi 会话记录与 `node_modules/`；
- 备份文件（`*.bak`、`*.bak-*`、`*.old`）删除：恢复取的是正式文件，不是备份；
- 凭据清空但保留结构：shell rc 中 `KEY`/`TOKEN`/`SECRET`/`PASSWORD` 的值、
  OBS `service.json` 推流密钥、git `user.email`、ani-rss 下载器密码/API Key/UUID，
  以及 `.omp`、`.pi` 运行态与 `agent/auth.json`。
- Zen 的 `prefs.js` 只保留固定白名单键：书签、历史、Cookie、登录信息、同步 ID、
  遥测标识与会话状态不入库；`profiles.ini` 归一为单个默认档案。

用户层恢复入口：

```bash
./scripts/restore-user.sh --dry-run
./scripts/restore-user.sh
```

被替换的路径先复制到 `~/.local/state/cachyos-config/backup/home`；该目录每次
恢复前清空，因此只保留一份备份。

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

控制台键盘映射固定 `KEYMAP=us`：`kbd` 没有中文控制台布局，`loadkeys cn` 会
`Unable to open file: cn` 并让 `systemd-vconsole-setup` 以 exit 1 失败（开机闪一行
`Failed to start Virtual Console Setup`）；中文输入由 GUI 的 fcitx5 负责，`XKBLAYOUT=cn`
只影响 X11、必须保留。`sd-vconsole` 钩子把 `/etc/vconsole.conf` 打进 initramfs，
所以改完该文件必须重建 initramfs（`update-initramfs`），否则 initramfs 阶段仍按旧值报错。

这一层之外恢复流程不写任何东西：没有磁盘 UUID、`/etc/machine-id`、`/etc/fstab`、
`/etc/hostname`。`/etc/pacman.d/mirrorlist` 这类由位置生成的文件永不自动恢复。

系统层恢复入口：

```bash
./scripts/restore-system.sh --dry-run
./scripts/restore-system.sh
```

复制后，恢复脚本会重新加载 systemd、生成 locale 并重建 initramfs。被替换的文件
备份在 `/var/backups/cachyos-config`，该目录每次恢复前清空，只保留一份备份。

## 软件与服务

`packages/profiles/` 与 `packages/required-extra.txt` 是软件包安装输入；
`packages/inventory/explicit.txt` 记录显式安装的软件；`packages/services/` 和
`packages/toolchains/` 记录采集状态，也会在恢复时使用。详见
[软件包与服务](packages-services.md)。

用 `scripts/profile.sh use NAME` 选择档位，用
`scripts/profile.sh diff full minimal` 查看两档差异。

### Clash Verge 国内直连

托管文件
`~/.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles/Script.js`
是全局扩展脚本：B 站网页、视频、图片和 API 域名及 `GEOSITE,cn` 优先直连，
缺少中国 IP 直连规则时补充兜底，保留订阅其余规则和海外节点选择。
订阅更新不会覆盖该脚本，切换订阅也会应用。

采集和恢复只管理这个文件，不覆盖整个 Clash 目录。恢复前退出 Clash Verge，
恢复后重新打开应用以生成生效配置。须使用「规则模式」，「全局模式」会绕过这些规则。
订阅和凭据需要单独恢复。

### Libvirt：守护进程不进开机

`libvirtd.service` **不**纳入 `packages/services/system.txt`。开机只启用
`libvirtd{,-ro,-admin}.socket`、`virtlockd{,-admin}.socket`、`virtlogd{,-admin}.socket`
做按需激活，真正有客户端连接时才拉起守护进程。`QEMU-win10` 定义在 `qemu:///session`，
无 autostart（`~/.config/libvirt/qemu/autostart/` 不存在），只能
`~/Downloads/QEMU-win10/manage.sh start` 手动启动。

代价：`virbr0` 默认 NAT 网络不再随开机出现，首次使用系统级 libvirt 时随守护进程出现；
该域用 `<interface type='user'>`，不依赖 `virbr0`。`restore-services.sh` 只负责 enable，
不负责 disable：目标机器若此前已 enable 过 `libvirtd.service`，恢复后需手动执行
`sudo systemctl disable --now libvirtd.service`。回滚只需
`sudo systemctl enable --now libvirtd.service`。

## 记录的软件版本

CachyOS 是滚动发行，软件包一直在升级，配置文件不会自动跟上。下表是每份托管配置
验证时对应的版本。跨版本升级后要回头读上游的格式变更说明（niri `.kdl` 节点名、
Noctalia 设置、kitty 选项、mpv `script-opts`、KOReader `settings.reader.lua`、
Sioyek `prefs.config`、Zed 设置、Micro 键位、fcitx5 profile 格式），并在同一次
提交里同时改配置和这张表。

| 组件 | 采集时版本 | 可能失效的配置格式 |
| --- | --- | --- |
| niri | 26.04 | `.config/niri/*.kdl` 的节点与 action 名 |
| Noctalia | 5.4.0 | `.config/noctalia/` 结构、`settings.toml` 状态键 |
| kitty | 0.49.2 | `.config/kitty/kitty.conf` 选项 |
| mpv | 0.41.0 | `mpv.conf` 选项、`script-opts/uosc.conf` |
| KOReader | 2026.07.1 | `settings.reader.lua`、`defaults.lua`、插件目录 |
| Sioyek | 2.0.0 | `prefs.config` 共享键 |
| Zed | 1.28.1 | `settings.json` 键、snippet JSON 结构 |
| Zen | 1.24.1b | `prefs.js` 白名单、`profiles.ini` 结构 |
| Neovim | 0.12.6 | 插件 API、LSP `vim.lsp.config` 结构 |
| Micro | 2.0.15 | `settings.json` 键、`bindings.json` action |
| fcitx5 | 5.1.23 | `profile`/`config` 选项名 |
| SDDM + Sugar Candy | 0.21.0 / 模块 | `theme.conf`、Qt6 QML API |
| OBS Studio | 33.0.1 | `basic/profiles/`、`basic/scenes/` JSON 结构 |
| Thunar | 4.20.10 | 自定义动作 XML（`uca.xml`） |
| Yazi | 26.9.1 | `yazi.toml`、`keymap.toml` 键 |
| Starship | 1.27.0 | `starship.toml` 模块 |
| Clash Verge Rev | 2.5.8 | 扩展脚本 API（`main(config)`） |
| Git | 2.56.0 | `.gitconfig` 段名 |
| Qt | 6.12.0 | `QtProject.conf` 键 |
| zsh | 5.9.2 | rc 加载顺序（`.zshenv` → `.zshrc`） |

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
