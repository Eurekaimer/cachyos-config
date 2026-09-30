#!/usr/bin/env bash
set -Eeuo pipefail

module_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$module_dir/../../scripts/lib/common.sh"

# Installer for the KOReader module. Two independent halves, applied in order:
#
#   1. patch    Repair the two desktop defects shipped by AUR koreader-bin
#               (startup device-probe crash, PDF footer crash) in /usr/lib.
#   2. keystream Clone Eurekaimer/koreader-keystream-config and restore the
#               canonical keyboard config into ~/.config/koreader.
#
# --restore rolls the system Lua files back to the upstream originals; it is
# what modules/koreader/uninstall.sh forwards to.

# --- Half 1: system Lua patches -------------------------------------------
# Two Lua files this script touches, shipped by the AUR koreader-bin package.
koreader_root="/usr/lib/koreader/frontend"
koreader_device_lua="$koreader_root/device.lua"
koreader_footer_lua="$koreader_root/apps/reader/modules/readerfooter.lua"
# Match the AUR koreader-bin upstream tag (e.g. version 2026.07.1-2 -> v2026.07.1).
koreader_src_url="https://github.com/koreader/koreader.git"

# Patch markers.
probe_fixed='lfs.attributes("/usr/bin/hwdetect.sh")'
footer_fixed='if self.view.view_mode == "page" or not self.ui.document.getPosFromXPointer then'

# --- Half 2: keystream keyboard config ------------------------------------
keystream_url=${KOREADER_KEYSTREAM_URL:-https://github.com/Eurekaimer/koreader-keystream-config.git}
koreader_config="$HOME/.config/koreader"

usage() {
    cat <<'EOF'
Usage: modules/koreader/install.sh [OPTIONS]

Installs the KOReader desktop integration in two halves:

1. System Lua patches (needs sudo). Repairs two defects of the AUR
   koreader-bin build:
   a. Startup crash from the device probe. KOReader treats an existing
      /usr/bin/hwdetect as a Kobo firmware marker, but Arch's extra repository
      ships that exact binary, so the probe loads the Kobo device module and
      aborts on desktop. The bogus probe is removed from
      /usr/lib/koreader/frontend/device.lua.
   b. PDF crash with the global continuous-scroll default. This repo sets
      DCREREADER_VIEW_MODE = "scroll" in defaults.custom.lua for EPUBs; the same
      default leaks into PDF view_mode, and ReaderFooter's scroll branch then
      calls getPosFromXPointer(), which only the CRE (EPUB/TXT) engine
      implements - so every PDF crashes on open. The branch is guarded in
      /usr/lib/koreader/frontend/apps/reader/modules/readerfooter.lua.

2. Keyboard config (user files). Clones Eurekaimer/koreader-keystream-config
   and restores it into ~/.config/koreader:
     plugins/vimkeys.koplugin/    -> plugins/     (always mirrored)
     patches/*.lua                -> patches/     (always mirrored, code not prefs)
     examples/defaults.custom.lua -> ./           (only if absent; --force overwrites)
     examples/settings/hotkeys.lua -> settings/   (only if absent; --force overwrites)
     scripts/install-ecdict.sh    -> downloads the ECDICT dictionary
   Existing hotkeys.lua / defaults.custom.lua are NOT overwritten by default so
   device bindings and per-device defaults survive. The clone is a temporary
   checkout, never left on disk.

Options:
  --dry-run             Print the commands that would be run without changing files
  --restore             Restore both system Lua files to the upstream originals
                        and stop (this is what `scripts/module.sh uninstall
                        koreader` runs). Uses the .bak-* backup taken at patch
                        time; if missing, clones the koreader/koreader tag
                        matching the installed koreader-bin version.
  --force               Overwrite existing destination files from the keystream repo
  --skip-dictionary     Restore keyboard/config files without installing ECDICT
  --refresh-dictionary  Rebuild ECDICT even when the expected version is present
  -h, --help            Show this help
EOF
}

restore_mode=0
force=0
skip_dictionary=0
refresh_dictionary=0
while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --restore) restore_mode=1 ;;
        --force) force=1 ;;
        --skip-dictionary) skip_dictionary=1 ;;
        --refresh-dictionary) refresh_dictionary=1 ;;
        -h|--help)
            usage
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

require_non_root_user

# Restore from the .bak-* the patch step left next to the file, if any.
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
# once, caching the checkout in upstream_clone_dir. Sets original_path to the
# requested file inside that tree. Not called in a subshell: the cache and the
# EXIT-trap cleanup both live in this shell.
fetch_original() {
    local file=$1 rel="${1#"$koreader_root/"}"

    if [[ -z "$upstream_clone_dir" ]]; then
        local pkg_ver
        pkg_ver=$(pacman -Q koreader-bin 2>/dev/null | awk '{print $2}')
        local tag=""
        if [[ -n "$pkg_ver" ]]; then
            tag="v${pkg_ver%%-*}"                  # 2026.07.1-2 -> v2026.07.1
        fi
        [[ -n "$tag" ]] || die "Cannot map koreader-bin version to an upstream tag."

        require_command git
        upstream_clone_dir=$(mktemp -d)

        log "Cloning $koreader_src_url at $tag (koreader-bin $pkg_ver)"
        run git clone --depth 1 --branch "$tag" --filter=blob:none \
            "$koreader_src_url" "$upstream_clone_dir/koreader"
        if (( DRY_RUN )); then
            return 0
        fi
    fi

    original_path="$upstream_clone_dir/koreader/$rel"
    [[ -f "$original_path" ]] || die "Upstream tag has no $rel; version mapping changed. Restore manually."
}

restore_file() {
    local lua_file=$1
    [[ -f "$lua_file" ]] || { warn "Skipping missing $lua_file (koreader-bin not installed?)"; return 0; }
    restore_from_backup "$lua_file" && return 0
    fetch_original "$lua_file"
    if (( DRY_RUN )); then
        warn "Dry run only; no file was changed."
        return 0
    fi
    log "No local backup; restoring $lua_file from upstream checkout"
    run sudo cp -a -- "$original_path" "$lua_file"
}

restore_lua_patches() {
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
}

patch_lua_files() {
    [[ -f "$koreader_device_lua" ]] || die \
        "Missing $koreader_device_lua; install koreader-bin first (paru -S koreader-bin)."

    local probe_broken='or lfs.attributes("/usr/bin/hwdetect")'
    if grep -Fq "$probe_broken" "$koreader_device_lua"; then
        log "koreader-bin shipped the broken Kobo probe; planning patch"
        local backup_path="$koreader_device_lua.bak-$(date +%Y%m%d)"
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

    local footer_broken='if self.view.view_mode == "page" then'
    if grep -Fq "$footer_broken" "$koreader_footer_lua"; then
        log "koreader-bin shipped the unguarded footer scroll branch; planning patch"
        local footer_backup_path="$koreader_footer_lua.bak-$(date +%Y%m%d)"
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
}

restore_component() {
    local rel=$1 dst=$2
    if [[ -e "$dst" && $force -eq 0 ]]; then
        warn "Skipping existing $dst (use --force to overwrite)"
        return
    fi
    run cp -a -- "$src/$rel" "$dst"
    if (( ! DRY_RUN )); then
        log "Restored $dst"
    fi
}

# Temporary checkouts (keystream clone, upstream koreader clone for --restore).
# Declared at file scope so the EXIT trap can still see them after the
# functions that create them have returned.
clone_dir=""
upstream_clone_dir=""
original_path=""
cleanup_clone() {
    [[ -n "$clone_dir" ]] && rm -rf -- "$clone_dir"
    [[ -n "$upstream_clone_dir" ]] && rm -rf -- "$upstream_clone_dir"
    return 0
}
trap cleanup_clone EXIT

sync_keystream() {
    require_command git

    clone_dir=$(mktemp -d)

    log "Cloning $keystream_url"
    run git clone --depth 1 "$keystream_url" "$clone_dir/keystream"
    src="$clone_dir/keystream"
    if (( ! DRY_RUN )); then
        [[ -f "$src/README.md" ]] || die "Clone did not produce a keystream checkout; review network and repo URL."
        if (( ! skip_dictionary )); then
            [[ -x "$src/scripts/install-ecdict.sh" ]] ||
                die "Clone is missing the ECDICT installer: $src/scripts/install-ecdict.sh"
        fi
    fi

    run mkdir -p -- "$koreader_config/plugins" "$koreader_config/patches" "$koreader_config/settings"

    restore_component plugins/vimkeys.koplugin "$koreader_config/plugins/vimkeys.koplugin"
    # Patches are code, not user prefs: always mirror the repo's patch set.
    run cp -a -- "$src/patches/." "$koreader_config/patches/"
    restore_component examples/defaults.custom.lua "$koreader_config/defaults.custom.lua"
    restore_component examples/settings/hotkeys.lua "$koreader_config/settings/hotkeys.lua"

    if (( ! skip_dictionary )); then
        local dictionary_args=()
        (( refresh_dictionary )) && dictionary_args+=(--force)
        run "$src/scripts/install-ecdict.sh" "${dictionary_args[@]}"
    fi

    if (( DRY_RUN )); then
        warn "Dry run only; no file was changed."
    else
        log "keystream config restored; restart KOReader, keep external dictionary lookup disabled, and enable Vim Keys in Tools > More tools > Plugin manager"
    fi
}

if (( restore_mode )); then
    restore_lua_patches
    exit 0
fi

patch_lua_files
sync_keystream
