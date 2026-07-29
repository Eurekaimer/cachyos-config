# 新机器 Agent 恢复规范

[English](../en/recovery.md)

本文件是给自动化 Agent 的操作合同。目标：在全新 CachyOS 上恢复软件、配置和服务，同时避免把旧磁盘 UUID 写入新机器。

## 不变量

1. 必须以目标桌面用户运行脚本，不得直接用 root 运行总脚本。
2. 必须先执行安全审计和 dry-run；失败时停止，不得绕过。
3. 默认不得使用 `--with-hardware`。
4. 不得把密码、SSH/GPG 私钥、浏览器资料、Clash/NetworkManager 凭据补进公开仓库。
5. 不得手工逐文件复制；路径白名单只维护在 `manifests/`。
6. 恢复脚本采用“备份、删除目标、原样复制”，不是目录合并。

## 标准流程

```bash
cd ~/Documents/GitHub/cachyos-config

./scripts/audit.sh
./scripts/restore-all.sh --dry-run
./scripts/restore-all.sh
sudo reboot
```

如果仓库位于其他目录，可直接从仓库根目录执行；脚本不依赖固定仓库绝对路径。

## 使用硬件快照前的强制判断

仅当用户明确要求恢复同一磁盘布局时才进入本节。Agent 必须比较：

```bash
lsblk -f
findmnt --real
cat state/hardware/lsblk.txt
cat state/hardware/findmnt.txt
```

以下任一项不同，禁止 `--with-hardware`：

- 根分区、EFI 分区 UUID；
- Btrfs 子卷命名；
- `/boot`、`/home`、`/var/*` 挂载策略；
- 新机器已有的重要挂载。

完全一致后才可执行：

```bash
./scripts/restore-all.sh --dry-run --with-hardware
./scripts/restore-all.sh --with-hardware
```

## 分阶段恢复与故障隔离

```bash
# 软件源、pacman/AUR、Rust、Bun Agent
./scripts/install-packages.sh --dry-run
./scripts/install-packages.sh

# /etc；不含 fstab/hostname
./scripts/restore-system.sh --dry-run
./scripts/restore-system.sh

# $HOME 与 dconf
./scripts/restore-user.sh --dry-run
./scripts/restore-user.sh

# systemd enable 状态；缺失 unit 会跳过
./scripts/restore-services.sh --dry-run
./scripts/restore-services.sh
```

AUR 暂时不可用时可以先用 `--skip-aur` 完成仓库软件，再单独重试 `install-packages.sh`。

## 恢复后的验收

```bash
# 脚本和公开安全边界
./scripts/audit.sh

# Niri 配置
niri validate

# 关键软件
command -v niri kitty nautilus thunar imv mpv fcitx5 jq ddcutil wlsunset omp
omp --version

# 服务
systemctl is-enabled NetworkManager bluetooth ufw libvirtd

# 配置落点
cmp configs/home/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf
```

如果目标用户名与采集用户名不同，`restore-user.sh` 会在白名单文本文件中将旧 home 路径改写为当前 `$HOME`；因此不能用全仓库 `cmp` 验收这类文件。

## 桌面交互验收

1. `Super+E` 打开 Nautilus；Thunar 可以保留安装，但不是该快捷键的目标。
2. 在 Nautilus 中复制、移动并打开一个测试目录，确认基本文件操作正常。
3. 双击 `.md`，确认新的 `markdown-neovim` 列用 Kitty + Neovim 打开；双击图片，确认新的 `imv` 列打开。
4. 打开两个或三个普通平铺窗口，用 `Super+[` 或 `Super+]` 堆叠；两窗口高度应约 671 px，三窗口约 442 px，最底部窗口边框完整可见。
5. 用 `Super+Ctrl+H/L` 微调列宽，用 `Super+Ctrl+J/K` 微调当前窗口高度。
6. 重启 MPV 后再测试堆叠。`keepaspect-window=no` 允许窗口适配列高，视频画面本身仍保持比例。
7. 对外置 SSD 运行 `scripts/diagnostics/storage-link.sh /dev/sda`；如果仍为 `480 Mbit/s`，必须更换到 USB 3.x/10G 端口和 SuperSpeed 线缆，不能用内核参数掩盖。
8. 运行 `ddcutil getvcp 10`，确认 HP27UI 可读；用亮度键增减后再读取，数值应按 5 变化。`pgrep -a wlsunset` 应显示 4000 K 的夜间模式进程。

## 刷新快照

在源机器修改配置或软件后：

```bash
./scripts/capture.sh
./scripts/audit.sh
```

然后人工查看 `configs/`、`packages/` 和 `state/`。只有审计成功并确认没有个人凭据后才能提交到 GitHub。
