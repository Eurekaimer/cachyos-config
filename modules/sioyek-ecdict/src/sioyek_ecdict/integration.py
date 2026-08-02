from __future__ import annotations

import os
import subprocess
from pathlib import Path

from .dictionary import DEFAULT_DB

LOOKUP_KEY = "s"
COMMAND_NAME = "_ecdict"
DBUS_NAME = "io.github.sioyek.ecdict"
DBUS_PATH = "/io/github/sioyek/ecdict"



def _config_home() -> Path:
    """Return the user's XDG configuration directory."""
    return Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))


def _data_home() -> Path:
    """Return the user's XDG data directory."""
    return Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))


def _sioyek_config_dir() -> Path:
    """Locate Sioyek's native Linux user configuration directory.

    ``SIOYEK_CONFIG_DIR`` supports nonstandard packages. Otherwise an existing
    XDG config wins; a fresh installation uses the standard XDG location.
    """
    override = os.environ.get("SIOYEK_CONFIG_DIR")
    if override:
        return Path(override).expanduser()
    standard = _config_home() / "sioyek"
    candidates = (standard, Path.home() / ".config/sioyek")
    for candidate in candidates:
        if (candidate / "prefs_user.config").exists() or (
            candidate / "keys_user.config"
        ).exists():
            return candidate
    return standard


def _read_lines(path: Path) -> list[str]:
    """Read a Sioyek user configuration while tolerating a missing file."""
    return path.read_text(encoding="utf-8").splitlines() if path.exists() else []


def _trim_trailing_blanks(lines: list[str]) -> list[str]:
    """Remove accumulated separator lines before appending our config section."""
    while lines and not lines[-1].strip():
        lines.pop()
    return lines


def _service_unit(executable: Path, database: Path = DEFAULT_DB) -> str:
    """Build the user unit with explicit executable and database paths."""
    return "\n".join(
        (
            "[Unit]",
            "Description=Low-latency Sioyek ECDICT popup service",
            "After=graphical-session.target",
            "",
            "[Service]",
            "Type=simple",
            "Environment=LD_PRELOAD=libgtk4-layer-shell.so.0",
            f'ExecStart="{executable}" --database "{database}" serve',
            "Restart=on-failure",
            "RestartSec=1",
            "",
            "[Install]",
            "WantedBy=default.target",
            "",
        )
    )


def _dbus_command() -> str:
    """Build Sioyek's selected-text command for the resident D-Bus service."""
    return (
        f"new_command {COMMAND_NAME} /usr/bin/gdbus call --session "
        f"--dest {DBUS_NAME} --object-path {DBUS_PATH} "
        f"--method {DBUS_NAME}.Lookup %{{selected_text}}"
    )


def configure_sioyek(
    executable: Path | None = None,
    *,
    database: Path = DEFAULT_DB,
    manage_service: bool = True,
) -> tuple[Path, Path, Path, str]:
    """Install a direct one-key lookup and remove external web search.

    Sioyek separates fields with spaces, not tabs. Keeping the command and key
    on a space-delimited line makes ``s`` override its stock external-search
    prefix and forwards the selected text directly to the warm D-Bus service.
    """
    executable = (
        executable
        or Path(__file__).resolve().parents[2] / ".venv/bin/sioyek-ecdict"
    )
    config_dir = _sioyek_config_dir()
    config_dir.mkdir(parents=True, exist_ok=True)
    prefs = config_dir / "prefs_user.config"
    keys = config_dir / "keys_user.config"

    key_lines = _trim_trailing_blanks(
        [
            line
            for line in _read_lines(keys)
            if not line.lstrip().startswith("_ecdict")
            and line.split() != ["copy", LOOKUP_KEY]
            and not line.lstrip().startswith("external_search")
            and not line.lstrip().startswith("search_selected_text_in_google_scholar")
            and not line.lstrip().startswith("search_selected_text_in_libgen")
            and "Sioyek ECDICT" not in line
        ]
    )
    key_lines.extend(
        (
            "",
            "# Sioyek ECDICT: selected English -> local popup. Web search disabled.",
            f"{COMMAND_NAME} {LOOKUP_KEY}",
        )
    )
    keys.write_text("\n".join(key_lines).lstrip() + "\n", encoding="utf-8")

    pref_lines = _trim_trailing_blanks(
        [
            line
            for line in _read_lines(prefs)
            if not line.lstrip().startswith("new_command _ecdict")
            and not line.lstrip().startswith("search_url_d")
            and not line.lstrip().startswith("search_url_s")
            and not line.lstrip().startswith("google_scholar_address")
            and not line.lstrip().startswith("libgen_address")
            and "Offline ECDICT" not in line
            and "Warm D-Bus lookup" not in line
            and "Warm local lookup only" not in line
            and "Warm local ECDICT lookup" not in line
            and "Sioyek 2.0 compatibility" not in line
            and "Single-key local lookup" not in line
        ]
    )
    pref_lines.extend(
        ("", "# Warm local ECDICT lookup; web search disabled.", _dbus_command())
    )
    prefs.write_text("\n".join(pref_lines).lstrip() + "\n", encoding="utf-8")

    systemd_dir = _config_home() / "systemd/user"
    systemd_dir.mkdir(parents=True, exist_ok=True)
    unit = systemd_dir / "sioyek-ecdict.service"
    unit.write_text(_service_unit(executable, database), encoding="utf-8")

    # Remove the abandoned web-search/URI route from previous revisions.
    (_data_home() / "applications/sioyek-ecdict.desktop").unlink(missing_ok=True)
    if manage_service:
        subprocess.run(["systemctl", "--user", "daemon-reload"], check=True)
        subprocess.run(["systemctl", "--user", "enable", unit.name], check=True)
        subprocess.run(["systemctl", "--user", "restart", unit.name], check=True)
    return prefs, keys, unit, LOOKUP_KEY
