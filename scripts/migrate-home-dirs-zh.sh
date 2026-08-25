#!/usr/bin/env bash
# Migrate legacy Chinese-named XDG directories to English names.
#
# Old installs created ~/桌面 ~/下载 ~/文档 ... (from a zh_CN locale before the
# locale was switched). This renames them to the English names the managed
# user-dirs.dirs snapshot expects. Idempotent: exits silently when nothing to do.
#
# Must run BEFORE restore-user.sh (which restores .config/user-dirs.dirs).
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_non_root_user

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help)
            cat <<'EOF'
Usage: scripts/migrate-home-dirs-zh.sh [--dry-run]

Renames Chinese-named XDG directories (桌面/下载/文档/...) under $HOME to their
English equivalents. Skips any mapping whose target already exists. No-op when
no Chinese directory is present.
EOF
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

# zh name -> English name (matches the managed user-dirs.dirs snapshot)
declare -A ZH_TO_EN=(
    [桌面]=Desktop
    [下载]=Downloads
    [模板]=Templates
    [公共]=Public
    [文档]=Documents
    [音乐]=Music
    [图片]=Pictures
    [视频]=Videos
    [项目]=Projects
)

migrated=0
for zh in "${!ZH_TO_EN[@]}"; do
    en=${ZH_TO_EN[$zh]}
    src="$HOME/$zh"
    dst="$HOME/$en"
    [[ -d "$src" ]] || continue
    if [[ -e "$dst" ]]; then
        warn "Both ~/$zh and ~/$en exist; leaving ~/$zh in place"
        continue
    fi
    log "Moving ~/$zh -> ~/$en"
    run mv -- "$src" "$dst"
    migrated=$((migrated + 1))
done

# Recompute user-dirs.dirs from the current locale; restore-user.sh later
# replaces it with the managed English snapshot anyway.
if (( ! DRY_RUN )) && command -v xdg-user-dirs-update >/dev/null 2>&1; then
    xdg-user-dirs-update >/dev/null 2>&1 || true
fi

(( migrated )) && log "Migrated $migrated directory(s); log out and back in to refresh the file manager"
log "Home directory migration complete"
