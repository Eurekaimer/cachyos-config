#!/usr/bin/env bash
# Snapshot sanitizers: strip runtime state and credentials from a captured
# configuration tree before it is committed.
#
# Every rule is expressed relative to the root of the tree being cleaned.
# Two callers use it:
#
#   configs/apps/<app>/  — the per-application tree, one app at a time
#                          (its layout mirrors the paths that app owns, so the
#                          same rules apply unchanged)
#   configs/home/        — the generated $HOME install tree
#
# shellcheck disable=SC2154  # warn/run/log come from scripts/lib/common.sh

# Drop caches, histories and other filename-leaking runtime state.
sanitize_runtime_state() {
    local root=${1%/}

    # mpv keeps a playback cache and a history of played files.
    rm -rf -- "$root/.config/mpv/cache"
    rm -f -- "$root/.config/mpv/memo-history.log"

    # KOReader runtime state: reading history, caches and per-book databases.
    rm -rf -- "$root/.config/koreader/cache"
    rm -rf -- "$root/.config/koreader/data"
    rm -rf -- "$root/.config/koreader/clipboard"
    rm -rf -- "$root/.config/koreader/help"
    rm -rf -- "$root/.config/koreader/ota"
    rm -rf -- "$root/.config/koreader/screenshots"
    rm -f -- "$root/.config/koreader/history.lua"
    rm -f -- "$root/.config/koreader/settings/lookup_history.lua"
    # The Wikipedia lookup plugin keeps its own history: looked-up words plus the
    # book they came from, exactly the recent-file class of runtime state.
    rm -f -- "$root/.config/koreader/settings/wikipedia_history.lua"
    find "$root/.config/koreader/plugins" -mindepth 1 -maxdepth 1 \
        ! -name vimkeys.koplugin -exec rm -rf -- {} + 2>/dev/null || true
    find "$root/.config/koreader/scripts" "$root/.config/koreader/styletweaks" \
        -mindepth 1 -delete 2>/dev/null || true
    find "$root/.config/koreader/settings" -maxdepth 1 -name '*.sqlite3' -delete 2>/dev/null || true
    find "$root/.config/koreader" -type f \
        \( -name '*.old' -o -name '*.bak-*' \) -delete 2>/dev/null || true

    # Reader settings carry the last-opened book and last directory, which are
    # recent-file runtime state just like history.lua.
    if [[ -f "$root/.config/koreader/settings.reader.lua" ]]; then
        sed -i -e '/\["lastfile"\]/d' -e '/\["lastdir"\]/d' \
            "$root/.config/koreader/settings.reader.lua"
    fi

    # Wallpaper metadata written by the desktop's comment tool.
    rm -rf -- "$root/Pictures/Wallpapers/.comments"
}

# Remove credentials and machine-identifying values while keeping the structure.
sanitize_credentials() {
    local root=${1%/} rc_file rc_path

    # OBS profiles contain reusable scene and encoder settings, but service.json
    # stores live-stream keys. Keep credentials out of the portable snapshot.
    local obs_profiles="$root/.config/obs-studio/basic/profiles"
    if [[ -d "$obs_profiles" ]]; then
        find "$obs_profiles" -type f \
            \( -name 'service.json' -o -name 'service.json.bak' \) -delete
    fi

    # Shell rc files export credentials for CLI tools (agent API keys, tokens).
    # Blank the values while keeping the variable names, so a restore reproduces
    # the structure and the user re-adds the secret from the password manager.
    for rc_file in .zshrc .bashrc .bash_profile; do
        rc_path="$root/$rc_file"
        [[ -f "$rc_path" ]] || continue
        sed -i -E \
            '/^[[:space:]]*(export[[:space:]]+)?[A-Za-z0-9_]*(KEY|TOKEN|SECRET|PASSWORD|PASSWD)[A-Za-z0-9_]*=/I s/=.*$/='"''"'/' \
            "$rc_path"
    done

    # Qt records recently visited paths in its project settings.
    if [[ -f "$root/.config/QtProject.conf" ]]; then
        sed -i -E '/^(history|lastVisited|qtVersion)=/d' \
            "$root/.config/QtProject.conf"
    fi

    # ani-rss snapshot must not publish downloader/API credentials or the
    # instance UUID (public repo); blank them like QtProject above.
    if [[ -f "$root/Projects/ASS/config/config.v2.json" ]]; then
        sed -i -E \
            -e 's/("downloadToolPassword":)[[:space:]]*"[^"]*"/\1 ""/' \
            -e 's/("apiKey":)[[:space:]]*"[^"]*"/\1 ""/' \
            -e 's/("uuid":)[[:space:]]*"[^"]*"/\1 ""/' \
            -e 's/("password":)[[:space:]]*"[^"]*"/\1 ""/' \
            "$root/Projects/ASS/config/config.v2.json"
    fi

    # Keep the public snapshot useful without publishing the account email.
    if [[ -f "$root/.gitconfig" ]]; then
        git config --file "$root/.gitconfig" --unset-all user.email || true
    fi
}

# Full sanitizer for one tree root.
sanitize_tree() {
    sanitize_runtime_state "$1"
    sanitize_credentials "$1"
}
