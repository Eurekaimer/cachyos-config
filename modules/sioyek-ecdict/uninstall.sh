#!/usr/bin/env bash
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
sioyek_dir="${SIOYEK_CONFIG_DIR:-$config_home/sioyek}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"

# Stop the resident process before removing its unit.
systemctl --user disable --now sioyek-ecdict.service 2>/dev/null || true
rm -f "$config_home/systemd/user/sioyek-ecdict.service"
rm -f "$data_home/applications/sioyek-ecdict.desktop"
systemctl --user daemon-reload

# Remove only lines owned by this integration; preserve every user binding.
python3 - "$sioyek_dir" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
for name in ("prefs_user.config", "keys_user.config"):
    path = root / name
    if not path.exists():
        continue
    lines = [
        line
        for line in path.read_text(encoding="utf-8").splitlines()
        if "Sioyek ECDICT" not in line
        and "Warm D-Bus lookup" not in line
        and "Sioyek 2.0 compatibility" not in line
        and "Single-key local lookup" not in line
        and not (
            name == "prefs_user.config"
            and line.lstrip().startswith(("search_url_d", "search_url_s"))
        )
        and not (name == "prefs_user.config" and line.lstrip().startswith("google_scholar_address"))
        and not (name == "prefs_user.config" and line.lstrip().startswith("libgen_address"))
        and not line.lstrip().startswith("new_command _ecdict")
        and not line.lstrip().startswith("_ecdict")
        and not (name == "keys_user.config" and line.lstrip().startswith("external_search"))
        and not (
            name == "keys_user.config"
            and line.lstrip().startswith("search_selected_text_in_google_scholar")
        )
        and not (
            name == "keys_user.config"
            and line.lstrip().startswith("search_selected_text_in_libgen")
        )
    ]
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
PY

printf '已移除服务和 Sioyek 查词绑定。项目目录与本地词典数据已保留。\n'
