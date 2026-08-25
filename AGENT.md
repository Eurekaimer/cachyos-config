# AGENT.md —— 全自动恢复运行手册（供 AI Agent 直接读取执行）

> 目标：`git clone` 本仓库后，Agent 依照本文件按序执行脚本即可一键复原整台 CachyOS 笔记本。
> 原则：**能用仓库脚本就不要手搓命令**；每步执行后必须验证再进下一步；任何脚本无法覆盖的偏差记入 `NOTES.md`。

# 检测并导出代理（唯一实现：scripts/lib/proxy.sh；install-packages.sh 会自动调用）
source scripts/lib/proxy.sh && setup_proxy
git config --global http.proxy http://127.0.0.1:7897
git config --global https.proxy http://127.0.0.1:7897
```
（`~/.zshrc` / `~/.bashrc` 各自内联了同款检测块——家目录 shell 无法 source 仓库，属有意重复；
脚本统一走 lib，改端口只动 `PROXY_HOST` / `PROXY_PORT` 环境变量即可。）

> 校验：`curl -x http://127.0.0.1:7897 -s -o /dev/null -w '%{speed_download}\n' --max-time 15 https://github.com/` 应 >100000（B/s）。
# 检测并导出代理（install-packages.sh 顶部已内置同款检测，手工操作前也要执行）
if (command -v ss >/dev/null 2>&1 && ss -tln 2>/dev/null | grep -q '127.0.0.1:7897') || (nc -z 127.0.0.1 7897 2>/dev/null); then
    export http_proxy=http://127.0.0.1:7897 https_proxy=http://127.0.0.1:7897
    export HTTP_PROXY=http://127.0.0.1:7897 HTTPS_PROXY=http://127.0.0.1:7897
    export all_proxy=socks5h://127.0.0.1:7897 ALL_PROXY=socks5h://127.0.0.1:7897
    export no_proxy=localhost,127.0.0.1,::1,.local
fi
git config --global http.proxy http://127.0.0.1:7897
git config --global https.proxy http://127.0.0.1:7897
```

> 校验：`curl -x http://127.0.0.1:7897 -s -o /dev/null -w '%{speed_download}\n' --max-time 15 https://github.com/` 应 >100000（B/s）。

```bash
# 基础工具链（LiveCD/新系统可能缺）
sudo pacman -S --needed --noconfirm git base-devel

# AUR helper：paru（仓库脚本 install-packages.sh 会自动探测 paru 并加 --noconfirm）
git clone https://aur.archlinux.org/paru.git /tmp/paru && cd /tmp/paru && makepkg -si --noconfirm
```

检查点：
- `command -v paru` 有输出
- `./scripts/audit.sh` 退出码 0

`restore-all.sh` 的 Stage 0 已自动执行下面的初始化，单独跑 Stage 4 前手动执行一次：

```bash
git submodule update --init --recursive
test -f modules/sddm/sugar-candy/Main.qml || echo "STAGE4 WILL DIE"
```

```bash
git submodule update --init --recursive
test -f modules/sddm/sugar-candy/Main.qml || echo "STAGE4 WILL DIE"
```

排错：github.com 超时/SSL EOF 时，从任意旧克隆拷贝整个目录内容到
`modules/sddm/sugar-candy/`（只需文件存在即可过 `sync-sddm-theme.sh` 的存在性检查）。
字体类大文件走 §0 代理直拉（见 §6），不再有 vendor 离线包。

## 2. 执行顺序（两条路线）

### 路线 A：完整一键（推荐，机器不急时）

| 0 | 内置（无独立脚本） | 前置：`ensure_sudo` 检查 + `git submodule update --init --recursive` |
| 1 | `scripts/install-packages.sh` | paru 装 pacman-explicit + aur-explicit 全量（含 noctalia-qs/noctalia-shell）|
| 2 | `scripts/restore-system.sh` | 系统配置（sudo；结尾 daemon-reload/locale-gen/mkinitcpio -P）|
| 3 | `scripts/restore-user.sh` | 家目录配置替换 + dconf |
| 4 | `scripts/sync-sddm-theme.sh --from-snapshot` | SDDM Sugar Candy 主题 |
| 5 | `scripts/restore-services.sh` | systemctl enable 系统/用户单元 |
| 6 | `scripts/post-restore-tweaks.sh` | noctalia 运行时回填 + eDP-1 缩放 + 可选壁纸/fcitx5 重启 |

可选参数：`--migrate-zh-dirs`（Stage 0 顺带迁移中文家目录）、`--wallpaper FILE`（Stage 6 设壁纸）、
`--restart-fcitx5`（Stage 6 重启输入法）、`--now`、`--skip-aur`、`--no-backup`、`--dry-run`。
| 1 | `scripts/install-packages.sh` | paru 装 pacman-explicit + aur-explicit 全量 |
| 2 | `scripts/restore-system.sh` | 系统配置（sudo；结尾 daemon-reload/locale-gen/mkinitcpio -P）|
| 3 | `scripts/restore-user.sh` | 家目录配置替换 + dconf |
| 4 | `scripts/sync-sddm-theme.sh --from-snapshot` | SDDM Sugar Candy 主题 |
| 5 | `scripts/restore-services.sh` | systemctl enable 系统/用户单元 |

### 路线 B：最快可用桌面（用户在旁边等时，按依赖优先级拆开跑）

用户指定的优先级：**浏览器/常用应用 → 中文输入法 → 前端外壳(noctalia)**。

```bash
# B1. 应用层（含 google-chrome/linuxqq/wechat-bin/zoom，全在 aur-explicit.txt）
./scripts/install-packages.sh                 # 幂等，一次装完所有包

# B2. 用户配置层（fcitx5 双拼/classicui、niri 键位、noctalia 配置、壁纸）
./scripts/restore-user.sh

# —— 此时让用户注销重登 niri 即可干活；其余阶段随后补跑 ——
# B3. ./scripts/restore-system.sh
# B4. ./scripts/sync-sddm-theme.sh --from-snapshot
# B5. ./scripts/restore-services.sh
```

### AUR 提供者清单（避免 paru 非交互卡选择）

| 清单里的包名 | 说明 |
|---|---|
| `baidunetdisk-bin` | AUR 真名；`baidunetdisk` 是虚拟名，会触发提供者选择 |
| `go-musicfox-bin` | AUR 真名；`go-musicfox` 同理 |
| `google-chrome` | AUR 本体；另有 beta/canary/dev 变体，勿混装 |
| paru.conf `Provides` 需注释 | 不注释则无 TTY 下卡在"选择提供者"，多包安装直接挂起 |

登录自启只对下次登录生效；当前会话内立即启用：

```bash
pkill -x noctalia; sleep 1
setsid qs -d -c noctalia-shell </dev/null >/dev/null 2>&1 &
sleep 3; qs list --all                       # 必须列出实例
qs -c noctalia-shell ipc call launcher toggle # exit 0 = Super/Caps+Space 启动器可用
```

## 3. 输入法快速自检

```bash
fcitx5-remote            # exit 0；输出 2 表示激活
grep -c lxgw <(fc-list :family)   # >0 = LXGW 字体就位（候选框样式依赖）
```

环境变量 `GTK_IM_MODULE/QT_IM_MODULE/XMODIFIERS` 由 `.config/niri/cfg/misc.kdl`
在 niri 启动时注入——**已开着的旧应用收不到，重登生效**。

## 4. 验证总表（全部通过才算完成）

1. `qs list --all` 有实例 且 `launcher toggle` exit 0
2. `fcitx5-remote` exit 0；任意应用打拼音出候选框（LXGW WenKai 样式）
3. `restore-all.sh` 尾行 `== Full restore complete`
4. `systemctl list-unit-files | grep -Fxf packages/system-services.txt` 抽查 enabled
5. `niri validate -c ~/.config/niri/config.kdl` 通过
6. `NOTES.md` 记录了本次所有 warning/偏差

## 5. 排错决策树


| 症状 | 根因 | 处理 |
|---|---|---|
| `sudo: 非交互管道下秒败 "需要密码"` | stdin 未送达（非密码错误） | 用 `SUDO_ASKPASS` 脚本 + `sudo -A <cmd>`；或临时 NOPASSWD sudoers.d 文件（结束必删） |
| Stage 0 前置失败（error: Preflight failed） | 非交互会话无免密 sudo | 配临时 NOPASSWD 后重跑 restore-all |
| Stage 4 die: Sugar Candy missing | 子模块未初始化 | 见 §1（Stage 0 已自动处理） |
| GitHub 连接超时/SSL EOF | 直连被墙/抖动 | proxy 已有(clash verge)则查规则；否则用 vendor/ 或旧克隆离线救 |
| paru 卡死/锁冲突 | 上一个 paru/pacman 未退出 | `pgrep -af 'paru\|pacman'` 确认后等待或清 `/var/lib/pacman/db.lck` |
| Caps/Super+Space 无反应 | quickshell 外壳没起 | §2 路线 B 的手动拉起三连 |
| 候选框字体不对 | LXGW 未装/未刷新缓存 | `pacman -Q ttf-lxgw-wenkai ttf-lxgw-wenkai-mono-nerd`; `fc-cache -f` |
| 单个 AUR 包反复构建失败 | 上游问题 | 从列表剔除该包单独装其余，记录 NOTES.md |
| `冲突的软件包将需要手动确认` | 包文件冲突 | 从清单剔除冲突包名，保留已装好的同名包 |
| `无法找到所有需要的软件包: X` | X 在 AUR 不存在 | 从清单剔除 X，记录 NOTES.md |
| 壁纸/配色恢复后被回退 | restore-user 覆盖了运行时文件 | 跑 `scripts/post-restore-tweaks.sh`（幂等）|

## 6. 字体下载（无需 vendor）

`ttf-lxgw-wenkai{,-mono-nerd}` 的 PKGBUILD 要现拉 ~140MB GitHub release。
走 §0 代理实测 ~5MB/s，直接让 paru/makepkg 拉即可；`vendor/fonts/` 离线包方案
已随 2026-08-25 重构移除（无脚本消费，纯冗余）。GitHub 完全不可达时才考虑旧克隆离线兜底。

## 7. 明确不要做的事

- 不传 `--with-hardware`（fstab/hostname 是机器绑定的）
- 不自动 reboot——最后提示用户自己重启
- 不跳过备份（默认备份到 `~/.local/state/cachyos-config/backups/<ts>/`）
- 临时提权文件（sudoers.d/askpass）用完必须删除并在 NOTES.md 记录
restore-user 会用快照覆盖 `~/.config/noctalia` 与 `cfg/display.kdl`，丢掉运行时状态。
**不要手搓命令**——跑仓库脚本（restore-all 的 Stage 6 已自动执行）：

```bash
# 完整收尾（noctalia 回填 + eDP-1 scale 1.1；可选加壁纸/重启 fcitx5）
./scripts/post-restore-tweaks.sh
./scripts/post-restore-tweaks.sh --wallpaper project_mifeng.png --restart-fcitx5
```

自检：`grep -c luckystar ~/.config/noctalia/settings.json` > 0；
`niri msg outputs | sed -n '6,8p'` 显示 `Scale: 1.1`。

restore-user 会用快照覆盖 `~/.config/noctalia` 与 `cfg/display.kdl`，丢掉运行时状态：

```bash
# 1) noctalia 运行时文件（来自备份目录）
TS=$(ls -1dt ~/.local/state/cachyos-config/backups/*/ | head -1)
cp -a "$TS/home/.config/noctalia/settings.json" "$TS/home/.config/noctalia/colors.json" ~/.config/noctalia/
cp -a "$TS/home/.config/noctalia/colorschemes" ~/.config/noctalia/ 2>/dev/null || true
cp -a "$TS/home/.config/noctalia/config.toml" ~/.config/noctalia/ 2>/dev/null || true
grep -c luckystar ~/.config/noctalia/settings.json   # >0

# 2) eDP-1 缩放（机器相关，不入快照）
grep -q 'output "eDP-1"' ~/.config/niri/cfg/display.kdl || cat >> ~/.config/niri/cfg/display.kdl <<'EOF'

output "eDP-1" {
    scale 1.1
}
EOF
niri msg outputs | sed -n '6,8p'   # Scale: 1.1
```
