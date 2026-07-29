# Recovery workflow

[简体中文](../zh-CN/recovery.md)

Run recovery as the target desktop user, never as root. Audit and preview every change first:

```bash
./scripts/audit.sh
./scripts/restore-all.sh --dry-run
./scripts/restore-all.sh
sudo reboot
```

The combined restore installs packages and toolchains, restores portable system configuration, restores user configuration and dconf, then enables recorded services. Every mutating script supports `--dry-run`; each layer can also be run independently:

```bash
./scripts/install-packages.sh
./scripts/restore-system.sh
./scripts/restore-user.sh
./scripts/restore-services.sh
```

If AUR access is temporarily unavailable, use `install-packages.sh --skip-aur` and retry that layer later.

Do not pass `--with-hardware` on a new disk or host. That option overwrites `/etc/fstab` and `/etc/hostname`; compare `lsblk -f` and `findmnt --real` with `state/hardware/` before considering it.

After recovery, run `./scripts/audit.sh`, `niri validate`, verify the required commands and enabled services, and exercise the desktop shortcuts and default applications described in the component documents.
