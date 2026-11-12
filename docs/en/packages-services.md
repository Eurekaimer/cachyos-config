# Packages and services

[简体中文](../zh-CN/packages-services.md)

`packages/` separates package installation inputs from captured machine state.

**Install inputs** — read by `scripts/install-packages.sh`:

| Path | Role |
| --- | --- |
| `packages/profiles/full.txt` | Workstation profile: NVIDIA, gaming, containers, comms |
| `packages/profiles/minimal.txt` | ThinkPad T480 class profile: Intel iGPU, no gaming/containers, CN/EN TeX |
| `packages/required-extra.txt` | Packages the managed configuration or the recovery scripts themselves need |
| `packages/core.txt` | User-protected core packages; never auto-generated or removed during capture |

The installer combines the selected profile with `required-extra.txt`, resolves
repository packages, and sends other names to the AUR helper. Profiles are
installation choices; they are not the list of what is currently installed.

**Capture outputs** — written by `scripts/capture.sh`:

| Path | Content |
| --- | --- |
| `packages/inventory/explicit.txt` | Explicitly installed packages from repositories and foreign sources; dependency-installed packages are excluded |
| `packages/services/system.txt` | Enabled system units provided by installed packages |
| `packages/services/user.txt` | Enabled user units provided by installed packages |
| `packages/toolchains/rustup.txt` | Rust toolchains |
| `packages/toolchains/bun.txt` | Bun global tools, including the Oh My Pi agent |

The inventory follows pacman's explicit install reason (`pacman -Qqe`), whether
the package was installed via pacman or an AUR helper such as paru. It is a
current package list, not a history of commands: changing a package's install
reason changes whether it appears. The inventory is not installer input.
Service and toolchain lists are also used by the restore scripts.

Packages listed in `packages/core.txt` must not be uninstalled or removed from
the full restore profile unless the user first changes their tier. Other
packages are unclassified until the user decides; they are not deletion
candidates by default. `scripts/audit.sh` checks that each core package remains
in the full profile.

To count the recorded packages or refresh only this list without capturing
home configuration:

```bash
wc -l packages/inventory/explicit.txt
pacman -Qqe | LC_ALL=C sort -u > packages/inventory/explicit.txt
```

Compare two profiles with `./scripts/profile.sh diff full minimal`, select one
with `./scripts/profile.sh use minimal` or
`./scripts/install-packages.sh --profile minimal`. Restore packages with
`./scripts/install-packages.sh`; restore service enablement with
`./scripts/restore-services.sh`.
