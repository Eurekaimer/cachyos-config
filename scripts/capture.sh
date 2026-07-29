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


copy_one() {
    local source=$1 destination=$2
    [[ -e "$source" || -L "$source" ]] || return 1
    mkdir -p -- "$(dirname -- "$destination")"
    if [[ -r "$source" ]]; then
        cp -a -- "$source" "$destination"
    else
        sudo cp -a -- "$source" "$destination"
        sudo chown -R -- "$(id -u):$(id -g)" "$destination"
    fi
}

capture_group() {
    local source_root=$1 destination_root=$2 manifest=$3
    local relative
    while IFS= read -r relative; do
        if ! copy_one "${source_root%/}/$relative" "${destination_root%/}/$relative"; then
            warn "Skipped missing path: ${source_root%/}/$relative"
        fi
    done < <(read_list "$manifest")
}

log "Refreshing managed snapshots"
rm -rf -- "${config_root:?}/home" "$config_root/system" "$config_root/dconf"
mkdir -p -- "$config_root/home" "$config_root/system/portable" \
    "$config_root/system/hardware" "$config_root/system/reference" \
    "$config_root/dconf" "$packages_root" "$state_root/hardware" "$manifest_root"

capture_group "$captured_home" "$config_root/home" "$manifest_root/home-paths.txt"
capture_group / "$config_root/system/portable" "$manifest_root/system-portable-paths.txt"
capture_group / "$config_root/system/hardware" "$manifest_root/system-hardware-paths.txt"
capture_group / "$config_root/system/reference" "$manifest_root/system-reference-paths.txt"

# Runtime history is not configuration and may expose filenames.
rm -f -- "$config_root/home/.config/mpv/memo-history.log"

# Keep the public snapshot useful without publishing the account email.
if [[ -f "$config_root/home/.gitconfig" ]]; then
    git config --file "$config_root/home/.gitconfig" --unset-all user.email || true
fi

if command -v dconf >/dev/null 2>&1; then
    dconf dump / >"$config_root/dconf/user.ini"
else
    warn "dconf is unavailable; desktop dconf settings were not captured"
fi

log "Capturing package and service state"
pacman -Qqen | LC_ALL=C sort -u >"$packages_root/pacman-explicit.txt"
pacman -Qqm | LC_ALL=C sort -u >"$packages_root/aur-explicit.txt"

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

log "Snapshot complete: $REPO_ROOT"
warn "Deliberately excluded: passwords, SSH/GPG keys, browser profiles, Clash profiles, NetworkManager connections, cookies, logs, caches, and .omp runtime state."
