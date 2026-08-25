#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Two Lua files this script touches, shipped by the AUR koreader-bin package.
koreader_root="/usr/lib/koreader/frontend"
koreader_device_lua="$koreader_root/device.lua"
koreader_footer_lua="$koreader_root/apps/reader/modules/readerfooter.lua"
# Match the AUR koreader-bin upstream tag (e.g. version 2026.07.1-2 -> v2026.07.1).
koreader_src_url="https://github.com/koreader/koreader.git"

# Patch markers.
probe_fixed='lfs.attributes("/usr/bin/hwdetect.sh")'
footer_fixed='if self.view.view_mode == "page" or not self.ui.document.getPosFromXPointer then'

usage() {
    cat <<'EOF'
Usage: scripts/patch-koreader-desktop.sh [--dry-run|--restore]

Repair two KOReader desktop defects caused by the AUR koreader-bin build:

1. Startup crash from the device probe. KOReader treats an existing
   `/usr/bin/hwdetect` as a Kobo firmware marker, but Arch's extra repository
   ships that exact binary, so the probe loads the Kobo device module and
   aborts on desktop. The script removes the bogus probe from
   `/usr/lib/koreader/frontend/device.lua`.

2. PDF crash with the global continuous-scroll default. This repo sets
   `DCREREADER_VIEW_MODE = "scroll"` in `defaults.custom.lua` for EPUBs; the
   same default leaks into PDF `view_mode`, and ReaderFooter's scroll branch
   then calls `getPosFromXPointer()`, which only the CRE (EPUB/TXT) engine
   implements — so every PDF crashes on open with
   `readerfooter.lua: attempt to call method 'getPosFromXPointer' (a nil value)`.
   The script guards that branch in
   `/usr/lib/koreader/frontend/apps/reader/modules/readerfooter.lua` so
   non-CRE documents keep page-based progress; PDFs stay in page mode.

Options:
  --dry-run     Print the commands that would be run without changing files
  --restore     Restore both files to the upstream originals. Uses the local
                .bak-* backup taken at patch time; if missing, clones the
                koreader/koreader tag matching the installed koreader-bin
                version from GitHub and restores those originals.
  -h, --help    Show this help
EOF
}

restore_mode=0
while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --restore) restore_mode=1 ;;
        -h|--help)
            usage
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

require_non_root_user

# shellcheck disable=SC2317
restore_from_backup() {
    local lua_file=$1 backup=""
    # Newest .bak-* for this file wins.
    backup=$(ls -t -- "${lua_file}".bak-* 2>/dev/null | head -n1 || true)
    if [[ -n "$backup" && -f "$backup" ]]; then
        log "Restoring $lua_file from backup $backup"
        run sudo cp -a -- "$backup" "$lua_file"
        return 0
    fi
    return 1
}

# Clone the koreader/koreader tag matching the installed koreader-bin version
# and print the absolute path to <file> from that tree.
# shellcheck disable=SC2317
fetch_original() {
    local file=$1 rel="${1#"$koreader_root/"}"

    local pkg_ver
    pkg_ver=$(pacman -Q koreader-bin 2>/dev/null | awk '{print $2}')
    local tag=""
    if [[ -n "$pkg_ver" ]]; then
        tag="v${pkg_ver%%-*}"                      # 2026.07.1-2 -> v2026.07.1
    fi
    [[ -n "$tag" ]] || die "Cannot map koreader-bin version to an upstream tag."

    require_command git
    local clone_dir
    clone_dir=$(mktemp -d)
    trap 'rm -rf -- "$clone_dir"' EXIT

    log "Cloning $koreader_src_url at $tag (koreader-bin $pkg_ver)"
    run git clone --depth 1 --branch "$tag" --filter=blob:none \
        "$koreader_src_url" "$clone_dir/koreader"

    local original="$clone_dir/koreader/$rel"
    [[ -f "$original" ]] || die "Upstream tag $tag has no $rel; version mapping changed. Restore manually."
    printf '%s\n' "$original"
}

restore_file() {
    local lua_file=$1
    [[ -f "$lua_file" ]] || { warn "Skipping missing $lua_file (koreader-bin not installed?)"; return 0; }
    if restore_from_backup "$lua_file"; then
        return 0
    fi
    local original
    original=$(fetch_original "$lua_file")
    log "No local backup; restoring $lua_file from upstream checkout"
    run sudo cp -a -- "$original" "$lua_file"
}

if (( restore_mode )); then
    restore_file "$koreader_device_lua"
    restore_file "$koreader_footer_lua"
    if (( DRY_RUN )); then
        warn "Dry run only; no file was changed."
    else
        # Sanity: restored files must not carry our patch markers.
        if grep -Fq "$probe_fixed" "$koreader_device_lua" 2>/dev/null || \
           grep -Fq "$footer_fixed" "$koreader_footer_lua" 2>/dev/null; then
            die "Restored files still contain patch markers; review manually"
        fi
        log "KOReader upstream originals restored on both files"
    fi
    exit 0
fi

[[ -f "$koreader_device_lua" ]] || die \
    "Missing $koreader_device_lua; install koreader-bin first (paru -S koreader-bin)."

probe_broken='or lfs.attributes("/usr/bin/hwdetect")'
if grep -Fq "$probe_broken" "$koreader_device_lua"; then
    log "koreader-bin shipped the broken Kobo probe; planning patch"
    backup_path="$koreader_device_lua.bak-$(date +%Y%m%d)"
    if [[ -e "$backup_path" ]]; then
        log "Backup already present: $backup_path"
    else
        run sudo cp -a -- "$koreader_device_lua" "$backup_path"
    fi
    run sudo sed -i "s| $probe_broken||" "$koreader_device_lua"
    if (( DRY_RUN )); then
        warn "Dry run only; no file was changed. Re-run without --dry-run to apply."
    else
        if grep -Fq "$probe_broken" "$koreader_device_lua"; then
            die "Patch did not apply cleanly; review $koreader_device_lua manually"
        fi
        grep -Fq "$probe_fixed" "$koreader_device_lua" || \
            die "Patched file lost its Kobo probe; review $koreader_device_lua manually"
        log "KOReader desktop device-detect patch applied"
    fi
elif grep -Fq "$probe_fixed" "$koreader_device_lua"; then
    log "KOReader desktop device-detect already patched; nothing to do"
else
    die "Unexpected layout in $koreader_device_lua; a koreader-bin update may have changed the probe. Review it and re-apply the fix manually."
fi

[[ -f "$koreader_footer_lua" ]] || die \
    "Missing $koreader_footer_lua; install koreader-bin first (paru -S koreader-bin)."

footer_broken='if self.view.view_mode == "page" then'
if grep -Fq "$footer_broken" "$koreader_footer_lua"; then
    log "koreader-bin shipped the unguarded footer scroll branch; planning patch"
    footer_backup_path="$koreader_footer_lua.bak-$(date +%Y%m%d)"
    if [[ -e "$footer_backup_path" ]]; then
        log "Backup already present: $footer_backup_path"
    else
        run sudo cp -a -- "$koreader_footer_lua" "$footer_backup_path"
    fi
    run sudo sed -i "s|$footer_broken|$footer_fixed|" "$koreader_footer_lua"
    if (( DRY_RUN )); then
        warn "Dry run only; no file was changed. Re-run without --dry-run to apply."
    else
        if grep -Fq "$footer_broken" "$koreader_footer_lua"; then
            die "Patch did not apply cleanly; review $koreader_footer_lua manually"
        fi
        grep -Fq "$footer_fixed" "$koreader_footer_lua" || \
            die "Patched file lost its footer guard; review $koreader_footer_lua manually"
        log "KOReader footer PDF-scroll guard applied"
    fi
elif grep -Fq "$footer_fixed" "$koreader_footer_lua"; then
    log "KOReader footer PDF-scroll guard already patched; nothing to do"
else
    die "Unexpected layout in $koreader_footer_lua; a koreader-bin update may have changed the footer. Review it and re-apply the fix manually."
fi