# cachyos-config

[![CachyOS](https://img.shields.io/badge/CachyOS-rolling-1793D1?logo=archlinux&logoColor=white)](https://cachyos.org/)
![Snapshot](https://img.shields.io/badge/snapshot-2026--07--29-2dba4e)
![Shell](https://img.shields.io/badge/scripts-Bash-4EAA25?logo=gnubash&logoColor=white)
[![Documentation](https://img.shields.io/badge/docs-English%20%7C%20中文-8A2BE2)](README.zh-CN.md)

**English** · [简体中文](README.zh-CN.md)

An auditable and repeatable recovery kit for a personal CachyOS workstation. It keeps configuration snapshots, package and service manifests, hardware references, and restore automation separate so each layer can be inspected or restored independently.

For a fresh installation, download the CachyOS ISO from the [official download page](https://cachyos.org/download/)—the torrent is recommended—then return here after the base system is installed.


[](/home/eurekaimer/Documents/GitHub/cachyos-config/system.png)

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

## Documentation

+ [Configuration map and restore boundaries](docs/en/configuration.md) · [中文](docs/zh-CN/configuration.md)
+ [Capture and snapshot maintenance](docs/en/capture.md) · [中文](docs/zh-CN/capture.md)
+ [Recovery workflow](docs/en/recovery.md) · [中文](docs/zh-CN/recovery.md)
+ [Packages and services](docs/en/packages-services.md) · [中文](docs/zh-CN/packages-services.md)
+ [Niri window manager](docs/en/niri.md) · [中文](docs/zh-CN/niri.md)
+ [Noctalia Shell](docs/en/noctalia.md) · [中文](docs/zh-CN/noctalia.md)
+ [Kitty, shells, and command-line tools](docs/en/kitty-shell.md) · [中文](docs/zh-CN/kitty-shell.md)
+ [MPV media stack](docs/en/mpv.md) · [中文](docs/zh-CN/mpv.md)
+ [Input methods and desktop integration](docs/en/input-desktop.md) · [中文](docs/zh-CN/input-desktop.md)
+ [Security and publishing boundaries](docs/en/security.md) · [中文](docs/zh-CN/security.md)
+ [External storage diagnostics](docs/en/storage-diagnostics.md) · [中文](docs/zh-CN/storage-diagnostics.md)
