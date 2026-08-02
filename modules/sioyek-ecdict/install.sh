#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$project_dir"

# Stop immediately with an actionable dependency message.
die() {
    printf '安装失败：%s\n' "$*" >&2
    exit 1
}

# Require a host command before changing the user's configuration.
require_command() {
    command -v "$1" >/dev/null 2>&1 || die "缺少 $1。$2"
}

[[ "$(uname -s)" == "Linux" ]] || die "目前只支持 Linux。"
require_command uv "请先安装 uv：https://docs.astral.sh/uv/getting-started/installation/"
require_command sioyek "请先安装原生 Linux 版 Sioyek（暂不支持 Flatpak 沙箱）。"
require_command gdbus "请安装 GLib 命令行工具。"
require_command systemctl "需要 systemd user service 保持词典热启动。"

python_bin="${PYTHON:-python3}"
require_command "$python_bin" "请安装 Python 3.11 或更高版本。"

# Validate GTK bindings and layer-shell before downloading the dictionary.
"$python_bin" - <<'PY' || die "缺少 PyGObject、GTK4 或 Gtk4LayerShell。请参考 README 的发行版依赖。"
import gi
gi.require_version("Gdk", "4.0")
gi.require_version("Gio", "2.0")
gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gdk, Gio, Gtk, Gtk4LayerShell
PY

# Rebuild a reproducible uv environment while exposing Arch's GTK bindings.
uv venv --clear --python "$(command -v "$python_bin")" --system-site-packages .venv
uv sync --frozen

# Import ECDICT once, then idempotently refresh Sioyek and the user service.
uv run --no-sync sioyek-ecdict bootstrap
printf '\n安装完成。重载 Sioyek 后：\n'
printf '  s       查询选中的英文（联网搜索已禁用）\n'
printf '  Super+s 打开全局词典输入框（需按 README 配置桌面快捷键）\n'
