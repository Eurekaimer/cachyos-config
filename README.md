# cachyos-config

CachyOS 工作站的可审计、可重复恢复包。配置快照、软件清单和执行脚本彼此分离；既能单独恢复某一层，也能由总脚本完整恢复。

## 快速恢复

```bash
git clone <你的仓库 URL> cachyos-config
cd cachyos-config

# 必须先审计并查看将执行的动作
./scripts/audit.sh
./scripts/restore-all.sh --dry-run

# 新 CachyOS 机器：安装软件、覆盖系统/用户配置、恢复服务
./scripts/restore-all.sh
sudo reboot
```

只有在磁盘 UUID、分区结构和主机身份都与快照一致时，才允许恢复硬件配置：

```bash
./scripts/restore-all.sh --with-hardware
```

`--with-hardware` 会直接覆盖 `/etc/fstab` 和 `/etc/hostname`。在不同机器上使用错误的 `fstab` 可能导致无法启动。

## 分层结构

```text
cachyos-config/
├── configs/
│   ├── home/                 # 对应 $HOME 的用户配置快照
│   ├── system/portable/      # 可移植的 /etc 配置
│   ├── system/hardware/      # fstab、hostname；只可显式恢复
│   ├── system/reference/     # 仅比较，不自动恢复
│   └── dconf/user.ini        # dconf 文本导出
├── manifests/                # 允许采集/覆盖的路径白名单
├── packages/                 # pacman、AUR、Rust、Bun、服务清单
├── scripts/
│   ├── lib/                  # 日志、备份、覆盖等公共抽象
│   ├── capture.sh            # 从当前机器刷新快照
│   ├── install-packages.sh   # 只安装软件和工具链
│   ├── restore-user.sh       # 只覆盖用户配置
│   ├── restore-system.sh     # 只覆盖系统配置
│   ├── restore-services.sh   # 只恢复服务启用状态
│   ├── restore-all.sh        # 总入口
│   ├── diagnostics/          # 不修改系统的硬件诊断
│   └── audit.sh              # 开源前安全与结构审计
├── state/                    # 采集时间、系统和硬件参考信息
└── docs/
    ├── config-locations.md   # 当前配置位置与恢复策略
    ├── storage-diagnostics.md # 外置 SSD 链路诊断
    └── agent-recovery.md     # 新机器上交给 Agent 的操作规范
```

## 覆盖与备份语义

恢复不是“合并”。脚本严格按照 `manifests/*.txt`：

1. 将目标已有文件/目录复制到备份目录；
2. 删除目标路径；
3. 将仓库快照原样复制到对应 FHS/XDG 位置；
4. 用户名变化时，只在受管文本文件内把旧 `$HOME` 改为新 `$HOME`。

默认备份位置：

- 用户配置：`~/.local/state/cachyos-config/backups/<时间>/home/`
- 系统配置：`/var/backups/cachyos-config/<时间>/`

可用 `--no-backup` 关闭备份，但不建议。

## 单独执行

```bash
./scripts/install-packages.sh
./scripts/restore-user.sh
./scripts/restore-system.sh
./scripts/restore-services.sh
```

所有修改型脚本都支持 `--dry-run`。各脚本的完整参数见 `--help`。

## 刷新当前机器快照

```bash
./scripts/capture.sh
./scripts/audit.sh
```

采集脚本只读取白名单。要新增配置，应先把相对路径加入 `manifests/`，不要在脚本里散落硬编码复制命令。

## 开源安全边界

以下内容不会采集：密码、SSH/GPG 私钥、浏览器资料、Clash 配置、NetworkManager 连接、Cookie、缓存、日志及 `.omp` 运行时数据库。Git 邮箱也会在采集时移除；恢复后手动执行：

```bash
git config --global user.email '你的邮箱'
```

公开前必须执行 `./scripts/audit.sh`，并人工检查 `configs/` 和 `state/`。软件清单会暴露已安装应用名称；壁纸快照可能涉及版权，公开前需自行确认许可。

## 当前软件快照

最近一次采集时间为 `2026-07-29T05:25:21+08:00`。README 只列恢复所需的统计和关键桌面软件；完整、可直接用于安装的清单由 `./scripts/capture.sh` 自动刷新：

| 来源 | 当前数量 | 完整清单 |
|---|---:|---|
| CachyOS/Arch 仓库显式软件包 | 219 | `packages/pacman-explicit.txt` |
| AUR/外部显式软件包 | 13 | `packages/aur-explicit.txt` |
| Rustup 工具链 | 1 | `packages/rustup-toolchains.txt` |
| Bun 全局软件包 | 1 | `packages/bun-global.txt` |
| 已启用系统服务 | 29 | `packages/system-services.txt` |
| 已启用用户服务 | 6 | `packages/user-services.txt` |

当前关键软件版本：

| 软件 | 版本 | 用途 |
|---|---|---|
| Niri | `26.04-1.1` | Wayland 合成器与窗口管理 |
| Noctalia Shell | `4.7.7-3` | 顶栏、控制中心、启动器及夜间模式 |
| Nautilus | `50.2.2-1` | `Super+E` 默认图形文件管理器 |
| Thunar | `4.20.9-1.1` | 仍保留安装，但不再绑定 `Super+E` |
| Kitty | `0.48.1-1.1` | 终端 |
| MPV | `0.41.0-3.1` | 视频播放 |
| imv | `5.0.1-2.1` | 图片双击打开 |
| Fcitx5 | `5.1.21-1.1` | 中文输入法 |
| Clash Verge Rev | `2.5.2-1` | 本地代理客户端 |
| Google Chrome | `150.0.7871.186-1` | 浏览器 |
| QEMU / Libvirt / Virt Manager | `11.0.2-4` / `12.5.0-1.1` / `5.1.0-4` | Windows 虚拟机 |
| ddcutil / i2c-tools | `2.2.7-1.1` / `4.4-4.1` | 外接显示器 DDC/CI 亮度控制 |
| wlsunset | `0.4.0-1.1` | 4000 K 夜间色温 |
| ShellCheck | `0.11.0-130` | 恢复脚本静态检查 |

版本是该次快照的记录；滚动更新后以 `pacman -Q` 和 `packages/` 下由采集脚本刷新的清单为准。`./scripts/install-packages.sh` 会安装清单，而不是解析 README 表格。

## Clash 与 Niri 代理环境

此前 Clash 已运行，但从 Niri 启动的 Google Chrome 等程序没有继承代理环境，因此浏览器无法访问 Google。修复位于 `~/.config/niri/cfg/misc.kdl` 的 `environment` 块，并已保存在 `configs/home/.config/niri/cfg/misc.kdl`：

```kdl
http_proxy  "http://127.0.0.1:7897"
https_proxy "http://127.0.0.1:7897"
all_proxy   "socks5h://127.0.0.1:7897"
HTTP_PROXY  "http://127.0.0.1:7897"
HTTPS_PROXY "http://127.0.0.1:7897"
ALL_PROXY   "socks5h://127.0.0.1:7897"
no_proxy    "localhost,127.0.0.1,::1,.local"
NO_PROXY    "localhost,127.0.0.1,::1,.local"
```

同时设置大小写两套变量，以兼容 Chromium/Electron、命令行工具和不同网络库；`socks5h` 让代理端处理域名解析。这里假定 Clash 的混合代理端口为 `7897`；如果 Clash 端口改变，必须同步修改这八项。应用修改：

```bash
niri validate
niri msg action load-config-file
```

然后彻底退出并重新打开 Chrome 等已有进程；已运行的进程不会追溯继承新环境。仓库只保存本机回环地址和端口，不采集 Clash 节点、订阅或凭据。

## 当前桌面行为

- `Super+E`：恢复为原来的 Nautilus 文件管理器；Thunar 仍安装但不再作为默认快捷键目标。
- 双击 Markdown：在新的 Niri 列中用 Kitty + Neovim 打开。
- 双击图片：在新的 Niri 列中用 imv 打开。
- `Super+[` / `Super+]`：合并或分离窗口；由 Niri 按顶栏实际占用区和 16 px 间距自动均分列高。实测两窗口各 671.33 px、三窗口各 442 px，底部边框完整。
- `Super+Ctrl+H/L`：当前列宽度以 2% 微调。
- `Super+Ctrl+J/K`：当前窗口高度以 2% 微调。
- `Super+Ctrl+方向键`：保留原来的列/窗口移动功能。
- MPV 设置 `keepaspect-window=no`，平铺时允许合成器独立调整窗口比例；视频内容仍保持自身比例并留黑边。已打开的 MPV 需重启一次才读取该设置。
- Noctalia 夜间模式已强制启用，色温为 4000 K；安装 `wlsunset` 后立即生效。
- 外接 HP27UI 通过 DDC/CI 控制亮度，当前为 35%，每次按亮度键调整 5%。`ddcutil`、`i2c-dev` 和开机模块加载配置均已纳入恢复包。

## 外置 SSD 当前诊断

`/dev/sda` 的 RTL9210 NVMe 硬盘盒当前只协商到 USB 2.0 `480 Mbit/s`，使用 `usb-storage` 且队列深度为 1；这就是约 20 MB/s 的根因。SSD SMART 健康、40°C、无介质错误。必须换到 USB 3.x/10G 端口并使用带 SuperSpeed 数据线的线缆；软件参数无法提升物理协商速率。

重插后验证：

```bash
./scripts/diagnostics/storage-link.sh /dev/sda
```

预期为 `5000` 或 `10000 Mbit/s`，通常驱动为 `uas`。完整证据和处理流程见 `docs/storage-diagnostics.md`。
