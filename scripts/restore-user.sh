#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/restore.sh
source "$SCRIPT_DIR/lib/restore.sh"

require_non_root_user

target_home=${HOME:?}
skip_dconf=0
while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --no-backup) BACKUP_ENABLED=0 ;;
        --skip-dconf) skip_dconf=1 ;;
        -h|--help)
            cat <<'EOF'
Usage: scripts/restore-user.sh [--dry-run] [--no-backup] [--skip-dconf]

Directly replaces every managed path below the current user's home directory.
By default existing paths are copied to ~/.local/state/cachyos-config/backups/.
Absolute references to the captured home are rewritten for the current user.
EOF
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

manifest="$REPO_ROOT/manifests/home-paths.txt"
snapshot_root="$REPO_ROOT/configs/home"
backup_root="$target_home/.local/state/cachyos-config/backups/$RESTORE_TIMESTAMP/home"

log "Replacing managed user configuration in $target_home"
while IFS= read -r relative; do
    replace_user_path "$snapshot_root/$relative" "$target_home/$relative" "$relative" "$backup_root"
done < <(read_list "$manifest")

rewrite_captured_home "$target_home" "$manifest"

if (( ! skip_dconf )) && [[ -s "$REPO_ROOT/configs/dconf/user.ini" ]]; then
    if command -v dconf >/dev/null 2>&1; then
        if (( DRY_RUN )); then
            log "Would load configs/dconf/user.ini into the current user's dconf database"
        else
            dconf load / <"$REPO_ROOT/configs/dconf/user.ini"
        fi
    else
        warn "dconf is unavailable; dconf snapshot was skipped"
    fi
fi

(( BACKUP_ENABLED )) && log "Previous user configuration backup: $backup_root"
log "User configuration restored"
