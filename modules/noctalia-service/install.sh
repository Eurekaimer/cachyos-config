#!/usr/bin/env bash
set -euo pipefail

module_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
unit_dir="$HOME/.config/systemd/user"
unit_path="$unit_dir/noctalia.service"
backup_dir="${CACHYOS_MODULE_BACKUPS:-$HOME/.local/state/cachyos-config/module-backups}"

die() {
    printf '安装失败：%s\n' "$*" >&2
    exit 1
}

[[ "$(uname -s)" == "Linux" ]] || die "目前只支持 Linux。"
command -v noctalia >/dev/null 2>&1 || die "缺少 /usr/bin/noctalia（原生 Noctalia v5 包）。"

mkdir -p "$unit_dir"

# 覆盖前备份已有的同名单元，避免丢掉手工改动
if [[ -e "$unit_path" || -L "$unit_path" ]]; then
    mkdir -p "$backup_dir"
    backup_path="$backup_dir/noctalia.service"
    rm -rf "$backup_path"
    cp -a "$unit_path" "$backup_path" || die "备份 $unit_path 失败"
    printf '已备份旧版本到 %s\n' "$backup_path"
fi

install -m 0644 "$module_dir/noctalia.service" "$unit_path"
printf '已安装 %s\n' "$unit_path"

systemctl --user daemon-reload
systemctl --user enable --now noctalia.service
sleep 2
if ! systemctl --user is-active --quiet noctalia.service; then
    die "noctalia.service 未能启动，查看 journalctl --user -u noctalia.service"
fi

# niri 的 spawn-at-startup 若仍拉起 noctalia，下次登录会出现两个实例
autostart="$HOME/.config/niri/cfg/autostart.kdl"
if [[ -f "$autostart" ]] && grep -qE '^[[:space:]]*spawn-at-startup[[:space:]]+"noctalia"' "$autostart"; then
    printf '警告：%s 仍含 spawn-at-startup "noctalia"，请删除该行，否则重新登录会出现双实例。\n' "$autostart"
fi

printf 'Noctalia 现由 systemd 托管：崩溃后 2 秒自动重生，手动重启用 systemctl --user restart noctalia.service。\n'
