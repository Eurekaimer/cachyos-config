#!/usr/bin/env bash
# Application-layer helpers shared by capture, sync-configs and the profile
# entry point.
#
# Two sources of truth meet here:
#
#   configs/apps/<app>/paths  -> the $HOME paths that app owns (one per line)
#   configs/apps/<app>/…      -> the app's configuration, mirroring those paths
#
# manifests/home-paths.txt is DERIVED from the paths files; never edit it by
# hand. scripts/audit.sh fails when the two disagree.
#
# shellcheck disable=SC2154  # die/log come from scripts/lib/common.sh

# Print "<app>\t<path>" for every path declared by every application, sorted by
# app then path. Skipped silently when the app tree does not exist yet.
apps_manifest() {
    local repo_root=$1
    local apps_root="$repo_root/configs/apps" dir app paths path
    [[ -d "$apps_root" ]] || return 0
    for dir in "$apps_root"/*/; do
        [[ -d "$dir" ]] || continue
        app=$(basename -- "$dir")
        paths="$dir/paths"
        [[ -f "$paths" ]] || continue
        while IFS= read -r path; do
            path=${path%%#*}
            # Trim leading/trailing whitespace only: a path may legitimately
            # contain spaces (e.g. ".config/autostart/Clash Verge.desktop").
            path=$(printf '%s' "$path" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            [[ -n "$path" ]] || continue
            printf '%s\t%s\n' "$app" "$path"
        done <"$paths"
    done
}

# Regenerate manifests/home-paths.txt from configs/apps/*/paths (sorted, deduped).
write_home_paths() {
    local repo_root=$1
    local manifest="$repo_root/manifests/home-paths.txt" tmp
    tmp=$(mktemp)
    {
        printf '# Paths relative to the target user'"'"'s home directory.\n'
        printf '# GENERATED from configs/apps/*/paths by scripts/sync-configs.sh; do not edit by hand.\n'
        apps_manifest "$repo_root" | cut -f2 | LC_ALL=C sort -u
    } >"$tmp"
    mv -- "$tmp" "$manifest"
}

# Resolve which package profile to use, in precedence order:
#   1. an explicit --profile argument
#   2. the PACKAGE_PROFILE environment variable
#   3. the remembered choice in ~/.local/state/cachyos-config/profile
#   4. "full"
# Validates the result and dies with the historical message on failure.
resolve_profile() {
    local repo_root=$1
    local cli_arg=${2:-}
    local remembered=""
    local candidate
    local state_file="${XDG_STATE_HOME:-$HOME/.local/state}/cachyos-config/profile"

    if [[ -n "$cli_arg" ]]; then
        candidate=$cli_arg
    elif [[ -n "${PACKAGE_PROFILE:-}" ]]; then
        candidate=$PACKAGE_PROFILE
    else
        if [[ -r "$state_file" ]]; then
            IFS= read -r remembered <"$state_file" || true
            remembered=$(printf '%s' "$remembered" | tr -d '[:space:]')
        fi
        candidate=${remembered:-full}
    fi

    local profile_file="$repo_root/packages/profiles/$candidate.txt"
    [[ -r "$profile_file" ]] || die "Unknown package profile '$candidate' (expected $profile_file)"
    printf '%s\n' "$candidate"
}

# Path of the file that remembers the selected profile.
profile_state_file() {
    printf '%s/cachyos-config/profile\n' "${XDG_STATE_HOME:-$HOME/.local/state}"
}
