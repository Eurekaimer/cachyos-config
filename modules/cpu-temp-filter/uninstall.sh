#!/usr/bin/env bash
set -euo pipefail

install_path="${CPU_TEMP_BIN_DIR:-$HOME/.local/bin}/cpu-temp-filter"
unit_path="$HOME/.config/systemd/user/cpu-temp-filter.service"
published="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/cpu-temp/temp1_input"

if [[ ! -e "$install_path" && ! -e "$unit_path" ]]; then
    echo "cpu-temp-filter 未安装，无需卸载。"
    exit 0
fi

systemctl --user disable --now cpu-temp-filter.service 2>/dev/null || true
rm -f "$unit_path" "$install_path"
systemctl --user daemon-reload
printf '已移除 %s 与 %s\n' "$install_path" "$unit_path"
printf '发布文件 %s 随服务停止由 systemd 清理。\n' "$published"
printf 'Noctalia 的 [system.monitor].cpu_temp_sensor_path 仍指向该路径；改回自动探测请删掉该键后运行 noctalia msg config-reload。\n'
