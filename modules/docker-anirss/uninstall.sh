#!/usr/bin/env bash
set -euo pipefail

install_path="${CAMPUS_BIN_DIR:-$HOME/.local/bin}/docker-ass"

if [[ ! -e "$install_path" && ! -L "$install_path" ]]; then
    echo "docker-ass 未安装，无需卸载。"
    exit 0
fi

rm -f "$install_path"
printf '已移除 %s\n' "$install_path"
