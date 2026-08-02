# Recovery workflow

[简体中文](../zh-CN/recovery.md)

On a machine that does not have the repository yet, clone it first:

```bash
git clone https://github.com/Eurekaimer/cachyos-config.git
cd cachyos-config
```

Run recovery as the target desktop user, never as root. Audit and preview every change first:

```bash
./scripts/audit.sh
./scripts/restore-all.sh --dry-run
./scripts/restore-all.sh
sudo reboot
```

Recovery is safe on any machine: it never touches disk UUIDs, `/etc/machine-id`, `/etc/fstab`, or `/etc/hostname`, and captured home paths are rewritten for the current user when the username differs.

The combined restore installs packages and toolchains, restores portable system configuration, restores user configuration and dconf, then enables recorded services. Every mutating script supports `--dry-run`; each layer can also be run independently:

```bash
./scripts/install-packages.sh
./scripts/restore-system.sh
./scripts/restore-user.sh
./scripts/restore-services.sh
```

The vendored Sioyek dictionary is an explicit post-restore step because it
downloads ECDICT data. Once the AUR package layer has installed Sioyek, run:

```bash
./scripts/install-sioyek-ecdict.sh
```

Restart Sioyek, select an English word, and press `s`. See the
[component guide](sioyek-ecdict.md) for the generated files and removal.

If AUR access is temporarily unavailable, use `install-packages.sh --skip-aur` and retry that layer later.

Do not pass `--with-hardware` on a new disk or host. That option overwrites `/etc/fstab` and `/etc/hostname`; compare `lsblk -f` and `findmnt --real` with `state/hardware/` before considering it.

After recovery, run `./scripts/audit.sh`, `niri validate`, verify the required commands and enabled services, and exercise the desktop shortcuts and default applications described in the component documents.
