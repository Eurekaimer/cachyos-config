# Packages and services

[简体中文](../zh-CN/packages-services.md)

The snapshot captured on `2026-07-29T22:31:32+08:00` contains:

| Source | Count | Manifest |
|---|---:|---|
| CachyOS/Arch repository packages | 220 | `packages/pacman-explicit.txt` |
| AUR/external packages | 13 | `packages/aur-explicit.txt` |
| Rustup toolchains | 1 | `packages/rustup-toolchains.txt` |
| Bun global packages | 1 | `packages/bun-global.txt` |
| Enabled system services | 29 | `packages/system-services.txt` |
| Enabled user services | 6 | `packages/user-services.txt` |

`packages/required-extra.txt` holds dependencies needed by the recovery tooling itself. The installer consumes these manifests directly; README tables are descriptive only.

Refresh all generated lists with `./scripts/capture.sh`. Restore packages alone with `./scripts/install-packages.sh`, and restore enablement state with `./scripts/restore-services.sh`. Missing service units are skipped rather than fabricated.
