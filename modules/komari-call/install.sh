#!/usr/bin/env bash
set -euo pipefail

die() {
    printf '安装失败：%s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "缺少 $1。$2"
}

[[ "$(uname -s)" == "Linux" ]] || die "目前只支持 Linux。"
require_command cargo "请先安装 Rust 工具链（rustup 或发行版 rust 包）。"
require_command git "请安装 git。"

repo_url="https://github.com/Eurekaimer/KOMABELIKA.git"
bin_dir="${KOMARI_BIN_DIR:-$HOME/.local/bin}"
cargo_home="${CARGO_HOME:-$HOME/.cargo}"
cargo_bin="$cargo_home/bin/komari-call"

printf '从 %s 构建安装 komari-call（首次构建需要几分钟）...\n' "$repo_url"
cargo install --git "$repo_url" --locked --force komari-call
[[ -x "$cargo_bin" ]] || die "构建完成但找不到 $cargo_bin，请检查 CARGO_HOME 设置。"

mkdir -p "$bin_dir"
ln -sfn "$cargo_bin" "$bin_dir/komari-call"
printf '已安装 komari-call：%s -> %s\n' "$bin_dir/komari-call" "$cargo_bin"
