#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/restore.sh
source "$SCRIPT_DIR/lib/restore.sh"

require_non_root_user

include_hardware=0
while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --no-backup) BACKUP_ENABLED=0 ;;
        --with-hardware) include_hardware=1 ;;
        -h|--help)
            cat <<'EOF'
Usage: scripts/restore-system.sh [--dry-run] [--no-backup] [--with-hardware]

Directly replaces portable /etc snapshots. --with-hardware additionally replaces
/etc/fstab and /etc/hostname and is only safe for the same disks/host layout.
Location-generated reference files such as mirrorlist are never auto-restored.
EOF
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

backup_root="/var/backups/cachyos-config/$RESTORE_TIMESTAMP"

restore_group() {
    local snapshot_root=$1 manifest=$2 label=$3
    log "Replacing $label system configuration"
    local relative
    while IFS= read -r relative; do
        replace_system_path "$snapshot_root/$relative" "/$relative" "$relative" "$backup_root"
    done < <(read_list "$manifest")
}

restore_group "$REPO_ROOT/configs/system/portable" \
    "$REPO_ROOT/manifests/system-portable-paths.txt" portable

if (( include_hardware )); then
    warn "Applying disk- and host-specific configuration because --with-hardware was requested"
    restore_group "$REPO_ROOT/configs/system/hardware" \
        "$REPO_ROOT/manifests/system-hardware-paths.txt" hardware-specific
fi

if (( ! DRY_RUN )); then
    sudo systemctl daemon-reload
    command -v locale-gen >/dev/null 2>&1 && sudo locale-gen
    command -v mkinitcpio >/dev/null 2>&1 && sudo mkinitcpio -P
fi

(( BACKUP_ENABLED )) && log "Previous system configuration backup: $backup_root"
log "System configuration restored; reboot after the complete restore"
