#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=scripts/lib/profile.sh
source "$SCRIPT_DIR/lib/profile.sh"
# shellcheck source=scripts/lib/sanitize.sh
source "$SCRIPT_DIR/lib/sanitize.sh"

# Two-way synchronizer for the application layer.
#
#   configs/apps/<app>/paths   the $HOME paths the app owns (source of truth)
#   configs/apps/<app>/…       the app's configuration, mirroring those paths
#   configs/home/…             GENERATED $HOME install tree consumed by
#                              restore-user.sh; never edit by hand
#
# --to-snapshot: $HOME -> configs/apps -> configs/home -> manifests/home-paths.txt
# --to-home:     configs/apps -> $HOME (per-path; the inverse of the first hop)

apps_root="$REPO_ROOT/configs/apps"
home_root="$REPO_ROOT/configs/home"

usage() {
    cat <<'EOF'
Usage: scripts/sync-configs.sh (--to-snapshot|--to-home) [--dry-run] [--no-sanitize]

Keeps the application layer and this machine in step.

--to-snapshot (default direction for capture)
    For every app under configs/apps/, copy each path it declares from $HOME
    into configs/apps/<app>/, strip runtime state and credentials, rebuild
    configs/home/ from the app trees, and regenerate manifests/home-paths.txt.

--to-home
    Copy every declared path from configs/apps/<app>/ back into $HOME.

A path that is missing at the source keeps its previous snapshot copy with a
warning, matching capture.sh. Files that configs/apps/<app>/ holds but its
paths file does not declare (notes, READMEs) are never touched.

Options:
  --dry-run       Print the copy commands without changing files
  --no-sanitize   Skip runtime/credential scrubbing (snapshot direction only)
  -h, --help      Show this help
EOF
}

direction=""
while (($#)); do
    case "$1" in
        --to-snapshot) direction=snapshot ;;
        --to-home) direction=to-home ;;
        --dry-run) DRY_RUN=1 ;;
        --no-sanitize) SANITIZE=0 ;;
        -h|--help)
            usage
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done
[[ -n "$direction" ]] || { usage >&2; exit 2; }

SANITIZE=${SANITIZE:-1}
[[ -d "$apps_root" ]] || die "No application layer found at $apps_root"

# Copy one source path into the tree, keeping the previous copy when the
# source is absent so a transient machine state cannot erase the snapshot.
copy_path() {
    local source=$1
    local destination=$2
    local rel=$3
    if [[ ! -e "$source" && ! -L "$source" ]]; then
        if [[ -e "$destination" || -L "$destination" ]]; then
            warn "Kept previous snapshot (source missing): $rel"
        else
            warn "Skipped missing path: $source"
        fi
        return 0
    fi
    run rm -rf -- "$destination"
    run mkdir -p -- "$(dirname -- "$destination")"
    run cp -a -- "$source" "$destination"
}

# --- snapshot direction ----------------------------------------------------
snapshot_apps() {
    local app dir path source destination
    while IFS=$'\t' read -r app path; do
        [[ -n "$app" ]] || continue
        source="$HOME/$path"
        destination="$apps_root/$app/$path"
        copy_path "$source" "$destination" "$app:$path"
    done < <(apps_manifest "$REPO_ROOT")

    if (( SANITIZE )) && (( ! DRY_RUN )); then
        for dir in "$apps_root"/*/; do
            [[ -d "$dir" ]] || continue
            sanitize_tree "${dir%/}"
        done
    fi
}

# Rebuild the generated $HOME install tree from the app trees.
rebuild_home_tree() {
    local app path source destination
    if (( DRY_RUN )); then
        print_cmd rm -rf -- "$home_root"
        print_cmd mkdir -p -- "$home_root"
    else
        rm -rf -- "$home_root"
        mkdir -p -- "$home_root"
    fi
    while IFS=$'\t' read -r app path; do
        [[ -n "$app" ]] || continue
        source="$apps_root/$app/$path"
        destination="$home_root/$path"
        [[ -e "$source" || -L "$source" ]] || { warn "App tree lacks $app:$path; skipping"; continue; }
        run mkdir -p -- "$(dirname -- "$destination")"
        run cp -a -- "$source" "$destination"
    done < <(apps_manifest "$REPO_ROOT")
}

# --- home direction --------------------------------------------------------
restore_apps_to_home() {
    local app path source destination
    while IFS=$'\t' read -r app path; do
        [[ -n "$app" ]] || continue
        source="$apps_root/$app/$path"
        destination="$HOME/$path"
        if [[ ! -e "$source" && ! -L "$source" ]]; then
            warn "Snapshot lacks $app:$path; skipping"
            continue
        fi
        run rm -rf -- "$destination"
        run mkdir -p -- "$(dirname -- "$destination")"
        run cp -a -- "$source" "$destination"
    done < <(apps_manifest "$REPO_ROOT")
}

case "$direction" in
    snapshot)
        # configs/apps, configs/home and manifests/home-paths.txt are rewritten
        # as one transaction: any failure restores all three unchanged. The
        # backup is a copy, because snapshot_apps reads configs/apps/*/paths to
        # learn which $HOME paths to capture.
        sync_backup=$(mktemp -d)
        sync_complete=0
        restore_snapshot() {
            local item
            if (( sync_complete )); then
                rm -rf -- "$sync_backup"
                return 0
            fi
            for item in apps home home-paths.txt; do
                [[ -e "$sync_backup/$item" || -L "$sync_backup/$item" ]] || continue
                if [[ "$item" == home-paths.txt ]]; then
                    rm -f -- "$REPO_ROOT/manifests/$item"
                    cp -a -- "$sync_backup/$item" "$REPO_ROOT/manifests/$item"
                else
                    rm -rf -- "$REPO_ROOT/configs/$item"
                    cp -a -- "$sync_backup/$item" "$REPO_ROOT/configs/$item"
                fi
            done
            rm -rf -- "$sync_backup"
            die "Configuration sync failed; previous application layer restored"
        }
        trap restore_snapshot EXIT
        for item in apps home home-paths.txt; do
            if [[ "$item" == home-paths.txt ]]; then
                src="$REPO_ROOT/manifests/$item"
            else
                src="$REPO_ROOT/configs/$item"
            fi
            [[ -e "$src" || -L "$src" ]] || continue
            cp -a -- "$src" "$sync_backup/$item"
        done

        log "Capturing the application layer from $HOME"
        snapshot_apps
        log "Rebuilding the generated home tree: configs/home/"
        rebuild_home_tree
        if (( DRY_RUN )); then
            log "Would regenerate manifests/home-paths.txt"
        else
            write_home_paths "$REPO_ROOT"
            log "Regenerated manifests/home-paths.txt"
        fi
        sync_complete=1
        log "Application layer snapshot complete"
        ;;
    to-home)
        log "Restoring the application layer into $HOME"
        restore_apps_to_home
        log "Application layer restored"
        ;;
esac
