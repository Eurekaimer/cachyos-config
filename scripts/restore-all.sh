#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_non_root_user

dry_run=0
with_hardware=0
skip_aur=0
no_backup=0
start_now=0
migrate_zh=0
restart_fcitx5=0
wallpaper=""
while (($#)); do
    case "$1" in
        --dry-run) dry_run=1 ;;
        --with-hardware) with_hardware=1 ;;
        --skip-aur) skip_aur=1 ;;
        --no-backup) no_backup=1 ;;
        --now) start_now=1 ;;
        --migrate-zh-dirs) migrate_zh=1 ;;
        --restart-fcitx5) restart_fcitx5=1 ;;
        --wallpaper)
            shift
            (($#)) || die "--wallpaper requires a file path"
            wallpaper=$1
            ;;
        -h|--help)
            cat <<'EOF'
Usage: scripts/restore-all.sh [OPTIONS]

Full one-shot restore for a fresh or existing CachyOS install: packages and
toolchains, portable system configuration, user configuration and dconf, SDDM
theme, service enablement, then post-restore machine tweaks. Safe on any
machine, including one with a different username; captured home paths are
rewritten for the current user.

Stages (in order):
  0  Preflight: passwordless-sudo check + submodule init (Stage 4 depends on it)
  1  Packages and toolchains
  2  System configuration
  3  User configuration and dconf
  4  SDDM theme (requires modules/sddm/sugar-candy, initialized in Stage 0)
  5  Service enablement
  6  Post-restore tweaks: noctalia runtime backfill, eDP-1 scaling

Machine-bound state is never touched by default: disk UUIDs, /etc/machine-id,
/etc/fstab, and /etc/hostname are excluded unless --with-hardware is passed
after explicit review on the same disks/host.

Options:
  --dry-run          Print every replacement/install command without changing files
  --with-hardware    Also replace /etc/fstab and /etc/hostname (same hardware only)
  --skip-aur         Do not install captured AUR packages
  --no-backup        Replace configuration without saving previous files
  --now              Start enabled services immediately instead of after reboot/login
  --migrate-zh-dirs  Rename legacy Chinese XDG dirs (桌面/文档/...) before Stage 1
  --restart-fcitx5   Restart fcitx5 in Stage 6 (after font installs)
  --wallpaper FILE   Set the Noctalia wallpaper in Stage 6 (relative paths
                     resolve under ~/Pictures/Wallpapers)
  -h, --help         Show this help
EOF
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

export RESTORE_TIMESTAMP=${RESTORE_TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}
(( dry_run )) && DRY_RUN=1
common_args=()
(( dry_run )) && common_args+=(--dry-run)

install_args=("${common_args[@]}")
(( skip_aur )) && install_args+=(--skip-aur)

system_args=("${common_args[@]}")
user_args=("${common_args[@]}")
(( with_hardware )) && system_args+=(--with-hardware)
if (( no_backup )); then
    system_args+=(--no-backup)
    user_args+=(--no-backup)
fi

service_args=("${common_args[@]}")
(( start_now )) && service_args+=(--now)

tweaks_args=("${common_args[@]}")
(( restart_fcitx5 )) && tweaks_args+=(--restart-fcitx5)
[[ -n "$wallpaper" ]] && tweaks_args+=(--wallpaper "$wallpaper")

log "Stage 0/7: preflight"
ensure_sudo || die "Preflight failed; configure passwordless sudo first (see AGENT.md §5)"
if (( migrate_zh )); then
    log "Stage 0/7: migrating legacy Chinese home directories"
    "$SCRIPT_DIR/migrate-home-dirs-zh.sh" "${common_args[@]}"
fi
log "Stage 0/7: initializing submodules"
if (( DRY_RUN )); then
    print_cmd git submodule update --init --recursive
else
    git submodule update --init --recursive \
        || die "Submodule init failed; see AGENT.md §1 for the offline fallback"
fi

log "Stage 1/7: packages and toolchains"
"$SCRIPT_DIR/install-packages.sh" "${install_args[@]}"
log "Stage 2/7: system configuration"
"$SCRIPT_DIR/restore-system.sh" "${system_args[@]}"
log "Stage 3/7: user configuration"
"$SCRIPT_DIR/restore-user.sh" "${user_args[@]}"
log "Stage 4/7: SDDM theme"
"$SCRIPT_DIR/sync-sddm-theme.sh" --from-snapshot "${common_args[@]}"
log "Stage 5/7: service enablement"
"$SCRIPT_DIR/restore-services.sh" "${service_args[@]}"
log "Stage 6/7: post-restore tweaks"
"$SCRIPT_DIR/post-restore-tweaks.sh" "${tweaks_args[@]}"

log "Full restore complete"
(( dry_run )) || warn "Reboot to activate kernel/initramfs, login shell, and all enabled services."
