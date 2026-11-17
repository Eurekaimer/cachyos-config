#!/usr/bin/env bash
set -euo pipefail

unit_path="$HOME/.config/systemd/user/noctalia.service"

if [[ ! -e "$unit_path" ]]; then
    echo "noctalia-service 未安装，无需卸载。"
    exit 0
fi

systemctl --user disable --now noctalia.service 2>/dev/null || true
rm -f "$unit_path"
systemctl --user daemon-reload
printf '已移除 %s\n' "$unit_path"
printf 'niri 的 spawn-at-startup 不会自动恢复；需要 Noctalia 开机自启请在 autostart.kdl 手工加回。\n'
