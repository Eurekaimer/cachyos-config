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

replace_user_path() {
    local source=$1 destination=$2 relative=$3 backup_root=$4
    [[ -e "$source" || -L "$source" ]] || { warn "Snapshot missing, skipped: $relative"; return 0; }
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

for raw in manifest.read_text(encoding="utf-8").splitlines():
    relative = raw.split("#", 1)[0].strip()
    if not relative:
        continue
    root = target_home / relative
    paths = root.rglob("*") if root.is_dir() else (root,)
    for path in paths:
        if not path.is_file() or path.is_symlink():
            continue
        data = path.read_bytes()
        if b"\0" not in data and old in data:
            path.write_bytes(data.replace(old, new))
PY
}
