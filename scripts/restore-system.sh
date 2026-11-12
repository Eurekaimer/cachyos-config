#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/restore.sh
source "$SCRIPT_DIR/lib/restore.sh"

require_non_root_user

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --no-backup) BACKUP_ENABLED=0 ;;
        -h|--help)
            cat <<'EOF'
Usage: scripts/restore-system.sh [--dry-run] [--no-backup]

Directly replaces the portable /etc snapshots declared by
manifests/system-portable-paths.txt. By default the replaced files are copied to
/var/backups/cachyos-config, which is cleared first, so exactly one backup
generation is kept.
EOF
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

backup_root="/var/backups/cachyos-config"

restore_group() {
    local snapshot_root=$1 manifest=$2 label=$3
    log "Replacing $label system configuration"
    local relative
    while IFS= read -r relative; do
        replace_system_path "$snapshot_root/$relative" "/$relative" "$relative" "$backup_root"
    done < <(read_list "$manifest")
}

if (( BACKUP_ENABLED )) && (( ! DRY_RUN )); then
    sudo rm -rf -- "$backup_root"
    sudo mkdir -p -- "$backup_root"
fi

restore_group "$REPO_ROOT/configs/system/portable" \
    "$REPO_ROOT/manifests/system-portable-paths.txt" portable

if (( ! DRY_RUN )); then
    sudo systemctl daemon-reload
    command -v locale-gen >/dev/null 2>&1 && sudo locale-gen
    command -v mkinitcpio >/dev/null 2>&1 && sudo mkinitcpio -P
fi

(( BACKUP_ENABLED )) && log "Previous system configuration backup: $backup_root"
log "System configuration restored; reboot after the complete restore"
