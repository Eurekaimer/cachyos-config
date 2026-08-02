#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
    cat <<'EOF'
Usage: scripts/install-sioyek-ecdict.sh [OPTIONS]

Install the vendored offline English-to-Chinese lookup plugin into the current
user's native Sioyek configuration. The first run downloads and indexes ECDICT;
subsequent runs reuse the local database and safely refresh the integration.

Options:
  --dry-run        Print package and plugin install commands without changing files
  --skip-packages  Do not install missing Arch/CachyOS runtime dependencies
  -h, --help       Show this help
EOF
}

skip_packages=0
while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --skip-packages) skip_packages=1 ;;
        -h|--help)
            usage
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

require_non_root_user
command -v sioyek >/dev/null 2>&1 || die \
    "Sioyek is not installed. Install its AUR package first: yay -S sioyek-git."

plugin_dir="$REPO_ROOT/modules/sioyek-ecdict"
[[ -f "$plugin_dir/install.sh" ]] || die "Missing vendored plugin: $plugin_dir"

required_packages=(uv python-gobject gtk4-layer-shell)
missing_packages=()
for package in "${required_packages[@]}"; do
    pacman -Qq "$package" >/dev/null 2>&1 || missing_packages+=("$package")
done

if ((${#missing_packages[@]})); then
    if (( skip_packages )); then
        die "Missing packages: ${missing_packages[*]}. Install them or omit --skip-packages."
    fi
    require_command sudo
    require_command pacman
    log "Installing Sioyek ECDICT runtime dependencies"
    run sudo pacman -S --needed "${missing_packages[@]}"
fi

if (( DRY_RUN )); then
    print_cmd "$plugin_dir/install.sh"
    exit 0
fi

require_command uv
"$plugin_dir/install.sh"

log "Sioyek ECDICT is ready"
printf '%s\n' \
    'Restart Sioyek, select an English word, and press s.' \
    'The stock s web-search binding is disabled by the local dictionary binding.' \
    "Keep this clone at: $REPO_ROOT"
