#!/usr/bin/env bash
# Sync-record helpers: remember the revision this machine last reconciled with,
# so a later run inspects only what moved instead of re-scanning every managed
# path.
#
# The record is LOCAL machine state (never committed, never restored):
#
#   ~/.local/state/cachyos-config/sync-record.txt
#
# Fields:
#   revision    commit HEAD pointed at during the last reconciliation
#   index_hash  sha256 over `git ls-files -s` for the managed trees
#   paths_hash  sha256 over the declared $HOME paths
#
# index_hash is deliberately taken from the index, not from HEAD: committing an
# already-captured tree does not change it, while pulling new commits does. So
# "capture, then commit" stays in step, and a pull shows up as pending work.
#
# What this answers: has the REPOSITORY moved since this machine last
# reconciled? Verifying that the live $HOME still matches the snapshot is a
# different question that needs the full scan (`scripts/sync-configs.sh
# --to-snapshot --dry-run`); see docs/*/capture.md.
#
# shellcheck disable=SC2154  # die/log/warn come from scripts/lib/common.sh

# Hosts the record helpers rely on; loaded here so every caller can source this
# file alone (capture.sh, restore-user.sh, sync-status.sh).
if ! declare -F apps_manifest >/dev/null 2>&1; then
    # shellcheck source=scripts/lib/profile.sh
    source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/profile.sh"
fi

# Managed trees whose content defines the sync identity.
SYNC_TRACKED_TREES=(configs manifests packages state)

sync_state_dir() {
    printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}/cachyos-config"
}

sync_record_file() {
    printf '%s/sync-record.txt\n' "$(sync_state_dir)"
}

sync_revision() {
    local repo_root=${1:-$REPO_ROOT}
    git -C "$repo_root" rev-parse HEAD 2>/dev/null || printf 'unknown\n'
}

sync_revision_subject() {
    local repo_root=${1:-$REPO_ROOT}
    git -C "$repo_root" log -1 --format=%s 2>/dev/null || printf 'unknown\n'
}

# sha256 over the managed trees' working content plus their paths. Content, not
# index or HEAD, so the value survives "capture, then commit" (the files do not
# change) yet still moves when a pull rewrites them. Untracked files count too.
sync_tree_hash() {
    local repo_root=${1:-$REPO_ROOT}
    find "${SYNC_TRACKED_TREES[@]/#/$repo_root/}" -path '*/.git' -prune -o -type f -print0 \
        2>/dev/null \
        | LC_ALL=C sort -z \
        | xargs -0 -r sha256sum \
        | sha256sum | cut -d' ' -f1
}

# sha256 over the declared $HOME paths: catches allowlist edits before any
# content differs.
sync_paths_hash() {
    local repo_root=${1:-$REPO_ROOT}
    apps_manifest "$repo_root" | cut -f2 | LC_ALL=C sort -u | sha256sum | cut -d' ' -f1
}

# Read one field from an existing record ("<key>=<value>"), empty when absent.
sync_record_get() {
    local key=$1 record
    record=$(sync_record_file)
    [[ -r "$record" ]] || return 0
    sed -n -e "s/^${key}=//p" "$record" | head -n1
}

have_sync_record() {
    [[ -r "$(sync_record_file)" ]]
}

# Write the record atomically. Extra "key=value" arguments are appended.
write_sync_record() {
    local dir tmp
    dir=$(sync_state_dir)
    tmp="$dir/sync-record.txt.tmp.$$"
    mkdir -p -- "$dir"
    {
        printf 'timestamp=%s\n' "$(date --iso-8601=seconds)"
        printf 'revision=%s\n' "$(sync_revision)"
        printf 'revision_subject=%s\n' "$(sync_revision_subject)"
        printf 'tree_hash=%s\n' "$(sync_tree_hash)"
        printf 'paths_hash=%s\n' "$(sync_paths_hash)"
        printf 'user=%s\n' "${USER:-unknown}"
        printf 'home=%s\n' "$HOME"
        if (($#)); then printf '%s\n' "$@"; fi
    } >"$tmp"
    mv -- "$tmp" "$dir/sync-record.txt"
}

# Uncommitted managed changes (modifications and untracked files).
sync_dirty_files() {
    local repo_root=${1:-$REPO_ROOT}
    git -C "$repo_root" status --porcelain -- "${SYNC_TRACKED_TREES[@]}" 2>/dev/null
}

# Repository-relative managed files added between the recorded revision and
# HEAD. Exit 2 when the recorded revision is not an ancestor (rewritten history).
sync_changed_since_record() {
    local repo_root=${1:-$REPO_ROOT} recorded current
    recorded=$(sync_record_get revision)
    [[ -n "$recorded" ]] || return 1
    current=$(sync_revision "$repo_root")
    [[ "$recorded" != "$current" ]] || return 0
    git -C "$repo_root" merge-base --is-ancestor "$recorded" "$current" 2>/dev/null || return 2
    git -C "$repo_root" diff --name-only "$recorded" "$current" -- "${SYNC_TRACKED_TREES[@]}"
}

# Map repository-relative paths (stdin) to the managed $HOME paths they affect.
# configs/home and configs/apps both collapse onto the declared home paths, and
# nested entries under one declared directory are folded into the directory.
sync_home_paths_for() {
    local repo_root=${1:-$REPO_ROOT}
    local manifest rel app path
    manifest=$(apps_manifest "$repo_root")
    while IFS= read -r rel; do
        [[ -n "$rel" ]] || continue
        case "$rel" in
            configs/home/*)
                path=${rel#configs/home/}
                ;;
            configs/apps/*)
                # configs/apps/<app>/<path> -> declared <path> of that app
                app=${rel#configs/apps/}
                app=${app%%/*}
                path=${rel#configs/apps/"$app"/}
                printf '%s\n' "$manifest" | awk -F'\t' -v a="$app" -v p="$path" \
                    '$1==a && index(p,$2)==1 {print $2; exit}'
                continue
                ;;
            *)
                continue
                ;;
        esac
        printf '%s\n' "$path"
    done | LC_ALL=C sort -u | awk '
        { if (keep != "" && index($0, keep "/") == 1) next; print; keep = $0 }
    '
}

# Resolve the sync state. Prints one of:
#   unrecorded  no usable record yet
#   clean       repository equals the snapshot this machine last reconciled with
#   dirty       uncommitted managed changes on this machine (capture needed)
#   pending     commits landed since the last sync (restore/apply needed)
#   rewritten   the recorded revision is not an ancestor of HEAD
sync_probe() {
    local repo_root=${1:-$REPO_ROOT} recorded current
    current=$(sync_revision "$repo_root")
    recorded=$(sync_record_get revision)

    have_sync_record || { printf 'unrecorded\n'; return 0; }

    local record_hash tree_hash paths_hash current_paths
    record_hash=$(sync_record_get tree_hash)
    tree_hash=$(sync_tree_hash "$repo_root")
    paths_hash=$(sync_record_get paths_hash)
    current_paths=$(sync_paths_hash "$repo_root")

    if [[ "$record_hash" == "$tree_hash" ]] && [[ "$paths_hash" == "$current_paths" ]]; then
        # Content unchanged since the record was written. A revision move here
        # is a normal capture-then-commit, so refresh in place — unless history
        # was rewritten, which invalidates the baseline mapping.
        if [[ "$recorded" != "$current" ]]; then
            git -C "$repo_root" merge-base --is-ancestor "$recorded" "$current" 2>/dev/null \
                || { printf 'rewritten\n'; return 0; }
            write_sync_record "direction=probe" "mode=status"
        fi
        printf 'clean\n'
        return 0
    fi

    if [[ "$recorded" != "$current" ]]; then
        # The record names an older revision and the content moved with it: new
        # commits landed here. Confirm the ancestry before calling it pending.
        git -C "$repo_root" merge-base --is-ancestor "$recorded" "$current" 2>/dev/null \
            || { printf 'rewritten\n'; return 0; }
        printf 'pending\n'
        return 0
    fi

    printf 'dirty\n'
}
