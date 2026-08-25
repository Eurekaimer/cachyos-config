#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
    cat <<'EOF'
Usage: scripts/install-koreader-keystream.sh [--dry-run] [--force]

Clone Eurekaimer/koreader-keystream-config (the canonical KOReader keyboard
config repo) and restore its contents into ~/.config/koreader:

  plugins/vimkeys.koplugin/   -> ~/.config/koreader/plugins/
  patches/1-lxgw-fonts.lua    -> ~/.config/koreader/patches/
  examples/defaults.custom.lua -> ~/.config/koreader/  (only if absent;
                                  --force overwrites)
  examples/settings/hotkeys.lua -> ~/.config/koreader/settings/ (only if
                                  absent; --force overwrites)

Following the repo README, existing hotkeys.lua / defaults.custom.lua are NOT
overwritten by default so device bindings and per-device defaults survive;
--force replaces them with the repo examples. The git clone is a fresh
temporary checkout, never left on disk.

Options:
  --dry-run   Print the commands that would be run without changing files
  --force     Overwrite existing destination files from the repo
  -h, --help  Show this help
EOF
}

force=0
while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --force) force=1 ;;
        -h|--help)
            usage
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

require_non_root_user
require_command git

keystream_url="https://github.com/Eurekaimer/koreader-keystream-config.git"
koreader_config="$HOME/.config/koreader"

clone_dir=$(mktemp -d)
trap 'rm -rf -- "$clone_dir"' EXIT

log "Cloning $keystream_url"
run git clone --depth 1 "$keystream_url" "$clone_dir/keystream"
src="$clone_dir/keystream"
if (( ! DRY_RUN )); then
    [[ -f "$src/README.md" ]] || die "Clone did not produce a keystream checkout; review network and repo URL."
fi

run mkdir -p -- "$koreader_config/plugins" "$koreader_config/patches" "$koreader_config/settings"

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

restore_component plugins/vimkeys.koplugin "$koreader_config/plugins/vimkeys.koplugin"
restore_component patches/1-lxgw-fonts.lua "$koreader_config/patches/1-lxgw-fonts.lua"
restore_component examples/defaults.custom.lua "$koreader_config/defaults.custom.lua"
restore_component examples/settings/hotkeys.lua "$koreader_config/settings/hotkeys.lua"

if (( DRY_RUN )); then
    warn "Dry run only; no file was changed."
else
    log "keystream config restored; restart KOReader and enable Vim Keys in Tools > More tools > Plugin manager"
fi