#!/usr/bin/env bash
set -euo pipefail

module_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${BILI_LIVE_HIME_BIN_DIR:-$HOME/.local/bin}"
install_path="$bin_dir/bili-live-hime"
backup_dir="${CACHYOS_MODULE_BACKUPS:-$HOME/.local/state/cachyos-config/module-backups}"
project_dir="${BILI_LIVE_HIME_DIR:-$HOME/Projects/bili-live-hime}"
clone_url="https://github.com/Rsplwe/bili-live-hime.git"
binary="$project_dir/src-tauri/target/release/bili-live-hime"

die() {
    printf '安装失败：%s\n' "$*" >&2
    exit 1
}

[[ "$(uname -s)" == "Linux" ]] || die "目前只支持 Linux。"

mkdir -p "$bin_dir"

# 项目缺失时从上游克隆：仓库是公开的，构建产物不进快照。
if [[ ! -d "$project_dir" ]]; then
    command -v git >/dev/null 2>&1 || die "缺少 git，无法克隆 $clone_url。"
    printf '未找到 %s，正在从上游克隆...\n' "$project_dir"
    mkdir -p "$(dirname -- "$project_dir")"
    git clone --depth 1 "$clone_url" "$project_dir" || die "克隆 $clone_url 失败。"
fi

# 依赖与产物：缺什么补什么，已有产物不重建（用 bili-live-hime --rebuild 手动重建）。
if [[ ! -d "$project_dir/node_modules" ]]; then
    command -v npm >/dev/null 2>&1 || die "缺少 npm。请先安装 Node.js（sudo pacman -S nodejs npm）。"
    printf '正在安装 npm 依赖...\n'
    (cd "$project_dir" && npm install) || die "npm install 失败。"
fi

if [[ ! -x "$binary" ]]; then
    command -v cargo >/dev/null 2>&1 || die "缺少 cargo。请先安装 Rust 工具链（sudo pacman -S rust，或 rustup）。"
    command -v npm >/dev/null 2>&1 || die "缺少 npm。请先安装 Node.js（sudo pacman -S nodejs npm）。"
    printf '正在构建发布版（首次约需数分钟）...\n'
    (cd "$project_dir" && npm run tauri build -- --no-bundle) || die "Tauri 构建失败。"
fi

# 备份已存在的旧版本
if [[ -e "$install_path" || -L "$install_path" ]]; then
    mkdir -p "$backup_dir"
    backup_path="$backup_dir/bili-live-hime.$(date +%Y%m%d-%H%M%S)"
    cp -a "$install_path" "$backup_path" || die "备份 $install_path 失败"
    printf '已备份旧版本到 %s\n' "$backup_path"
fi

install -m 0755 "$module_dir/bili-live-hime" "$install_path"
printf '已安装 bili-live-hime 到 %s\n' "$install_path"
printf '运行 bili-live-hime 启动；重新构建加 --rebuild。\n'
