#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/restore.sh
source "$SCRIPT_DIR/lib/restore.sh"

require_non_root_user
mode=
while (($#)); do
    case "$1" in
        --capture|--restore)
            [[ -z "$mode" ]] || die "Choose exactly one of --capture or --restore"
            mode=${1#--}
            ;;
        --dry-run) DRY_RUN=1 ;;
        -h|--help)
            cat <<'EOF'
Usage: scripts/sync-timewarrior.sh (--capture|--restore) [--dry-run]

Sync only the Timewarrior files listed in manifests/home-paths.txt:
  --capture  Copy $HOME/.config/timewarrior configuration and totals into the repo.
  --restore  Restore those files to $HOME, backing up existing files first.

Uses the standard ~/.config/timewarrior layout. Timing data is never copied
or replaced. Other extensions are left alone. No package installation or Git
commit/push is performed. Install timew and python before running reports.
EOF
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done
[[ -n "$mode" ]] || die "Choose --capture or --restore (see --help)"

paths=()
while IFS= read -r relative; do
    case "$relative" in
        .config/timewarrior/*) paths+=("$relative") ;;
    esac
done < <(read_list "$REPO_ROOT/manifests/home-paths.txt")
((${#paths[@]})) || die "No Timewarrior paths in home manifest"

source_root=${HOME:?}
destination_root="$REPO_ROOT/configs/home"
if [[ "$mode" == restore ]]; then
    source_root=$destination_root
    destination_root=$HOME
fi
# Validate every source before replacing any destination.
for relative in "${paths[@]}"; do
    [[ -f "$source_root/$relative" && ! -L "$source_root/$relative" ]] || die "Missing regular file: $source_root/$relative"
done

backup_root="$HOME/.local/state/cachyos-config/backups/$RESTORE_TIMESTAMP/home"
for relative in "${paths[@]}"; do
    if [[ "$mode" == restore ]]; then
        replace_user_path "$source_root/$relative" "$destination_root/$relative" "$relative" "$backup_root"
    else
        run mkdir -p -- "$(dirname -- "$destination_root/$relative")"
        run cp -a -- "$source_root/$relative" "$destination_root/$relative"
    fi
done
if [[ "$mode" == restore ]] && (( BACKUP_ENABLED )); then
    log "Previous configuration backup: $backup_root"
fi
log "Timewarrior $mode complete (timing data untouched)"
