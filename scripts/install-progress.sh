#!/usr/bin/env bash
# Live progress for a cachyos-config restore: package install progress + speed.
#
# Counts installed packages from both manifests (pacman-explicit + aur-explicit)
# and shows download speed sampled from /proc/net/dev. Live single-line bar in a
# terminal; --once prints one snapshot line (handy for scripts or the agent).
# Usage: scripts/install-progress.sh [--once] [repo-dir]
set -uo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

ONCE=0
[[ ${1:-} == --once ]] && { ONCE=1; shift; }
REPO="${1:-$REPO_ROOT}"
AUR="$REPO/packages/aur-explicit.txt"
PAC="$REPO/packages/pacman-explicit.txt"
[[ -r "$AUR" && -r "$PAC" ]] || { echo "manifests not found in $REPO" >&2; exit 1; }

# union of both manifests, skipping comments/blanks, preserving order
mapfile -t ALL < <(
  { grep -vE '^\s*#|^\s*$' "$AUR"; grep -vE '^\s*#|^\s*$' "$PAC"; } | awk '!seen[$0]++'
)
TOTAL=${#ALL[@]}

# Write straight to the terminal when available (avoids pipe buffering);
# fall back to stdout when not.
if tty -s; then OUT=/dev/tty; else OUT=/dev/stdout; fi

net_rx() { awk 'NR>2 {sub(":", "", $1); s += $2} END {print s+0}' /proc/net/dev; }

humanize() { # bytes -> "X B/s | KB/s | MB/s"
  awk -v b="$1" 'BEGIN{
    if (b >= 1048576) printf "%.1f MB/s", b/1048576
    else if (b >= 1024) printf "%.1f KB/s", b/1024
    else printf "%d B/s", b
  }'
}

tick() { # $1 = rx bytes now
  local speed=$(( $1 - PREV_RX )) done=0 p
  for p in "${ALL[@]}"; do
    if pacman -Q "$p" >/dev/null 2>&1; then done=$((done + 1)); fi
  done
  local remaining=$((TOTAL - done))
  local pct=$((done * 100 / TOTAL))
  local filled=$((pct * 40 / 100))
  local bar
  bar=$(printf '%*s' "$filled" '' | tr ' ' '#')$(printf '%*s' $((40 - filled)) '' | tr ' ' '-')
  local spd act
  spd=$(humanize "$speed")
  if pgrep -x paru >/dev/null || pgrep -x pacman >/dev/null || pgrep -x makepkg >/dev/null; then
    act="running"
  else
    act="idle"
  fi
  if ((remaining == 0)) && ! pgrep -x paru >/dev/null && ! pgrep -x pacman >/dev/null && ! pgrep -x makepkg >/dev/null; then
    printf '[%s] 100%%  %d/%d installed  ALL DONE\n' "$bar" "$done" "$TOTAL" >"$OUT"
    exit 0
  fi
  printf '\r[%s] %3d%%  %d/%d installed  %d remaining  %s  %s' \
    "$bar" "$pct" "$done" "$TOTAL" "$remaining" "$spd" "$act" >"$OUT"
}

PREV_RX=$(net_rx)
if ((ONCE)); then
  tick "$(net_rx)"
  printf '\n' >"$OUT"
  exit 0
fi
while :; do
  RX=$(net_rx)
  tick "$RX"
  PREV_RX=$RX
  sleep 1
done
