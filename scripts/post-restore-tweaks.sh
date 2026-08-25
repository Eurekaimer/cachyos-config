#!/usr/bin/env bash
# Post-restore machine tweaks: noctalia runtime backfill, eDP-1 scale, wallpaper.
#
# restore-user.sh replaces ~/.config/noctalia and cfg/display.kdl with the
# portable snapshots, dropping runtime state (colorschemes, config.toml) and
# machine-specific output scaling. This restores both from the restore backup.
# All steps are idempotent, so it is safe on every run.
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_non_root_user

wallpaper=""
edp_scale="1.1"
restart_fcitx5=0
while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --wallpaper)
            shift
            (($#)) || die "--wallpaper requires a file path"
            wallpaper=$1
            ;;
        --edp-scale)
            shift
            (($#)) || die "--edp-scale requires a value"
            edp_scale=$1
            ;;
        --restart-fcitx5) restart_fcitx5=1 ;;
        -h|--help)
            cat <<'EOF'
Usage: scripts/post-restore-tweaks.sh [OPTIONS]

Restores machine-specific state that restore-user.sh cannot carry:
  * noctalia runtime files (settings.json, colors.json, colorschemes, config.toml)
    from the most recent ~/.local/state/cachyos-config/backups/<ts>/
  * niri output scaling (default: eDP-1 at 1.1) appended to cfg/display.kdl
  * optional: set the Noctalia wallpaper via IPC
  * optional: restart fcitx5 so newly installed fonts take effect

Options:
  --dry-run            Print what would be done
  --wallpaper FILE     Set this wallpaper through the Noctalia IPC (relative
                       paths resolve under ~/Pictures/Wallpapers)
  --edp-scale VALUE    Scale for the eDP-1 output (default 1.1)
  --restart-fcitx5     Restart the fcitx5 input method after font installs
  -h, --help           Show this help

Wayland session env (WAYLAND_DISPLAY / XDG_RUNTIME_DIR / DBUS_SESSION_BUS_ADDRESS)
default to the current user's session and can be overridden.
EOF
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

wayland_live() {
    [[ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]]
}

# 1) Noctalia runtime files from the most recent restore backup
backfill_noctalia() {
    local backups="$HOME/.local/state/cachyos-config/backups" ts src
    [[ -d "$backups" ]] || { warn "No restore backups under $backups; noctalia backfill skipped"; return 0; }
    ts=$(ls -1dt "$backups"/*/ 2>/dev/null | head -1)
    [[ -n "$ts" ]] || return 0
    src="$ts/home/.config/noctalia"
    [[ -d "$src" ]] || { warn "No noctalia backup in $ts; backfill skipped"; return 0; }
    mkdir -p -- "$HOME/.config/noctalia"
    for f in settings.json colors.json config.toml; do
        [[ -f "$src/$f" ]] && run cp -a -- "$src/$f" "$HOME/.config/noctalia/"
    done
    if [[ -d "$src/colorschemes" ]]; then
        run cp -a -- "$src/colorschemes" "$HOME/.config/noctalia/"
    fi
    log "Noctalia runtime files backfilled from $ts"
}

# 2) niri eDP-1 scale (machine-specific, kept out of the portable snapshot)
apply_edp_scale() {
    local file="$HOME/.config/niri/cfg/display.kdl" block
    [[ -f "$file" ]] || { warn "niri display.kdl not found; eDP-1 scale skipped"; return 0; }
    if grep -q 'output "eDP-1"' "$file"; then
        log "eDP-1 scale already present in display.kdl"
        return 0
    fi
    block=$(printf '\noutput "eDP-1" {\n    scale %s\n}\n' "$edp_scale")
    if (( DRY_RUN )); then
        print_cmd cat ">>" "$file"
    else
        printf '%s' "$block" >>"$file"
    fi
    log "eDP-1 scale $edp_scale appended to display.kdl"
    if ! (( DRY_RUN )) && wayland_live && command -v niri >/dev/null 2>&1; then
        sleep 1  # let niri's config watcher pick up the change
        niri msg outputs 2>/dev/null | sed -n '6,8p' | grep -q "Scale: $edp_scale" \
            || warn "niri did not report Scale: $edp_scale (reload or re-login may be needed)"
    fi
}

# 3) Optional wallpaper switch through the Noctalia IPC
apply_wallpaper() {
    [[ -n "$wallpaper" ]] || return 0
    [[ "${wallpaper:0:1}" == / ]] || wallpaper="$HOME/Pictures/Wallpapers/$wallpaper"
    [[ -f "$wallpaper" ]] || die "Wallpaper not found: $wallpaper"
    if ! wayland_live; then
        warn "Wayland session not reachable; wallpaper set skipped (run again after login)"
        return 0
    fi
    require_command qs
    if (( DRY_RUN )); then
        log "Would set wallpaper to $wallpaper"
        return 0
    fi
    if qs -c noctalia-shell ipc call wallpaper set "$wallpaper" >/dev/null; then
        log "Wallpaper set to $wallpaper"
    else
        warn "qs wallpaper set failed"
    fi
}

# 4) Optional fcitx5 restart so fonts installed by Stage 1 take effect
restart_fcitx() {
    (( restart_fcitx5 )) || return 0
    if ! wayland_live; then
        warn "Wayland session not reachable; fcitx5 restart skipped"
        return 0
    fi
    if (( DRY_RUN )); then
        log "Would restart fcitx5"
        return 0
    fi
    setsid fcitx5 -rd --replace </dev/null >/dev/null 2>&1 &
    sleep 4
    fcitx5-remote || warn "fcitx5-remote failed after restart"
    log "fcitx5 restarted"
}

backfill_noctalia
apply_edp_scale
apply_wallpaper
restart_fcitx

log "Post-restore tweaks complete"
