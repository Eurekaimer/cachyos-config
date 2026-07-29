# 配置位置与恢复策略

## 用户层（自动覆盖）

| 功能 | 当前实际位置 | 仓库位置 |
|---|---|---|
| Zsh | `~/.zshrc` | `configs/home/.zshrc` |
| Bash | `~/.bashrc`、`~/.bash_profile`、`~/.bash_logout` | `configs/home/` |
| Git | `~/.gitconfig` | `configs/home/.gitconfig`（公开快照移除邮箱） |
| Kitty | `~/.config/kitty/` | `configs/home/.config/kitty/` |
| Starship | `~/.config/starship.toml` | `configs/home/.config/starship.toml` |
| Niri | `~/.config/niri/` | `configs/home/.config/niri/` |
| Niri 辅助脚本 | `~/.local/bin/niri-hotkeys-zh`、`~/.local/bin/niri-stack-column` | `configs/home/.local/bin/` |
| Noctalia | `~/.config/noctalia/` | `configs/home/.config/noctalia/` |
| Fcitx5 | `~/.config/fcitx5/` | `configs/home/.config/fcitx5/` |
| Fastfetch | `~/.config/fastfetch/` | `configs/home/.config/fastfetch/` |
| MPV | `~/.config/mpv/` | `configs/home/.config/mpv/` |
| GTK | `~/.config/gtk-3.0/`、`~/.config/gtk-4.0/` | `configs/home/.config/` |
| Micro | `~/.config/micro/settings.json`、`colorschemes/` | `configs/home/.config/micro/` |
| MIME 默认应用 | `~/.config/mimeapps.list` | `configs/home/.config/mimeapps.list` |
| 自动启动 | `~/.config/autostart/` 白名单文件 | `configs/home/.config/autostart/` |
| XDG 用户目录 | `~/.config/user-dirs.dirs`、`user-dirs.locale` | `configs/home/.config/` |
| 壁纸资源 | `~/Pictures/Wallpapers/` | `configs/home/Pictures/Wallpapers/` |
| dconf | `~/.config/dconf/user`（二进制数据库） | `configs/dconf/user.ini`（`dconf dump` 文本） |

用户层恢复入口：

```bash
./scripts/restore-user.sh --dry-run
./scripts/restore-user.sh
```

## 系统可移植层（显式覆盖 `/etc`）

| 功能 | 位置 |
|---|---|
| Pacman 仓库与选项 | `/etc/pacman.conf` |
| makepkg 编译选项 | `/etc/makepkg.conf` |
| initramfs hooks | `/etc/mkinitcpio.conf` |
| 语言与控制台 | `/etc/locale.conf`、`/etc/locale.gen`、`/etc/vconsole.conf` |
| 全局环境 | `/etc/environment` |
| 外接显示器 DDC/CI | `/etc/modules-load.d/i2c-dev.conf`；软件为 `ddcutil` |
| X11 键盘 | `/etc/X11/xorg.conf.d/00-keyboard.conf` |
| UFW | `/etc/default/ufw`、`/etc/ufw/{ufw.conf,user.rules,user6.rules}` |
| Snapper | `/etc/snapper/configs/root`、`/etc/conf.d/snapper` |
| libvirt 默认网络 | `/etc/libvirt/qemu/networks/default.xml` |

系统层恢复入口：

```bash
./scripts/restore-system.sh --dry-run
./scripts/restore-system.sh
```

恢复后脚本执行 `systemctl daemon-reload`、`locale-gen` 和 `mkinitcpio -P`。

## 硬件/主机层（默认禁止覆盖）

- `/etc/fstab`：含当前 Btrfs 子卷与磁盘 UUID。
- `/etc/hostname`：当前主机名。

这些文件保存在 `configs/system/hardware/`，只有 `--with-hardware` 才会覆盖。新磁盘或不同主机必须让 Agent 先对照 `state/hardware/{lsblk,findmnt,lspci}.txt`。

## 仅供比较

- `/etc/pacman.d/mirrorlist`：位置和时间相关，保存在 `configs/system/reference/`，脚本永不自动覆盖。
- `state/hardware/`：硬件与挂载参考，不是恢复输入。

## 软件与服务

| 清单 | 内容 |
|---|---|
| `packages/pacman-explicit.txt` | 当前显式安装且来自已配置仓库的软件 |
| `packages/aur-explicit.txt` | 当前显式 AUR/外部软件 |
| `packages/required-extra.txt` | 恢复配置自身依赖的软件，例如 `jq` |
| `packages/rustup-toolchains.txt` | Rust 工具链 |
| `packages/bun-global.txt` | Bun 全局工具，包括 Oh My Pi Agent |
| `packages/system-services.txt` | 已启用系统服务 |
| `packages/user-services.txt` | 已启用用户服务 |

## 明确不进入公开仓库

`~/.ssh`、`~/.gnupg`、浏览器目录、`~/.config/io.github.clash-verge-rev.clash-verge-rev`、`/etc/NetworkManager/system-connections`、`~/.omp`、Cookie、登录数据库、历史、日志和缓存。它们必须使用密码管理器或加密备份单独迁移。
