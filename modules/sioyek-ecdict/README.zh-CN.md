# sioyek-ecdict

[![Python](https://img.shields.io/badge/Python-3.11%2B-3776AB?logo=python&logoColor=white)](pyproject.toml)
![SQLite](https://img.shields.io/badge/SQLite-离线数据库-003B57?logo=sqlite&logoColor=white)
[![ECDICT](https://img.shields.io/badge/词典数据-ECDICT-6f42c1)](https://github.com/skywind3000/ECDICT)
![Linux](https://img.shields.io/badge/平台-Linux-FCC624?logo=linux&logoColor=black)

[English](README.md)

面向 [Sioyek](https://github.com/ahrm/sioyek) 的快速离线英汉查词工具，词典数据来自 [ECDICT](https://github.com/skywind3000/ECDICT)。目前只支持 Linux。

## 功能

- 在 Sioyek 中选中英文后按 `s`，释义卡片显示在屏幕右上角。
- 配置一次桌面快捷键后，按 `Super+S` 可随时打开全局词典输入框。
- 常驻 GTK/SQLite D-Bus 服务：每次查词不启动浏览器、不读取剪贴板、不访问网络，也不重复冷启动 Python。
- 显示中文释义、音标、词性、原形、柯林斯/牛津标记和词频信息。
- 自动处理 PDF 断行连字符，并识别 ECDICT 收录的词形变化。
- 卡片可拖动；拖动事件按显示帧合并，移动更平滑。
- 点击外部、按 `Esc` 或关闭按钮均可关闭。
- 首次导入完成后完全离线运行。

## CachyOS 快速安装

先通过 AUR 安装原生 Sioyek：

```bash
yay -S sioyek-git
```

随后克隆工作站配置仓库，并执行一个脚本：

```bash
git clone https://github.com/Eurekaimer/cachyos-config.git
cd cachyos-config
./scripts/install-sioyek-ecdict.sh
```

包装脚本会通过 `pacman` 补齐 `uv`、`python-gobject` 和
`gtk4-layer-shell`，然后调用仓库内置安装器。安装器通过
`uv sync --frozen` 按 `uv.lock` 还原 Python 项目，再调用一个可重复执行的
`bootstrap` 命令。首次执行会下载 ECDICT，并生成
`${XDG_DATA_HOME:-~/.local/share}/sioyek-ecdict/ecdict.sqlite3`；以后直接复用。
systemd 用户服务运行的是此模块内部的虚拟环境，因此请保留仓库目录。

安装完成后重启 Sioyek，选中英文并按 `s`。

## 手动安装模块

请使用原生 Linux 软件包或 AppImage 版 Sioyek。Flatpak 宿主集成目前未经
验证，暂不支持。从仓库根目录执行：

```bash
# Arch Linux / CachyOS
sudo pacman -S --needed uv python-gobject gtk4-layer-shell
./modules/sioyek-ecdict/install.sh

# Debian / Ubuntu（包是否存在取决于发行版版本）
sudo apt install python3-gi gir1.2-gtk-4.0 gir1.2-gtk4layershell-1.0
./modules/sioyek-ecdict/install.sh

# Fedora
sudo dnf install uv python3-gobject gtk4-layer-shell
./modules/sioyek-ecdict/install.sh
```

安装器会先检查 Linux、Sioyek、uv、GLib、GTK4 和 layer-shell，确认依赖
齐全后才修改配置。随后自动：

1. 重建 uv 隔离环境，同时复用发行版提供的 GTK ABI。
2. 执行 `uv sync --frozen`，以 `pyproject.toml` 和 `uv.lock` 完整定义
   Python 环境。
3. 执行 `sioyek-ecdict bootstrap`：仅在 XDG 数据库不存在时导入
   ECDICT，再以幂等方式刷新 Sioyek 集成。
4. 识别已有的 XDG Sioyek 配置目录；没有时创建 `~/.config/sioyek`。
5. 写入 `prefs_user.config`、`keys_user.config` 与 systemd 用户服务；
   服务命令明确记录 SQLite 数据库的完整路径。

安装器的核心命令等价于：

```bash
cd modules/sioyek-ecdict
uv venv --python /usr/bin/python3 --system-site-packages .venv
uv sync --frozen
uv run --no-sync sioyek-ecdict bootstrap
```

`uv` 负责 Python 包、锁文件、虚拟环境和命令行入口；发行版包管理器负责
PyGObject、GTK4 与 Gtk4LayerShell，因为这些绑定必须匹配宿主系统 ABI。
`bootstrap` 只管理生成的 SQLite 数据库、Sioyek 用户配置条目和 systemd
用户服务，不会修改 `/etc/sioyek`。

Sioyek 配置位于非标准目录时可明确指定：

```bash
SIOYEK_CONFIG_DIR=/path/to/sioyek/config ./modules/sioyek-ecdict/install.sh
```

## 键位

| 键位 | 功能 |
|---|---|
| `s` | 查询 Sioyek 中选中的英文；没有选中文字时静默退出 |
| `Super+S` | 配置下方桌面快捷键后，打开全局词典输入框 |

安装器会写入以空格分隔的 `_ecdict s`，覆盖 Sioyek 默认的
`external_search s`。不会再安装 Google Scholar 或其他联网搜索键位。

## 配置全局 `Super+S`
仓库附带的 Niri 快照已经包含此绑定。其他桌面环境可把下面的命令绑定到
`Super+S`：


```bash
gdbus call --session \
  --dest io.github.sioyek.ecdict \
  --object-path /io/github/sioyek/ecdict \
  --method io.github.sioyek.ecdict.Prompt
```

Niri：把这一行放进 `binds { ... }`：

```kdl
Mod+S hotkey-overlay-title="打开 ECDICT 英汉词典" { spawn "gdbus" "call" "--session" "--dest" "io.github.sioyek.ecdict" "--object-path" "/io/github/sioyek/ecdict" "--method" "io.github.sioyek.ecdict.Prompt"; }
```

Hyprland：

```ini
bind = SUPER, S, exec, gdbus call --session --dest io.github.sioyek.ecdict --object-path /io/github/sioyek/ecdict --method io.github.sioyek.ecdict.Prompt
```

KDE Plasma 与 GNOME 可在系统键盘快捷键设置中绑定同一命令。

## 手动查询与状态检查

```bash
modules/sioyek-ecdict/.venv/bin/sioyek-ecdict lookup dependencies
systemctl --user status sioyek-ecdict.service
```

## 如何嵌入 Sioyek

安装器先在 `prefs_user.config` 中定义 `_ecdict`：它通过 `gdbus` 调用常驻服务，`%{selected_text}` 由 Sioyek 直接填入；随后在 `keys_user.config` 中写入 `_ecdict s`。Sioyek 的键位解析器要求命令与按键之间使用空格；如果误写成制表符，该行会被静默忽略，默认联网搜索便仍会生效。现在选中文字会直接送入常驻 D-Bus 服务，不经过浏览器、URI 处理器或剪贴板，也不访问网络。服务完成 SQLite 索引查询后，通过 GTK4 layer-shell 显示结果。

## 卸载

```bash
./modules/sioyek-ecdict/uninstall.sh
```

脚本会删除用户服务和本项目写入的 Sioyek 键位，恢复 Sioyek 默认的外部搜索前缀，同时保留项目目录和本地词典数据库。

## 开发验证

```bash
modules/sioyek-ecdict/.venv/bin/python -m unittest discover -s modules/sioyek-ecdict/tests -v
```
