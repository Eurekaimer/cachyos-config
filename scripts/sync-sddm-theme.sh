#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_non_root_user
require_command patch
require_command python3

from_snapshot=0
wallpaper_override=""
while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --from-snapshot) from_snapshot=1 ;;
        --wallpaper)
            shift
            (($#)) || die "--wallpaper requires a file path"
            wallpaper_override=$1
            ;;
        -h|--help)
            cat <<'EOF'
Usage: scripts/sync-sddm-theme.sh [OPTIONS]

Builds the managed Sugar Candy Qt6 theme, installs it for SDDM, and keeps the
selected Noctalia wallpaper and SDDM configuration represented in this repo.

Options:
  --dry-run            Validate inputs and print system/repository changes
  --from-snapshot      Use modules/sddm/wallpaper.path and configs/home instead
                       of reading the current Noctalia runtime cache
  --wallpaper FILE     Override the current Noctalia wallpaper
  -h, --help           Show this help
EOF
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

module_root="$REPO_ROOT/modules/sddm"
theme_source="$module_root/sugar-candy"
theme_patch="$module_root/qt6.patch"
theme_override="$module_root/theme.conf.user"
sddm_source="$module_root/sddm.conf"
wallpaper_record="$module_root/wallpaper.path"
snapshot_home="$REPO_ROOT/configs/home"
snapshot_sddm="$REPO_ROOT/configs/system/portable/etc/sddm.conf.d/10-eurekaimer-theme.conf"
theme_target="/usr/share/sddm/themes/sugar-candy-qt6"
sddm_target="/etc/sddm.conf.d/10-eurekaimer-theme.conf"

[[ -f "$theme_source/Main.qml" ]] || die "Sugar Candy submodule is missing; run: git submodule update --init --recursive"
[[ -f "$theme_patch" && -f "$theme_override" && -f "$sddm_source" ]] || die "Incomplete SDDM module under $module_root"

if (( from_snapshot )); then
    [[ -f "$wallpaper_record" ]] || die "Missing wallpaper record: $wallpaper_record"
    IFS= read -r wallpaper_relative <"$wallpaper_record"
else
    if [[ -n "$wallpaper_override" ]]; then
        [[ -f "$wallpaper_override" ]] || die "Wallpaper does not exist: $wallpaper_override"
        wallpaper=$(realpath -- "$wallpaper_override")
    else
        wallpaper_cache="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/wallpapers.json"
        [[ -f "$wallpaper_cache" ]] || die "Noctalia wallpaper cache not found: $wallpaper_cache"
        wallpaper=$(python3 - "$wallpaper_cache" <<'PY'
import json
import os
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
for screen_name in sorted(data.get("wallpapers", {})):
    entry = data["wallpapers"][screen_name]
    if isinstance(entry, str):
        candidates = [entry]
    else:
        candidates = [entry.get("dark"), entry.get("light")]
    for candidate in candidates:
        if candidate and os.path.isfile(candidate):
            print(os.path.realpath(candidate))
            raise SystemExit(0)
raise SystemExit("No readable wallpaper found in Noctalia cache")
PY
)
    fi

    case "$wallpaper" in
        "$HOME"/*) wallpaper_relative=${wallpaper#"$HOME"/} ;;
        *) die "Wallpaper must be inside the target user's home: $wallpaper" ;;
    esac
fi

[[ -n "$wallpaper_relative" && "$wallpaper_relative" != /* && "$wallpaper_relative" != *".."* ]] || die "Unsafe wallpaper path: $wallpaper_relative"
snapshot_wallpaper="$snapshot_home/$wallpaper_relative"

if (( ! from_snapshot )); then
    if (( DRY_RUN )); then
        print_cmd install -Dm644 -- "$wallpaper" "$snapshot_wallpaper"
        printf '+ printf %%s\\n %q > %q\n' "$wallpaper_relative" "$wallpaper_record"
    else
        install -Dm644 -- "$wallpaper" "$snapshot_wallpaper"
        printf '%s\n' "$wallpaper_relative" >"$wallpaper_record"
    fi
fi
[[ -f "$snapshot_wallpaper" ]] || die "Snapshot wallpaper does not exist: $snapshot_wallpaper"

if (( DRY_RUN )); then
    print_cmd install -Dm644 -- "$sddm_source" "$snapshot_sddm"
else
    install -Dm644 -- "$sddm_source" "$snapshot_sddm"
fi

stage=$(mktemp -d)
cleanup() {
    rm -rf -- "$stage"
}
trap cleanup EXIT
cp -a -- "$theme_source/." "$stage/"
rm -f -- "$stage/.git"
patch --quiet -d "$stage" -p1 <"$theme_patch"
install -Dm644 -- "$theme_override" "$stage/theme.conf.user"
install -Dm644 -- "$snapshot_wallpaper" "$stage/Backgrounds/Eurekaimer.png"

log "Installing Sugar Candy Qt6 theme with: $wallpaper_relative"
run sudo install -d -m755 -- "$theme_target"
run sudo cp -a -- "$stage/." "$theme_target/"
run sudo chown -R root:root -- "$theme_target"
run sudo install -Dm644 -- "$sddm_source" "$sddm_target"

log "SDDM theme synchronized; preview with: sddm-greeter-qt6 --test-mode --theme $theme_target"
warn "Do not restart sddm from an active graphical session unless you are ready to log out."
