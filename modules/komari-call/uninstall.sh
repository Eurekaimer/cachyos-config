#!/usr/bin/env bash
set -euo pipefail

bin_dir="${KOMARI_BIN_DIR:-$HOME/.local/bin}"
link_path="$bin_dir/komari-call"

rm -f "$link_path"

if cargo uninstall komari-call >/dev/null 2>&1; then
    printf '已卸载 komari-call（~/.cargo/bin）。\n'
else
    printf 'komari-call 未通过 cargo 安装，已跳过（仅移除符号链接）。\n'
fi
