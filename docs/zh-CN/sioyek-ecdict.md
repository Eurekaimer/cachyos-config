# Sioyek ECDICT 离线查词插件

[English](../en/sioyek-ecdict.md)

本仓库内置 `modules/sioyek-ecdict`，为原生 Linux 版 Sioyek 提供离线英汉查词。它没有并入通用快照恢复流程，因为首次安装需要下载并索引 ECDICT 数据集，应由用户显式执行。

## CachyOS 最快安装流程

先通过 AUR 安装一个 Sioyek 版本，再克隆本仓库并运行一个脚本：

```bash
yay -S sioyek-git

git clone https://github.com/Eurekaimer/cachyos-config.git
cd cachyos-config
./scripts/install-sioyek-ecdict.sh
```

包装脚本会通过 `pacman` 自动补齐 `uv`、`python-gobject` 和 `gtk4-layer-shell`，随后调用仓库内置插件的安装器。只预览、不修改系统时执行：

```bash
./scripts/install-sioyek-ecdict.sh --dry-run
```

安装后请保留此仓库目录，不要随意移动或删除。systemd 用户服务指向 `modules/sioyek-ecdict/.venv/` 中的虚拟环境。

## 使用效果

重启 Sioyek 后：

1. 在 PDF 中选中英文单词；
2. 按 `s`；
3. 屏幕右上角出现中文释义卡片，卡片可拖动，按 `Esc` 可关闭。

查询自动忽略大小写，可修复常见 PDF 断行连字符、解析 ECDICT 词形变化，并显示音标、词性、原形、词典等级和词频信息。首次下载 ECDICT 后，日常查询完全离线。

仓库中的 Niri 快照还把 `Super+S` 绑定为全局词典输入框。其他桌面环境可使用[模块 README](../../modules/sioyek-ecdict/README.zh-CN.md) 中的 D-Bus 命令配置系统快捷键。

## 安装器会修改什么

```mermaid
flowchart LR
    S[Sioyek 选中文字] --> K[_ecdict s]
    K --> D[常驻 D-Bus 服务]
    D --> Q[ECDICT SQLite 索引]
    Q --> P[GTK4 layer-shell 卡片]
```

安装器会：

- 用发行版包管理器安装原生 GTK 绑定；
- 重建 `modules/sioyek-ecdict/.venv/`，允许读取系统 Python 包，再按照已提交的
  `uv.lock` 执行 `uv sync --frozen`；
- 执行 `sioyek-ecdict bootstrap`：仅在缺少数据库时生成
  `${XDG_DATA_HOME:-~/.local/share}/sioyek-ecdict/ecdict.sqlite3`，重复安装时
  直接复用；
- 向 `~/.config/sioyek/prefs_user.config` 写入含 `%{selected_text}` 的
  `new_command _ecdict`；
- 向 `~/.config/sioyek/keys_user.config` 写入以普通空格分隔的 `_ecdict s`；
- 启用 `~/.config/systemd/user/sioyek-ecdict.service`，其 `ExecStart` 同时记录
  虚拟环境命令和 SQLite 数据库的准确路径。

这套边界是有意设计的：uv 管理 Python 项目和命令入口；`pacman` 管理
PyGObject、GTK4 与 Gtk4LayerShell，确保它们匹配宿主 ABI；`bootstrap` 只管理
生成的用户数据和集成配置，不会修改 `/etc/sioyek`。`_ecdict s` 中的空格不可
替换为制表符：Sioyek 会静默忽略制表符分隔的键位行，导致默认
`external_search s` 仍然生效。安装器会清理旧的联网搜索集成，并让本地词典
覆盖默认的 `s` 搜索。查询不使用浏览器、剪贴板轮询、翻译 API 或 API Key。

## 更新、状态与卸载

安装过程可重复执行。拉取仓库更新后再次运行：

```bash
./scripts/install-sioyek-ecdict.sh
```

检查服务或直接查询：

```bash
systemctl --user status sioyek-ecdict.service
modules/sioyek-ecdict/.venv/bin/sioyek-ecdict lookup Map
```

删除服务和本项目写入的 Sioyek 键位，同时保留已下载的数据库：

```bash
./modules/sioyek-ecdict/uninstall.sh
```

## 故障排查

- 安装后必须重启 Sioyek，因为它只在启动时读取键位文件。
- 请使用原生软件包或 AppImage；目前不支持 Flatpak 宿主集成。
- 确认 `~/.config/sioyek/keys_user.config` 末尾是使用普通空格的 `_ecdict s`。
- 没有弹出卡片时检查 `systemctl --user status sioyek-ecdict.service`。
- 运行插件测试：`modules/sioyek-ecdict/.venv/bin/python -m unittest discover -s modules/sioyek-ecdict/tests -v`。

SQLite 数据库位于仓库外的 XDG 数据目录，仓库内虚拟环境由 Git 忽略；两者均不会发布，插件源码也不包含凭据或机器专属路径。
