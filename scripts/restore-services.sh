#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_non_root_user
start_now=0
while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --now) start_now=1 ;;
        -h|--help)
            cat <<'EOF'
Usage: scripts/restore-services.sh [--dry-run] [--now]

Enables captured system and user units that exist on the target machine.
--now also starts them immediately; without it, they start on next boot/login.
EOF
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

enable_system_unit() {
    local unit=$1
    if ! systemctl list-unit-files --no-legend "$unit" 2>/dev/null | awk '{print $1}' | grep -Fxq "$unit"; then
        warn "System unit unavailable, skipped: $unit"
        return 0
    fi
    if (( start_now )); then
        run sudo systemctl enable --now "$unit"
    else
        run sudo systemctl enable "$unit"
    fi
}

enable_user_unit() {
    local unit=$1
    if ! systemctl --user list-unit-files --no-legend "$unit" 2>/dev/null | awk '{print $1}' | grep -Fxq "$unit"; then
        warn "User unit unavailable, skipped: $unit"
        return 0
    fi
    if (( start_now )); then
        run systemctl --user enable --now "$unit"
    else
        run systemctl --user enable "$unit"
    fi
}

log "Restoring system service enablement"
while IFS= read -r unit; do
    enable_system_unit "$unit"
done < <(read_list "$REPO_ROOT/packages/system-services.txt")

log "Restoring user service enablement"
while IFS= read -r unit; do
    enable_user_unit "$unit"
done < <(read_list "$REPO_ROOT/packages/user-services.txt")

log "Service enablement restored"
