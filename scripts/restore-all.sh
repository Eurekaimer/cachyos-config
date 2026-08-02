#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_non_root_user

dry_run=0
with_hardware=0
skip_aur=0
no_backup=0
start_now=0
while (($#)); do
    case "$1" in
        --dry-run) dry_run=1 ;;
        --with-hardware) with_hardware=1 ;;
        --skip-aur) skip_aur=1 ;;
        --no-backup) no_backup=1 ;;
        --now) start_now=1 ;;
        -h|--help)
            cat <<'EOF'
Usage: scripts/restore-all.sh [OPTIONS]

Full one-shot restore for a fresh or existing CachyOS install: packages and
toolchains, portable system configuration, user configuration and dconf, then
service enablement. Safe on any machine, including one with a different
username; captured home paths are rewritten for the current user.

Machine-bound state is never touched by default: disk UUIDs, /etc/machine-id,
/etc/fstab, and /etc/hostname are excluded unless --with-hardware is passed
after explicit review on the same disks/host.

Options:
  --dry-run        Print every replacement/install command without changing files
  --with-hardware  Also replace /etc/fstab and /etc/hostname (same hardware only)
  --skip-aur       Do not install captured AUR packages
  --no-backup      Replace configuration without saving previous files
  --now            Start enabled services immediately instead of after reboot/login
EOF
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

export RESTORE_TIMESTAMP=${RESTORE_TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}
common_args=()
(( dry_run )) && common_args+=(--dry-run)

install_args=("${common_args[@]}")
(( skip_aur )) && install_args+=(--skip-aur)

system_args=("${common_args[@]}")
user_args=("${common_args[@]}")
(( with_hardware )) && system_args+=(--with-hardware)
if (( no_backup )); then
    system_args+=(--no-backup)
    user_args+=(--no-backup)
fi

service_args=("${common_args[@]}")
(( start_now )) && service_args+=(--now)

log "Stage 1/5: packages and toolchains"
"$SCRIPT_DIR/install-packages.sh" "${install_args[@]}"
log "Stage 2/5: system configuration"
"$SCRIPT_DIR/restore-system.sh" "${system_args[@]}"
log "Stage 3/5: user configuration"
"$SCRIPT_DIR/restore-user.sh" "${user_args[@]}"
log "Stage 4/5: SDDM theme"
"$SCRIPT_DIR/sync-sddm-theme.sh" --from-snapshot "${common_args[@]}"
log "Stage 5/5: service enablement"
"$SCRIPT_DIR/restore-services.sh" "${service_args[@]}"

log "Full restore complete"
(( dry_run )) || warn "Reboot to activate kernel/initramfs, login shell, and all enabled services."
