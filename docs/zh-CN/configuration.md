# 配置位置与恢复策略

[English](../en/configuration.md)

本文从功能出发，索引实时位置、仓库快照和恢复边界。所有表格都按第一列的
英文名称或路径字母序排列，因此知道软件名时不需要扫描无关内容。真正决定采集
范围的来源仍然是 `manifests/` 下的白名单。

## 用户层

`configs/home/` 镜像 `$HOME` 下的白名单路径；`configs/dconf/user.ini` 是可移植
文本导出，不是 dconf 二进制数据库。

| 功能 | 当前实际位置 | 仓库位置 |
| --- | --- | --- |
| Autostart（自动启动） | `~/.config/autostart/` 下的白名单文件 | `configs/home/.config/autostart/` |
| Bash | `~/.bashrc`、`~/.bash_profile`、`~/.bash_logout` | `configs/home/` |
| CachyOS Hello | `~/.config/cachyos-hello.json` | `configs/home/.config/cachyos-hello.json` |
| Dconf | `~/.config/dconf/user` 二进制数据库 | `configs/dconf/user.ini` 文本导出 |
| Docker helper | `~/.local/bin/docker-ass` | 不入快照；用 `scripts/install-docker-anirss.sh` 单独安装 |
| Fastfetch | `~/.config/fastfetch/` | `configs/home/.config/fastfetch/` |
| Fcitx5 | `~/.config/fcitx5/` | `configs/home/.config/fcitx5/` |
| Fontconfig | `~/.config/fontconfig/` | `configs/home/.config/fontconfig/` |
| Git | `~/.gitconfig` | `configs/home/.gitconfig`；公开快照移除邮箱 |
| GTK | `~/.config/gtk-3.0/`、`~/.config/gtk-4.0/` | `configs/home/.config/` |
| Kitty | `~/.config/kitty/` | `configs/home/.config/kitty/` |
| Micro | `~/.config/micro/settings.json`、`~/.config/micro/colorschemes/` | `configs/home/.config/micro/` |
| MIME defaults（默认应用） | `~/.config/mimeapps.list` | `configs/home/.config/mimeapps.list` |
| MPV | `~/.config/mpv/` | `configs/home/.config/mpv/` |
| Neovim | `~/.config/nvim/`、Neovim Markdown desktop entry | `configs/home/.config/nvim/`、`configs/home/.local/share/applications/neovim-markdown.desktop` |
| Niri | `~/.config/niri/` | `configs/home/.config/niri/` |
| Niri helpers（辅助脚本） | `~/.local/bin/niri-hotkeys-zh`、`~/.local/bin/niri-stack-column`、快捷键文本 | `configs/home/.local/bin/`、`configs/home/.local/share/niri/` |
| Noctalia | `~/.config/noctalia/` | `configs/home/.config/noctalia/` |
| Qt | `~/.config/QtProject.conf` | `configs/home/.config/QtProject.conf`；最近路径元数据会被移除 |
| Starship | `~/.config/starship.toml` | `configs/home/.config/starship.toml` |
| Thunar | `~/.config/Thunar/uca.xml` | `configs/home/.config/Thunar/uca.xml` |
| Wallpapers（壁纸） | `~/Pictures/Wallpapers/` | `configs/home/Pictures/Wallpapers/` |
| XDG user directories（用户目录） | `~/.config/user-dirs.dirs`、`~/.config/user-dirs.locale` | `configs/home/.config/` |
| Zsh | `~/.zshrc` | `configs/home/.zshrc` |

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

第一列是实际清单路径，并按路径字母序排列。

| 清单 | 内容 |
| --- | --- |
| `packages/aur-explicit.txt` | 当前显式 AUR 或外部软件 |
| `packages/bun-global.txt` | Bun 全局工具，包括 Oh My Pi Agent |
| `packages/pacman-explicit.txt` | 当前显式安装且来自已配置仓库的软件 |
| `packages/required-extra.txt` | 托管配置或恢复脚本自身依赖的软件 |
| `packages/rustup-toolchains.txt` | Rust 工具链 |
| `packages/system-services.txt` | 已启用系统服务 |
| `packages/user-services.txt` | 已启用用户服务 |

## 明确不进入公开仓库

SSH/GPG 密钥、浏览器目录、Clash profiles、NetworkManager connections、
`~/.omp` 运行状态、Cookie、登录数据库、历史、日志和缓存必须通过密码管理器或
加密备份单独迁移，不是本公开仓库的恢复输入。
