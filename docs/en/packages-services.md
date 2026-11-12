# Packages and services

[简体中文](../zh-CN/packages-services.md)

`packages/` holds two kinds of file, and only one of them installs anything.

**Install inputs** — read by `scripts/install-packages.sh`:

| Path | Role |
| --- | --- |
| `packages/profiles/full.txt` | Workstation profile: NVIDIA, gaming, containers, comms |
| `packages/profiles/minimal.txt` | ThinkPad T480 class profile: Intel iGPU, no gaming/containers, CN/EN TeX |
| `packages/required-extra.txt` | Packages the managed configuration or the recovery scripts themselves need |

`profiles/*.txt` is the only package list the installer reads; the installer
resolves every name against the repositories and sends whatever is left to the
AUR helper, so a new package needs exactly one line. A package that is no longer
wanted is deleted from both profiles — there is no group filter, so a line left
in the file is installed.

**Capture outputs** — written by `scripts/capture.sh` and describing the machine
the snapshot came from:

| Path | Content |
| --- | --- |
| `packages/inventory/pacman-explicit.txt` | Explicitly installed repository packages |
| `packages/inventory/aur-explicit.txt` | Explicitly installed AUR/external packages |
| `packages/services/system.txt` | Enabled system units provided by installed packages |
| `packages/services/user.txt` | Enabled user units provided by installed packages |
| `packages/toolchains/rustup.txt` | Rust toolchains |
| `packages/toolchains/bun.txt` | Bun global tools, including the Oh My Pi agent |

A service snapshot is not an install list: only units shipped by an installed
package are recorded, so a module or hand-installed unit that never ran on the
target machine cannot make `restore-services.sh` warn. Package inventory is a
record of the source machine, not installer input — after a package is removed
from a profile and uninstalled, the inventory only matches again after the next
capture.

Compare two profiles with `./scripts/profile.sh diff full minimal`, select one
with `./scripts/profile.sh use minimal` or
`./scripts/install-packages.sh --profile minimal`. Restore packages with
`./scripts/install-packages.sh`; restore service enablement with
`./scripts/restore-services.sh`.
