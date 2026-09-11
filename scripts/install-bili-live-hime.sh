#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
    cat <<'EOF'
Usage: scripts/install-bili-live-hime.sh [OPTIONS]

Install the bili-live-hime launcher into ~/.local/bin. The launcher starts the
release build of ~/Projects/bili-live-hime (override with BILI_LIVE_HIME_DIR),
cloning the upstream project and building it when missing.

bili-live-hime is the lightweight Bilibili live-streaming companion (B站直播姬
替代工具): it fetches the RTMP/SRT ingest URL and stream key, edits room title
and category, and shows danmaku, so OBS can push with those credentials.

This is an optional personal script: it is NOT part of the generic snapshot
restore, because the project sources and build output live outside $HOME
whitelists and every rebuild is machine-local.

Options:
  --dry-run   Print the module install command without changing files
  -h, --help  Show this help
EOF
}

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help)
            usage
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

require_non_root_user

module_dir="$REPO_ROOT/modules/bili-live-hime"
[[ -f "$module_dir/install.sh" ]] || die "Missing vendored module: $module_dir"

if (( DRY_RUN )); then
    print_cmd "$module_dir/install.sh"
    exit 0
fi

"$module_dir/install.sh"
log "bili-live-hime 安装完成：运行 bili-live-hime 启动，--rebuild 重新构建。"
