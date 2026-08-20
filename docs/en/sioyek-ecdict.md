# Sioyek ECDICT integration

[简体中文](../zh-CN/sioyek-ecdict.md)

This repository vendors `modules/sioyek-ecdict`, an offline English-to-Chinese lookup layer for native Linux Sioyek. It is kept separate from the generic snapshot restore because the first installation downloads and indexes the ECDICT dataset.

## Fast path on CachyOS

Install one AUR build of Sioyek, then clone this repository and run one script:

```bash
yay -S sioyek-git

git clone https://github.com/Eurekaimer/cachyos-config.git
cd cachyos-config
./scripts/install-sioyek-ecdict.sh
```

The wrapper installs missing repository packages (`uv`, `python-gobject`, and `gtk4-layer-shell`) with `pacman`, then runs the vendored module installer. Preview without changing the machine with:

```bash
./scripts/install-sioyek-ecdict.sh --dry-run
```

Keep the cloned repository in place after installation. The systemd user unit points to the virtual environment under `modules/sioyek-ecdict/.venv/`.

## Result

After restarting Sioyek:

1. Select an English word in a PDF.
2. Press `s`.
3. A Chinese definition card appears at the top-right and can be dragged or dismissed with `Esc`.

Lookup is case-insensitive, repairs common PDF line-break hyphens, resolves ECDICT inflections, and shows pronunciation, part of speech, lemma, dictionary rank, and frequency metadata. After the initial ECDICT download, lookup is fully offline.

The captured Niri configuration also binds `Super+S` to a global dictionary input. Other desktops can bind the D-Bus command documented in the [module README](../../modules/sioyek-ecdict/README.md).

## What the installer changes

```mermaid
flowchart LR
    S[Sioyek selected text] --> K[_ecdict s]
    K --> D[resident D-Bus service]
    D --> Q[indexed ECDICT SQLite]
    Q --> P[GTK4 layer-shell card]
```

The installer:

- installs native GTK bindings with the distribution package manager;
- rebuilds `modules/sioyek-ecdict/.venv/` with system site packages visible,
  then runs `uv sync --frozen` against the committed `uv.lock`;
- runs `sioyek-ecdict bootstrap`, which creates
  `${XDG_DATA_HOME:-~/.local/share}/sioyek-ecdict/ecdict.sqlite3` only when
  missing and otherwise reuses it;
- adds a `new_command _ecdict ... %{selected_text}` line to
  `~/.config/sioyek/prefs_user.config`;
- adds the space-delimited `_ecdict s` line to
  `~/.config/sioyek/keys_user.config`;
- enables `~/.config/systemd/user/sioyek-ecdict.service`, whose `ExecStart`
  records both the venv command and exact SQLite database path.

This split keeps ownership clear: uv owns the Python project and command; `pacman`
owns PyGObject, GTK4, and Gtk4LayerShell so they match the host ABI; bootstrap
owns only generated user data and integration. No `/etc/sioyek` file is
modified. The space in `_ecdict s` is significant: Sioyek silently ignores a
tab-delimited line, leaving its stock `external_search s` action active. The
installer removes earlier web-search integration and makes the local dictionary
binding override that stock action. No browser, clipboard polling, translation
API, or API key is used.

## Updates, status, and removal

The installation is idempotent. After pulling repository changes, rerun:

```bash
./scripts/install-sioyek-ecdict.sh
```

Inspect or query it directly:

```bash
systemctl --user status sioyek-ecdict.service
modules/sioyek-ecdict/.venv/bin/sioyek-ecdict lookup Map
```

Remove the service and owned Sioyek bindings while retaining the downloaded database:

```bash
./modules/sioyek-ecdict/uninstall.sh
```

## Troubleshooting

- Restart Sioyek after installation because it reads key files at startup.
- Use a native package or AppImage; Flatpak host integration is not supported.
- Confirm `~/.config/sioyek/keys_user.config` ends with `_ecdict s` using a normal space.
- Check `systemctl --user status sioyek-ecdict.service` if no card appears.
- Run the module tests with `modules/sioyek-ecdict/.venv/bin/python -m unittest discover -s modules/sioyek-ecdict/tests -v`.

The SQLite database lives outside the clone in the XDG data directory; the in-tree virtual environment is ignored by Git. Neither is published, and the source module contains no credentials or machine-specific paths.
