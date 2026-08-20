#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
    cat <<'EOF'
Usage: scripts/patch-koreader-desktop.sh [OPTIONS]

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

Both patches back up the shipped file first and are idempotent: rerun the
script after a koreader-bin upgrade restores the shipped lines.

Options:
  --dry-run        Print the commands that would be run without changing files
  -h, --help       Show this help
EOF
}

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help)
            usage
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

require_non_root_user

koreader_device_lua="/usr/lib/koreader/frontend/device.lua"
backup_path="$koreader_device_lua.bak-$(date +%Y%m%d)"
probe_broken='or lfs.attributes("/usr/bin/hwdetect")'
probe_fixed='lfs.attributes("/usr/bin/hwdetect.sh")'

[[ -f "$koreader_device_lua" ]] || die \
    "Missing $koreader_device_lua; install koreader-bin first (paru -S koreader-bin)."

if grep -Fq "$probe_broken" "$koreader_device_lua"; then
    log "koreader-bin shipped the broken Kobo probe; planning patch"
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

koreader_footer_lua="/usr/lib/koreader/frontend/apps/reader/modules/readerfooter.lua"
footer_backup_path="$koreader_footer_lua.bak-$(date +%Y%m%d)"
footer_broken='if self.view.view_mode == "page" then'
footer_fixed='if self.view.view_mode == "page" or not self.ui.document.getPosFromXPointer then'

[[ -f "$koreader_footer_lua" ]] || die \
    "Missing $koreader_footer_lua; install koreader-bin first (paru -S koreader-bin)."

if grep -Fq "$footer_broken" "$koreader_footer_lua"; then
    log "koreader-bin shipped the unguarded footer scroll branch; planning patch"
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
