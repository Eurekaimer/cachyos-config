#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
    cat <<'EOF'
Usage: scripts/install-docker-anirss.sh [OPTIONS]

Install the ANI-RSS + qBittorrent docker stack helper into ~/.local/bin as
docker-ass. It manages the compose stack under ~/Projects/ASS by default
(override with ANI_RSS_COMPOSE_FILE) and opens the ANI-RSS / qBittorrent web
interfaces after startup.

This is an optional personal script: it is NOT part of the generic snapshot
restore, because it depends on a machine-local compose file.

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

module_dir="$REPO_ROOT/modules/docker-anirss"
[[ -f "$module_dir/install.sh" ]] || die "Missing vendored module: $module_dir"

if (( DRY_RUN )); then
    print_cmd "$module_dir/install.sh"
    exit 0
fi

"$module_dir/install.sh"
log "docker-ass 安装完成：运行 docker-ass start 启动 ANI-RSS 容器栈。"
