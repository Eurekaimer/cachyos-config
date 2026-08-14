#!/usr/bin/env bash
set -euo pipefail

module_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${CAMPUS_BIN_DIR:-$HOME/.local/bin}"
install_path="$bin_dir/campus-login"
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
    backup_path="$backup_dir/campus-login.$(date +%Y%m%d-%H%M%S)"
    cp -a "$install_path" "$backup_path" || die "备份 $install_path 失败"
    printf '已备份旧版本到 %s\n' "$backup_path"
fi

install -m 0755 "$module_dir/campus-login" "$install_path"
printf '已安装 campus-login 到 %s\n' "$install_path"
printf '运行 campus-login 以直连模式打开校园网认证页。\n'
