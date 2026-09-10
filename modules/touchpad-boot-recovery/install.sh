#!/usr/bin/env bash
set -Eeuo pipefail

module_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

log() {
    printf '\033[1;32m==>\033[0m %s\n' "$*"
}

die() {
    printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
    exit 1
}

[[ "$(uname -s)" == "Linux" ]] || die "目前只支持 Linux。"
(( EUID != 0 )) || die "请以桌面用户运行（脚本内部会调用 sudo）。"
command -v sudo >/dev/null 2>&1 || die "缺少 sudo。"
command -v systemctl >/dev/null 2>&1 || die "缺少 systemctl（需要 systemd）。"
command -v python3 >/dev/null 2>&1 || die "缺少 python3。"

for f in touchpad-boot-recovery touchpad-boot-recovery.service; do
    [[ -f "$module_dir/$f" ]] || die "缺少模块文件：$module_dir/$f"
done

backup_dir="${CACHYOS_MODULE_BACKUPS:-$HOME/.local/state/cachyos-config/module-backups}/touchpad-boot-recovery.$(date +%Y%m%d-%H%M%S)"
if [[ -e /usr/local/sbin/touchpad-boot-recovery || -e /etc/systemd/system/touchpad-boot-recovery.service ]]; then
    mkdir -p "$backup_dir"
    [[ -e /usr/local/sbin/touchpad-boot-recovery ]] && cp -a /usr/local/sbin/touchpad-boot-recovery "$backup_dir/"
    [[ -e /etc/systemd/system/touchpad-boot-recovery.service ]] && cp -a /etc/systemd/system/touchpad-boot-recovery.service "$backup_dir/"
    log "已备份现有文件到 $backup_dir"
fi

log "安装 /usr/local/sbin/touchpad-boot-recovery"
sudo install -m 0755 -o root -g root "$module_dir/touchpad-boot-recovery" /usr/local/sbin/touchpad-boot-recovery

log "安装 /etc/systemd/system/touchpad-boot-recovery.service"
sudo install -m 0644 -o root -g root "$module_dir/touchpad-boot-recovery.service" /etc/systemd/system/touchpad-boot-recovery.service

sudo systemctl daemon-reload
sudo systemctl enable --now touchpad-boot-recovery.service

log "安装完成。当前状态："
systemctl status touchpad-boot-recovery.service --no-pager || true
