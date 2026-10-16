#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=scripts/lib/profile.sh
source "$SCRIPT_DIR/lib/profile.sh"
# shellcheck source=scripts/lib/sync-record.sh
source "$SCRIPT_DIR/lib/sync-record.sh"

mode=summary
while (($#)); do
    case "$1" in
        --files) mode=files ;;
        --paths) mode=paths ;;
        --summary) mode=summary ;;
        -h|--help)
            cat <<'EOF'
Usage: scripts/sync-status.sh [--summary|--files|--paths]

Report what this machine still has to synchronize, using the local sync record
(~/.local/state/cachyos-config/sync-record.txt) as the baseline. The record
stores the revision and an index hash of the managed trees, so a later run
inspects only what moved instead of re-scanning every managed path.

  --summary   state plus the pending-file count (default)
  --files     repository-relative managed files that landed since the recorded
              revision, or that are uncommitted on this machine
  --paths     the managed $HOME paths those files belong to

States: clean (repository equals the last synced snapshot), dirty (uncommitted
managed changes here; capture), pending (new commits; restore/apply),
rewritten (recorded revision is not an ancestor of HEAD).

Exit codes: 0 clean, 1 pending work, 2 history rewritten (full review).

Note: "clean" means the repository still equals the snapshot this machine last
reconciled with; it does not prove the live $HOME was not edited afterwards.
Verify that with a dry-run capture:
  ./scripts/sync-configs.sh --to-snapshot --dry-run
EOF
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

state=$(sync_probe)
recorded=$(sync_record_get revision)
current=$(sync_revision)

# Repository-relative paths that make this machine out of step: commits added
# since the recorded revision plus any uncommitted managed change.
pending_files() {
    local added dirty
    if added=$(sync_changed_since_record); then
        :
    else
        # 1 = no usable record; 2 = rewritten history (caller must stop).
        [[ $? -ne 2 ]] || return 2
        added=
    fi
    [[ -n "$added" ]] && printf '%s\n' "$added"
    dirty=$(sync_dirty_files) || true
    [[ -n "$dirty" ]] || return 0
    printf '%s\n' "$dirty" | sed -e 's/^...//' -e 's/^.* -> //'
}

case "$mode" in
    summary)
        case "$state" in
            clean)
                log "In step with $current ($(sync_revision_subject))"
                exit 0
                ;;
            unrecorded)
                warn "No sync record at $(sync_record_file); run ./scripts/capture.sh (or restore) to create the baseline"
                exit 1
                ;;
            rewritten)
                warn "Recorded revision $recorded is not an ancestor of HEAD $current; review the whole snapshot again"
                exit 2
                ;;
            dirty|pending)
                pending=$(pending_files) || exit 2
                count=$(printf '%s\n' "$pending" | grep -c . || true)
                if [[ "$state" == pending ]]; then
                    log "New commits since the last sync: $(git rev-list --count "$recorded..$current" 2>/dev/null || printf '?')"
                else
                    log "Uncommitted managed changes on this machine: capture before publishing."
                fi
                log "Recorded: $recorded ($(sync_record_get revision_subject))"
                log "HEAD:     $current ($(sync_revision_subject))"
                log "Pending managed files: $count"
                log "Run --files for the list, --paths for the affected home paths"
                exit 1
                ;;
        esac
        ;;
    files|paths)
        if [[ "$state" == unrecorded ]]; then
            warn "No sync record at $(sync_record_file); nothing to compare against"
            exit 1
        fi
        if pending=$(pending_files); then :; else exit 2; fi
        [[ -n "$pending" ]] || exit 0
        if [[ "$mode" == files ]]; then
            printf '%s\n' "$pending"
        else
            printf '%s\n' "$pending" | sync_home_paths_for "$REPO_ROOT"
        fi
        ;;
esac
