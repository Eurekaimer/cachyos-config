#!/usr/bin/env bash
set -euo pipefail

install_path="${BILI_LIVE_HIME_BIN_DIR:-$HOME/.local/bin}/bili-live-hime"

if [[ ! -e "$install_path" && ! -L "$install_path" ]]; then
    echo "bili-live-hime 启动器未安装，无需卸载。"
    exit 0
fi

rm -f "$install_path"
printf '已移除 %s\n' "$install_path"
printf '项目目录与构建产物保留在 %s。\n' "${BILI_LIVE_HIME_DIR:-$HOME/Projects/bili-live-hime}"
