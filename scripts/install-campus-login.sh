#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
    cat <<'EOF'
Usage: scripts/install-campus-login.sh [OPTIONS]

Install the campus network direct-connect login helper (Nankai netauth) into
~/.local/bin. It opens the campus authentication page in an isolated temporary
Chrome profile with all proxy environment variables cleared and direct
connection forced, so Clash/mihomo cannot intercept the captive portal.

This is an optional personal script: it is NOT part of the generic snapshot
restore, because not every machine needs campus authentication.

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

module_dir="$REPO_ROOT/modules/campus-login"
[[ -f "$module_dir/install.sh" ]] || die "Missing vendored module: $module_dir"

# 浏览器缺失只是运行时问题，不阻止安装，仅提醒
browser=""
for candidate in google-chrome-stable google-chrome chromium; do
    if command -v "$candidate" >/dev/null 2>&1; then
        browser=$candidate
        break
    fi
done
if [[ -z "$browser" ]]; then
    warn "未检测到 Chrome/Chromium；运行时脚本会提示安装浏览器。"
fi

if (( DRY_RUN )); then
    print_cmd "$module_dir/install.sh"
    exit 0
fi

"$module_dir/install.sh"
log "campus-login 安装完成：运行 campus-login 打开校园网认证页。"
