#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/restore.sh
source "$SCRIPT_DIR/lib/restore.sh"
# shellcheck source=scripts/lib/profile.sh
source "$SCRIPT_DIR/lib/profile.sh"

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

Replaces managed paths below the current user's home directory, retaining all
existing KOReader data/dict contents in preference to snapshot dictionaries.
Dictionary symlinks are copied as their contents; retention also applies with
--no-backup. Each declared path is restored from the application tree that owns
it (configs/apps/<app>/<path>). By default existing paths are copied to
~/.local/state/cachyos-config/backup/home, which is cleared first, so exactly
one backup generation is kept.
Absolute references to the captured home are rewritten in configuration only,
never in KOReader dictionaries. --dry-run does not change any files.
EOF
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

manifest="$REPO_ROOT/manifests/home-paths.txt"
backup_root="$target_home/.local/state/cachyos-config/backup/home"

if (( BACKUP_ENABLED )) && (( ! DRY_RUN )); then
    rm -rf -- "$backup_root"
    mkdir -p -- "$backup_root"
fi

log "Replacing managed user configuration in $target_home"
# Every manifest row names the application that declares it, so the source is
# the same path inside that app's tree.
while IFS=$'\t' read -r app path; do
    [[ -n "$app" ]] || continue
    replace_user_path "$REPO_ROOT/configs/apps/$app/$path" "$target_home/$path" "$path" "$backup_root"
done < <(apps_manifest "$REPO_ROOT")

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
