# cachyos-config

[![CachyOS](https://img.shields.io/badge/CachyOS-rolling-1793D1?logo=archlinux&logoColor=white)](https://cachyos.org/)
![Snapshot](https://img.shields.io/badge/snapshot-2026--08--01-2dba4e)
![Shell](https://img.shields.io/badge/scripts-Bash-4EAA25?logo=gnubash&logoColor=white)
[![Documentation](https://img.shields.io/badge/docs-English%20%7C%20中文-8A2BE2)](README.zh-CN.md)
[![Python](https://img.shields.io/badge/Python-3.11%2B-3776AB?logo=python&logoColor=white)](modules/sioyek-ecdict/pyproject.toml)
[![SQLite](https://img.shields.io/badge/SQLite-offline-003B57?logo=sqlite&logoColor=white)](modules/sioyek-ecdict)
[![ECDICT](https://img.shields.io/badge/dictionary-ECDICT-6f42c1)](https://github.com/skywind3000/ECDICT)

**English** · [简体中文](README.zh-CN.md)

An auditable and repeatable recovery kit for a personal CachyOS workstation. It keeps configuration snapshots, package and service manifests, hardware references, and restore automation separate so each layer can be inspected or restored independently.

For a fresh installation, download the CachyOS ISO from the [official download page](https://cachyos.org/download/)—the torrent is recommended—then return here after the base system is installed.


![CachyOS desktop screenshot](system.png)

## Architecture

```mermaid
flowchart TD
    H[Current CachyOS workstation] --> C[scripts/capture.sh]
    C --> U[configs/home + dconf]
    C --> S[configs/system]
    C --> P[packages + services]
    C --> R[state + hardware references]
    M[manifests: path allowlists] --> C
    U --> A[scripts/audit.sh]
    S --> A
    P --> A
    R --> A
    A --> X[scripts/restore-all.sh]
    X --> I[Packages]
    X --> Y[System configuration]
    X --> Z[User configuration]
    X --> V[Services]
```

## One-command Sioyek offline dictionary

After installing native Sioyek from the AUR, this clone can add the bundled
offline ECDICT lookup without a separate plugin repository:

```bash
yay -S sioyek-git
git clone https://github.com/Eurekaimer/cachyos-config.git
cd cachyos-config
./scripts/install-sioyek-ecdict.sh
```

Restart Sioyek, select an English word, and press `s`. The first run downloads
and indexes ECDICT; later lookups are local and offline. See the
[Sioyek ECDICT guide](docs/en/sioyek-ecdict.md) for exact changes, Niri
`Super+S`, updating, troubleshooting, and removal.

## Syncing across machines

Git is the transport: capture on the machine you configure, restore on any other machine.

**Publish from the current machine** after any config, package, or service change:

```bash
./scripts/capture.sh     # rebuild the snapshot from the allowlists
./scripts/audit.sh       # refuse to publish if secrets or private paths leaked

git add -A
git commit -m "sync: refresh snapshot"
git push
```

**Apply on another machine** (fresh CachyOS install or any other computer):

```bash
git clone https://github.com/Eurekaimer/cachyos-config.git
cd cachyos-config

./scripts/audit.sh                   # review what the snapshot contains
./scripts/restore-all.sh --dry-run   # preview every replacement and install
./scripts/restore-all.sh             # packages, system, user config, services
sudo reboot
```

The default flow never touches machine-bound state: no disk UUIDs,
`/etc/machine-id`, `/etc/fstab`, or `/etc/hostname` are read or written. The
last two live in a separate hardware layer applied only with an explicit,
reviewed `--with-hardware` on the same disks/host. A different username on the
target machine is fine — absolute home paths in managed files are rewritten
for the current user at restore time.

## Neovim

The managed Neovim configuration is LazyVim-inspired but intentionally keeps
only nine plugin repositories. It uses Snacks for the general UI and Neovim
0.12 built-ins for completion, comments, snippets, statusline, and colors.
See the [complete Neovim guide](docs/en/neovim.md) ·
[中文](docs/zh-CN/neovim.md) for architecture, every plugin's GitHub link and
rationale, omitted alternatives, keymaps, LSP/Treesitter behavior, recovery,
maintenance, and troubleshooting.

## Documentation

### Configuration and recovery boundaries

+ [Configuration map and restore boundaries](docs/en/configuration.md) · [中文](docs/zh-CN/configuration.md)

### Subsystem and workflow guides

+ [Capture and snapshot maintenance](docs/en/capture.md) · [中文](docs/zh-CN/capture.md)
+ [External storage diagnostics](docs/en/storage-diagnostics.md) · [中文](docs/zh-CN/storage-diagnostics.md)
+ [Input methods and desktop integration](docs/en/input-desktop.md) · [中文](docs/zh-CN/input-desktop.md)
+ [Kitty, shells, and command-line tools](docs/en/kitty-shell.md) · [中文](docs/zh-CN/kitty-shell.md)
+ [MPV media stack](docs/en/mpv.md) · [中文](docs/zh-CN/mpv.md)
+ [Neovim editor](docs/en/neovim.md) · [中文](docs/zh-CN/neovim.md)
+ [Niri window manager](docs/en/niri.md) · [中文](docs/zh-CN/niri.md)
+ [Noctalia Shell](docs/en/noctalia.md) · [中文](docs/zh-CN/noctalia.md)
+ [Packages and services](docs/en/packages-services.md) · [中文](docs/zh-CN/packages-services.md)
+ [Recovery workflow](docs/en/recovery.md) · [中文](docs/zh-CN/recovery.md)
+ [SDDM Qt6 login theme](docs/en/sddm.md) · [中文](docs/zh-CN/sddm.md)
+ [Security and publishing boundaries](docs/en/security.md) · [中文](docs/zh-CN/security.md)
+ [Sioyek offline ECDICT lookup](docs/en/sioyek-ecdict.md) · [中文](docs/zh-CN/sioyek-ecdict.md)
