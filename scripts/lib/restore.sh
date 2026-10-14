#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

RESTORE_TIMESTAMP=${RESTORE_TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}
BACKUP_ENABLED=${BACKUP_ENABLED:-1}

backup_user_path() {
    local destination=$1 relative=$2 backup_root=$3
    [[ -e "$destination" || -L "$destination" ]] || return 0
    if (( BACKUP_ENABLED )); then
        run mkdir -p -- "$(dirname -- "$backup_root/$relative")"
        run cp -a -- "$destination" "$backup_root/$relative"
    fi
}

# Stage the replacement before moving anything live. Materializing dictionary
# symlinks also protects targets located elsewhere inside the old KOReader tree.
replace_koreader_path() (
    local source=$1 destination=$2 relative=$3 backup_root=$4
    local stage replacement_installed=0
    if (( DRY_RUN )); then
        backup_user_path "$destination" "$relative" "$backup_root"
        log "Would replace $relative while retaining all existing data/dict contents (including symlink targets)"
        return 0
    fi

    run mkdir -p -- "$(dirname -- "$destination")" || return
    stage=$(mktemp -d -- "$(dirname -- "$destination")/.koreader-restore.XXXXXXXX") || return
    cleanup_koreader_restore() {
        local status=$?
        trap - EXIT HUP INT TERM
        if [[ -e "$stage/original" || -L "$stage/original" ]] &&
            (( ! replacement_installed )); then
            if [[ -e "$destination" || -L "$destination" ]] ||
                ! mv -T -- "$stage/original" "$destination"; then
                warn "KOReader rollback could not finish; original configuration and dictionaries remain at $stage/original"
                exit 1
            fi
        fi
        rm -rf -- "$stage"
        exit "$status"
    }
    trap cleanup_koreader_restore EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM

    run mkdir -- "$stage/new" || return
    run cp -a -- "$source/." "$stage/new/" || return
    # Never remove dictionary paths through a snapshot's data-directory symlink.
    if [[ -L "$stage/new/data" ]]; then
        run rm -- "$stage/new/data" || return
        run mkdir -- "$stage/new/data" || return
        run cp -a -- "$source/data/." "$stage/new/data/" || return
    fi
    run mkdir -p -- "$stage/new/data" || return
    run rm -rf -- "$stage/new/data/dict" || return
    run cp -aL -- "$destination/data/dict" "$stage/new/data/dict" || return
    backup_user_path "$destination" "$relative" "$backup_root" || return

    run mv -T -- "$destination" "$stage/original" || return
    run mv -T -- "$stage/new" "$destination" || return
    replacement_installed=1
)

replace_user_path() {
    local source=$1 destination=$2 relative=$3 backup_root=$4
    [[ -e "$source" || -L "$source" ]] || { warn "Snapshot missing, skipped: $relative"; return 0; }
    if [[ "$relative" == .config/koreader ]] &&
        [[ -e "$destination/data/dict" || -L "$destination/data/dict" ]]; then
        replace_koreader_path "$source" "$destination" "$relative" "$backup_root"
        return
    fi
    backup_user_path "$destination" "$relative" "$backup_root"
    run rm -rf -- "$destination"
    run mkdir -p -- "$(dirname -- "$destination")"
    run cp -a -- "$source" "$destination"
}

backup_system_path() {
    local destination=$1 relative=$2 backup_root=$3
    if (( DRY_RUN )); then
        [[ -e "$destination" || -L "$destination" ]] || return 0
    else
        sudo test -e "$destination" || sudo test -L "$destination" || return 0
    fi
    if (( BACKUP_ENABLED )); then
        run sudo mkdir -p -- "$(dirname -- "$backup_root/$relative")"
        run sudo cp -a -- "$destination" "$backup_root/$relative"
    fi
}

replace_system_path() {
    local source=$1 destination=$2 relative=$3 backup_root=$4
    [[ -e "$source" || -L "$source" ]] || { warn "Snapshot missing, skipped: /$relative"; return 0; }
    backup_system_path "$destination" "$relative" "$backup_root"
    run sudo rm -rf -- "$destination"
    run sudo mkdir -p -- "$(dirname -- "$destination")"
    run sudo cp -a -- "$source" "$destination"
    run sudo chown -R -- root:root "$destination"
}

rewrite_captured_home() {
    local target_home=$1 manifest=$2
    local captured_home
    captured_home=$(<"$REPO_ROOT/state/captured-home.txt")
    [[ -n "$captured_home" && "$captured_home" != "$target_home" ]] || return 0
    (( DRY_RUN )) && { log "Would rewrite $captured_home to $target_home in managed text files"; return 0; }

    python3 - "$target_home" "$captured_home" "$manifest" <<'PY'
from pathlib import Path
import sys

target_home = Path(sys.argv[1])
old = sys.argv[2].encode()
new = sys.argv[1].encode()
manifest = Path(sys.argv[3])

# Dictionary definitions are data, not configuration, even when plain text.
dictionary_root = target_home / ".config/koreader/data/dict"
dictionary_resolved = dictionary_root.resolve()

for raw in manifest.read_text(encoding="utf-8").splitlines():
    relative = raw.split("#", 1)[0].strip()
    if not relative:
        continue
    root = target_home / relative
    paths = root.rglob("*") if root.is_dir() else (root,)
    for path in paths:
        if path == dictionary_root or dictionary_root in path.parents:
            continue
        if not path.is_file() or path.is_symlink():
            continue
        resolved = path.resolve()
        if resolved == dictionary_resolved or dictionary_resolved in resolved.parents:
            continue
        data = path.read_bytes()
        if b"\0" not in data and old in data:
            path.write_bytes(data.replace(old, new))
PY
}
