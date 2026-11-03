#!/usr/bin/env bash
set -euo pipefail

module_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${CPU_TEMP_BIN_DIR:-$HOME/.local/bin}"
unit_dir="$HOME/.config/systemd/user"
install_path="$bin_dir/cpu-temp-filter"
unit_path="$unit_dir/cpu-temp-filter.service"
backup_dir="${CACHYOS_MODULE_BACKUPS:-$HOME/.local/state/cachyos-config/module-backups}"

die() {
    printf '安装失败：%s\n' "$*" >&2
    exit 1
}

[[ "$(uname -s)" == "Linux" ]] || die "目前只支持 Linux。"
command -v python3 >/dev/null 2>&1 || die "缺少 python3（过滤器是 python3 脚本）。"

mkdir -p "$bin_dir" "$unit_dir"

# 备份已存在的旧版本，避免覆盖用户改动而不留退路
for target in "$install_path" "$unit_path"; do
    [[ -e "$target" || -L "$target" ]] || continue
    mkdir -p "$backup_dir"
    backup_path="$backup_dir/$(basename "$target").$(date +%Y%m%d-%H%M%S)"
    cp -a "$target" "$backup_path" || die "备份 $target 失败"
    printf '已备份旧版本到 %s\n' "$backup_path"
done

install -m 0755 "$module_dir/cpu-temp-filter" "$install_path"
install -m 0644 "$module_dir/cpu-temp-filter.service" "$unit_path"
printf '已安装 %s\n' "$install_path"
printf '已安装 %s\n' "$unit_path"

systemctl --user daemon-reload
systemctl --user enable --now cpu-temp-filter.service
sleep 2
if ! systemctl --user is-active --quiet cpu-temp-filter.service; then
    die "cpu-temp-filter.service 未能启动，查看 journalctl --user -u cpu-temp-filter.service"
fi

published="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/cpu-temp/temp1_input"
[[ -r "$published" ]] || die "服务已启动但 $published 还不存在，稍等 1 秒再检查"
printf '已发布过滤温度：%s（当前 %s）\n' "$published" "$(cat "$published")"

# Noctalia 只接受 temp*_input 文件名，且直接读绝对路径、不做 ~ 展开。
if command -v noctalia >/dev/null 2>&1; then
    configured="$(noctalia msg config-get system.monitor.cpu_temp_sensor_path 2>/dev/null || true)"
    printf 'Noctalia cpu_temp_sensor_path = %s\n' "${configured:-<未设置>}"
    if [[ "$configured" != *"/cpu-temp/temp1_input"* ]]; then
        printf '提示：把 ~/.config/noctalia/config.toml 的 [system.monitor].cpu_temp_sensor_path 指向 %s 后运行 noctalia msg config-reload。\n' "$published"
    fi
fi
