#!/usr/bin/env bash
set -Eeuo pipefail

module_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$module_dir/../../scripts/lib/common.sh"

# Installer for the Sioyek ECDICT offline lookup plugin. Bootstraps the
# Arch/CachyOS runtime dependencies, rebuilds a reproducible uv environment,
# then imports the dictionary and idempotently refreshes the Sioyek
# integration and its user service.

usage() {
    cat <<'EOF'
Usage: modules/sioyek-ecdict/install.sh [OPTIONS]

Installs the vendored offline English-to-Chinese lookup plugin into the current
user's native Sioyek configuration. The first run downloads and indexes ECDICT;
later runs reuse the local database and safely refresh the integration.

Options:
  --dry-run        Print the package and plugin install commands without changing files
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
[[ "$(uname -s)" == "Linux" ]] || die "目前只支持 Linux。"

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

# The plugin requires a native Sioyek (not the Flatpak sandbox) because it
# writes into the user's real ~/.config/sioyek.
require_command sioyek "请先安装原生 Linux 版 Sioyek（暂不支持 Flatpak 沙箱）：paru -S sioyek-git"
require_command gdbus "请安装 GLib 命令行工具。"
require_command systemctl "需要 systemd user service 保持词典热启动。"

python_bin="${PYTHON:-python3}"
require_command "$python_bin" "请安装 Python 3.11 或更高版本。"
require_command uv "请先安装 uv：https://docs.astral.sh/uv/getting-started/installation/"

if (( DRY_RUN )); then
    print_cmd uv venv --clear --python "$(command -v "$python_bin")" --system-site-packages "$module_dir/.venv"
    print_cmd uv sync --frozen
    print_cmd uv run --no-sync sioyek-ecdict bootstrap
    exit 0
fi

# Validate GTK bindings and layer-shell before downloading the dictionary.
(cd "$module_dir" && "$python_bin" - <<'PY'
import gi
gi.require_version("Gdk", "4.0")
gi.require_version("Gio", "2.0")
gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gdk, Gio, Gtk, Gtk4LayerShell
PY
) || die "缺少 PyGObject、GTK4 或 Gtk4LayerShell。请参考 README 的发行版依赖。"

# Rebuild a reproducible uv environment while exposing Arch's GTK bindings.
(cd "$module_dir" && uv venv --clear --python "$(command -v "$python_bin")" --system-site-packages .venv)
(cd "$module_dir" && uv sync --frozen)

# Import ECDICT once, then idempotently refresh Sioyek and the user service.
(cd "$module_dir" && uv run --no-sync sioyek-ecdict bootstrap)

log "Sioyek ECDICT is ready"
printf '%s\n' \
    'Restart Sioyek, select an English word, and press s.' \
    'The stock s web-search binding is disabled by the local dictionary binding.' \
    "Keep this clone at: $REPO_ROOT"
