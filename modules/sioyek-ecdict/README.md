# sioyek-ecdict

[![Python](https://img.shields.io/badge/Python-3.11%2B-3776AB?logo=python&logoColor=white)](pyproject.toml)
![SQLite](https://img.shields.io/badge/SQLite-offline-003B57?logo=sqlite&logoColor=white)
[![ECDICT](https://img.shields.io/badge/dictionary-ECDICT-6f42c1)](https://github.com/skywind3000/ECDICT)
![Linux](https://img.shields.io/badge/platform-Linux-FCC624?logo=linux&logoColor=black)

[简体中文](README.zh-CN.md)

Fast offline English-to-Chinese lookup for [Sioyek](https://github.com/ahrm/sioyek), backed by [ECDICT](https://github.com/skywind3000/ECDICT). Linux only.

## What it does

- Select English in Sioyek and press `s`; the result card appears at the top-right.
- Open a global dictionary input with `Super+S` after adding one desktop shortcut.
- Uses a resident GTK/SQLite D-Bus service: no browser, clipboard polling, network request, or Python cold start per lookup.
- Shows Chinese definitions, phonetics, part of speech, lemma and frequency metadata.
- Handles common PDF line-break hyphens and ECDICT inflected forms.
- The result card is draggable; drag events are frame-coalesced for smooth movement.
- `Esc`, the close button, or a click outside dismisses the overlay.
- Works fully offline after the first import.

## Fast install on CachyOS

Install the native Sioyek AUR package first:

```bash
yay -S sioyek-git
```

Then clone the workstation repository and run its one-command installer:

```bash
git clone https://github.com/Eurekaimer/cachyos-config.git
cd cachyos-config
./scripts/install-sioyek-ecdict.sh
```

The wrapper installs missing Arch dependencies (`uv`, `python-gobject`, and
`gtk4-layer-shell`) with `pacman`, then runs the vendored installer. The
installer resolves the Python project from `uv.lock` with `uv sync --frozen`
and invokes one idempotent `bootstrap` command. The first bootstrap downloads
ECDICT and builds
`${XDG_DATA_HOME:-~/.local/share}/sioyek-ecdict/ecdict.sqlite3`; later runs
reuse it. Keep the clone in place because the systemd user service runs the
virtual environment stored inside this module.

Restart Sioyek after installation. Select an English word and press `s`.

## Manual module install

Use a native Linux Sioyek package or AppImage. Flatpak host integration is not
currently tested or supported. From the repository root:

```bash
# Arch Linux / CachyOS
sudo pacman -S --needed uv python-gobject gtk4-layer-shell
./modules/sioyek-ecdict/install.sh

# Debian / Ubuntu (package availability depends on release)
sudo apt install python3-gi gir1.2-gtk-4.0 gir1.2-gtk4layershell-1.0
./modules/sioyek-ecdict/install.sh

# Fedora
sudo dnf install uv python3-gobject gtk4-layer-shell
./modules/sioyek-ecdict/install.sh
```

The installer validates Linux, Sioyek, uv, GLib, GTK4, and layer-shell before
changing configuration. It then:

1. Rebuilds an isolated uv environment that can reuse the distribution GTK ABI.
2. Runs `uv sync --frozen`, making `pyproject.toml` and `uv.lock` the complete
   Python environment definition.
3. Runs `sioyek-ecdict bootstrap`: import ECDICT only when the XDG database is
   absent, then refresh the Sioyek integration idempotently.
4. Finds an existing XDG Sioyek configuration, or creates `~/.config/sioyek`.
5. Installs `prefs_user.config`, `keys_user.config`, and a systemd user service
   whose command names the exact SQLite database path.

The installer's core commands are:

```bash
cd modules/sioyek-ecdict
uv venv --python /usr/bin/python3 --system-site-packages .venv
uv sync --frozen
uv run --no-sync sioyek-ecdict bootstrap
```

`uv` owns the Python package, lockfile, virtual environment, and console
command. The distribution package manager owns PyGObject, GTK4, and
Gtk4LayerShell because those bindings must match the host ABI. `bootstrap`
owns only the generated SQLite database, Sioyek user entries, and systemd user
unit; it never modifies `/etc/sioyek`.

For a nonstandard Sioyek config path:

```bash
SIOYEK_CONFIG_DIR=/path/to/sioyek/config ./modules/sioyek-ecdict/install.sh
```

## Keys

| Key | Action |
|---|---|
| `s` | Look up selected English text; empty selection is a silent no-op |
| `Super+S` | Open the global dictionary input after configuring the compositor binding below |

The installer gives `s` a space-delimited `_ecdict s` binding, overriding
Sioyek's stock `external_search s` action. No Google Scholar or other web-search
replacement is installed.

## Global `Super+S` input
The bundled Niri snapshot already contains this binding. Other desktops can run
the same command from a custom `Super+S` shortcut:


```bash
gdbus call --session \
  --dest io.github.sioyek.ecdict \
  --object-path /io/github/sioyek/ecdict \
  --method io.github.sioyek.ecdict.Prompt
```

Niri example inside `binds { ... }`:

```kdl
Mod+S hotkey-overlay-title="Open ECDICT dictionary" { spawn "gdbus" "call" "--session" "--dest" "io.github.sioyek.ecdict" "--object-path" "/io/github/sioyek/ecdict" "--method" "io.github.sioyek.ecdict.Prompt"; }
```

Hyprland example:

```ini
bind = SUPER, S, exec, gdbus call --session --dest io.github.sioyek.ecdict --object-path /io/github/sioyek/ecdict --method io.github.sioyek.ecdict.Prompt
```

KDE Plasma and GNOME users can bind the same command in their system keyboard-shortcut settings.

## Manual use

```bash
modules/sioyek-ecdict/.venv/bin/sioyek-ecdict lookup dependencies
systemctl --user status sioyek-ecdict.service
```

## Sioyek integration

The installer defines `_ecdict` in `prefs_user.config` as a `gdbus` call whose `%{selected_text}` argument is supplied by Sioyek, then writes `_ecdict s` to `keys_user.config`. Sioyek's parser requires a space between command and key; a tab silently drops the binding and leaves its default web search active. The command sends the selection directly to the warm D-Bus service—no browser, URI handler, clipboard, or network request is involved. The service performs the indexed SQLite lookup and presents a GTK4 layer-shell overlay.

## Uninstall

```bash
./modules/sioyek-ecdict/uninstall.sh
```

The script removes the user service and owned Sioyek bindings, restores Sioyek's default external-search prefix, and preserves the project directory and local dictionary database.

## Development

```bash
modules/sioyek-ecdict/.venv/bin/python -m unittest discover -s modules/sioyek-ecdict/tests -v
```
