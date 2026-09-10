#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
    cat <<'EOF'
Usage: scripts/install-touchpad-boot-recovery.sh [OPTIONS]

Install the Lenovo 82XF touchpad boot-time self-recovery: a device-specific
one-shot systemd service that rebinds i2c_designware.0 once when the I2C
touchpad is still missing shortly after boot. It is an intermittent-failure
workaround, not a kernel root-cause fix.

This is an optional machine-specific module: it is NOT part of the generic
snapshot restore, because not every machine has this touchpad problem.

Options:
  --dry-run   Print the module install command without changing files
  -h, --help  Show this help
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

module_dir="$REPO_ROOT/modules/touchpad-boot-recovery"
[[ -f "$module_dir/install.sh" ]] || die "Missing vendored module: $module_dir"

# 提权可用性检查放在这里，避免安装中途才发现 sudo 要密码。
ensure_sudo

if (( DRY_RUN )); then
    print_cmd "$module_dir/install.sh"
    exit 0
fi

"$module_dir/install.sh"
