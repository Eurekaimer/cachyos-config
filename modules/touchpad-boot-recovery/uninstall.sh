#!/usr/bin/env bash
set -Eeuo pipefail

die() {
    printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
    exit 1
}

[[ "$(uname -s)" == "Linux" ]] || die "目前只支持 Linux。"
(( EUID != 0 )) || die "请以桌面用户运行（脚本内部会调用 sudo）。"
command -v sudo >/dev/null 2>&1 || die "缺少 sudo。"

# 停用服务并删除两个文件；不解绑触摸板，当前会话不受影响。
sudo systemctl disable --now touchpad-boot-recovery.service 2>/dev/null || true
sudo rm -f /usr/local/sbin/touchpad-boot-recovery /etc/systemd/system/touchpad-boot-recovery.service
sudo systemctl daemon-reload

printf '已停用并删除 touchpad-boot-recovery.service 及其脚本。\n'
