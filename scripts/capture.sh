#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_non_root_user
require_command pacman

captured_home=${HOME:?}
config_root="$REPO_ROOT/configs"
packages_root="$REPO_ROOT/packages"
state_root="$REPO_ROOT/state"
manifest_root="$REPO_ROOT/manifests"

while (($#)); do
    case "$1" in
        -h|--help)
            cat <<'EOF'
Usage: scripts/capture.sh [--help]

Rebuilds the managed snapshot from the CURRENT machine into this repository:

  configs/home/    allowlisted paths under $HOME (manifests/home-paths.txt)
  configs/system/  portable /etc snapshots (+ hardware/reference layers)
  configs/dconf/   desktop settings database export
  packages/        explicit pacman/AUR packages, toolchains, enabled services
  state/           machine metadata and hardware references

Run as the desktop user. Readable /etc files are copied directly; protected
ones are copied through sudo. Missing paths are reported and skipped; paths
that cannot be read keep their previous snapshot copy with a warning. If the
capture fails midway, the previous snapshot is restored unchanged.

After capture, review with scripts/audit.sh, then publish to sync other
machines:

  git add -A && git commit -m "sync: refresh snapshot" && git push

The snapshot is machine-portable: absolute paths referencing the captured
home are rewritten for the target user at restore time. Disk-specific files
such as /etc/fstab and /etc/hostname live in a separate hardware layer and
are never applied by the default restore.
EOF
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done


copy_one() {
    local source=$1 destination=$2
    [[ -e "$source" || -L "$source" ]] || return 1
    mkdir -p -- "$(dirname -- "$destination")"
    if [[ -r "$source" ]]; then
        cp -a -- "$source" "$destination"
    elif sudo cp -a -- "$source" "$destination"; then
        sudo chown -R -- "$(id -u):$(id -g)" "$destination"
    else
        return 2
    fi
}

capture_group() {
    local source_root=$1 destination_root=$2 manifest=$3
    local relative
    while IFS= read -r relative; do
        if ! copy_one "${source_root%/}/$relative" "${destination_root%/}/$relative"; then
            if [[ -e "$backup_root/${destination_root#"$config_root/"}/$relative" || -L "$backup_root/${destination_root#"$config_root/"}/$relative" ]]; then
                mkdir -p -- "$(dirname -- "${destination_root%/}/$relative")"
                cp -a -- "$backup_root/${destination_root#"$config_root/"}/$relative" "${destination_root%/}/$relative"
                warn "Kept previous snapshot (could not refresh): $relative"
            else
                warn "Skipped missing path: ${source_root%/}/$relative"
            fi
        fi
    done < <(read_list "$manifest")
}

log "Refreshing managed snapshots"
backup_root=$(mktemp -d)
capture_complete=0
restore_previous() {
    local dir
    if (( capture_complete )); then
        rm -rf -- "$backup_root"
    else
        for dir in home system dconf; do
            [[ -e "$backup_root/$dir" || -L "$backup_root/$dir" ]] || continue
            rm -rf -- "${config_root:?}/$dir"
            mv -- "$backup_root/$dir" "$config_root/$dir"
        done
        rm -rf -- "$backup_root"
        die "Capture failed; previous snapshot restored"
    fi
}
trap restore_previous EXIT

for dir in home system dconf; do
    [[ -e "$config_root/$dir" || -L "$config_root/$dir" ]] || continue
    mv -- "$config_root/$dir" "$backup_root/$dir"
done
mkdir -p -- "$config_root/home" "$config_root/system/portable" \
    "$config_root/system/hardware" "$config_root/system/reference" \
    "$config_root/dconf" "$packages_root" "$state_root/hardware" "$manifest_root"

capture_group "$captured_home" "$config_root/home" "$manifest_root/home-paths.txt"
capture_group / "$config_root/system/portable" "$manifest_root/system-portable-paths.txt"
capture_group / "$config_root/system/hardware" "$manifest_root/system-hardware-paths.txt"
capture_group / "$config_root/system/reference" "$manifest_root/system-reference-paths.txt"

# Runtime history and caches are not configuration and may expose filenames.
rm -rf -- "$config_root/home/.config/mpv/cache"
rm -f -- "$config_root/home/.config/mpv/memo-history.log"

# KOReader runtime state is not configuration and may expose filenames.
rm -rf -- "$config_root/home/.config/koreader/cache"
rm -rf -- "$config_root/home/.config/koreader/data"
rm -rf -- "$config_root/home/.config/koreader/clipboard"
rm -rf -- "$config_root/home/.config/koreader/help"
rm -rf -- "$config_root/home/.config/koreader/ota"
rm -rf -- "$config_root/home/.config/koreader/screenshots"
rm -f -- "$config_root/home/.config/koreader/history.lua"
find "$config_root/home/.config/koreader/plugins" -mindepth 1 -maxdepth 1 \
    ! -name scrollstep.koplugin -exec rm -rf -- {} +
rm -f -- "$config_root/home/.config/koreader/scripts"/*
rm -f -- "$config_root/home/.config/koreader/styletweaks"/*
rm -f -- "$config_root/home/.config/koreader/settings"/*.sqlite3

# Reader settings carry the last-opened book and last directory, which are
# recent-file runtime state just like history.lua.
if [[ -f "$config_root/home/.config/koreader/settings.reader.lua" ]]; then
    sed -i -e '/\["lastfile"\]/d' -e '/\["lastdir"\]/d' \
        "$config_root/home/.config/koreader/settings.reader.lua"
fi

# Drop application-generated metadata and recent-path history from the
# portable snapshot. These values are runtime state and may expose filenames.
rm -rf -- "$config_root/home/Pictures/Wallpapers/.comments"
if [[ -f "$config_root/home/.config/QtProject.conf" ]]; then
    sed -i -E '/^(history|lastVisited|qtVersion)=/d' \
        "$config_root/home/.config/QtProject.conf"
fi

# Keep the public snapshot useful without publishing the account email.
if [[ -f "$config_root/home/.gitconfig" ]]; then
    git config --file "$config_root/home/.gitconfig" --unset-all user.email || true
fi

if command -v dconf >/dev/null 2>&1; then
    dconf dump / | python3 -c '
import sys

section = ""
for line in sys.stdin:
    if line.startswith("[") and line.rstrip().endswith("]"):
        section = line.rstrip()
    if section.startswith("[org/gnome/portal/filechooser/"):
        continue
    if section == "[org/gnome/gthumb/browser]" and line.startswith(
        ("startup-current-file=", "startup-location=")
    ):
        continue
    sys.stdout.write(line)
' >"$config_root/dconf/user.ini"
else
    warn "dconf is unavailable; desktop dconf settings were not captured"
fi

log "Capturing package and service state"
pacman -Qqen | LC_ALL=C sort -u >"$packages_root/pacman-explicit.txt"
pacman -Qqm | LC_ALL=C sort -u >"$packages_root/aur-explicit.txt"
sed -i -e '/^llama-cpp$/d' -e '/^ollama$/d' \
    "$packages_root/pacman-explicit.txt"

if command -v rustup >/dev/null 2>&1; then
    rustup toolchain list | sed -E 's/[[:space:]]+\([^)]*\)//g' | LC_ALL=C sort -u >"$packages_root/rustup-toolchains.txt"
else
    : >"$packages_root/rustup-toolchains.txt"
fi

if [[ -f "$captured_home/.bun/install/global/package.json" ]]; then
    python3 - "$captured_home/.bun/install/global/package.json" "$packages_root/bun-global.txt" <<'PY'
import json
import sys

source, destination = sys.argv[1:]
with open(source, encoding="utf-8") as handle:
    package = json.load(handle)
entries = {}
for section in ("dependencies", "devDependencies", "optionalDependencies"):
    entries.update(package.get(section, {}))
with open(destination, "w", encoding="utf-8") as handle:
    for name in sorted(entries):
        handle.write(f"{name}@{entries[name]}\n")
PY
    if command -v omp >/dev/null 2>&1; then
        omp_version=$(omp --version)
        omp_version=${omp_version#omp/}
        python3 - "$packages_root/bun-global.txt" "$omp_version" <<'PY'
import sys

path, version = sys.argv[1:]
with open(path, encoding="utf-8") as handle:
    packages = handle.readlines()
with open(path, "w", encoding="utf-8") as handle:
    for package in packages:
        if package.startswith("@oh-my-pi/pi-coding-agent@"):
            package = f"@oh-my-pi/pi-coding-agent@{version}\n"
        handle.write(package)
PY
    fi
else
    : >"$packages_root/bun-global.txt"
fi

systemctl list-unit-files --state=enabled --no-legend | awk '$1 !~ /@\./ {print $1}' | LC_ALL=C sort -u >"$packages_root/system-services.txt"
systemctl --user list-unit-files --state=enabled --no-legend | awk '{print $1}' | LC_ALL=C sort -u >"$packages_root/user-services.txt"

printf '%s\n' "$captured_home" >"$state_root/captured-home.txt"
printf '%s\n' "${USER:?}" >"$state_root/captured-user.txt"
{
    printf 'captured_at=%s\n' "$(date --iso-8601=seconds)"
    printf 'kernel=%s\n' "$(uname -srmo)"
    printf 'shell=%s\n' "${SHELL:-unknown}"
    cat /etc/os-release
} >"$state_root/system-info.txt"

command -v lspci >/dev/null 2>&1 && lspci -k >"$state_root/hardware/lspci.txt" || true
command -v lsblk >/dev/null 2>&1 && lsblk -f >"$state_root/hardware/lsblk.txt" || true
command -v findmnt >/dev/null 2>&1 && findmnt --real >"$state_root/hardware/findmnt.txt" || true
command -v niri >/dev/null 2>&1 && niri --version >"$state_root/niri-version.txt" || true
command -v omp >/dev/null 2>&1 && omp --version >"$state_root/agent-version.txt" || true

capture_complete=1
log "Snapshot complete: $REPO_ROOT"
warn "Deliberately excluded: passwords, SSH/GPG keys, browser profiles, Clash profiles, NetworkManager connections, cookies, logs, caches, and .omp runtime state."
log "Next: ./scripts/audit.sh, then 'git add -A && git commit && git push' to sync other machines."
