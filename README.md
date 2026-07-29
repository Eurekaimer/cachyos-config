# cachyos-config

CachyOS 工作站的可审计、可重复恢复包。配置快照、软件清单和执行脚本彼此分离；既能单独恢复某一层，也能由总脚本完整恢复。

下面的内容都是ChatGPT 5.6Sol写的，主要是为了方便复原而已，基本上除了架构没有什么参考价值。

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
