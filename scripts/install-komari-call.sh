#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
    cat <<'EOF'
Usage: scripts/install-komari-call.sh [OPTIONS]

Build and install the komari-call terminal companion (KOMABELIKA) from its
GitHub repository with cargo, then link it into ~/.local/bin. Requires a Rust
toolchain (CachyOS: sudo pacman -S rust, or rustup). First build takes a few
minutes; later runs use --force to refresh the binary.

This is an optional personal script: it is NOT part of the generic snapshot
restore, because not every machine needs it.

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

module_dir="$REPO_ROOT/modules/komari-call"
[[ -f "$module_dir/install.sh" ]] || die "Missing vendored module: $module_dir"

if (( DRY_RUN )); then
    print_cmd "$module_dir/install.sh"
    exit 0
fi

if ! command -v cargo >/dev/null 2>&1; then
    die "缺少 cargo。请先安装 Rust 工具链：sudo pacman -S rust（或 rustup）。"
fi

"$module_dir/install.sh"
log "komari-call 安装完成：运行 komari-call 启动。"
