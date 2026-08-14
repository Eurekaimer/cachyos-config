#!/usr/bin/env bash
set -euo pipefail

module_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${CAMPUS_BIN_DIR:-$HOME/.local/bin}"
install_path="$bin_dir/docker-ass"
backup_dir="${CACHYOS_MODULE_BACKUPS:-$HOME/.local/state/cachyos-config/module-backups}"

die() {
    printf '安装失败：%s\n' "$*" >&2
    exit 1
}

[[ "$(uname -s)" == "Linux" ]] || die "目前只支持 Linux。"

mkdir -p "$bin_dir"

# 备份已存在的旧版本
if [[ -e "$install_path" || -L "$install_path" ]]; then
    mkdir -p "$backup_dir"
    backup_path="$backup_dir/docker-ass.$(date +%Y%m%d-%H%M%S)"
    cp -a "$install_path" "$backup_path" || die "备份 $install_path 失败"
    printf '已备份旧版本到 %s\n' "$backup_path"
fi

install -m 0755 "$module_dir/docker-ass" "$install_path"
printf '已安装 docker-ass 到 %s\n' "$install_path"
printf '默认 compose 文件：$HOME/Projects/ASS/docker-compose.yml（可用 ANI_RSS_COMPOSE_FILE 覆盖）\n'
