# Configuration map

[简体中文](../zh-CN/configuration.md)

## User layer

`configs/home/` mirrors allowlisted paths under `$HOME`. It contains shell startup files, Git settings with the public email removed, Niri, Noctalia, Kitty, Starship, MPV, Fcitx5, Fastfetch, GTK, Micro, MIME associations, autostart entries, XDG directories, helper scripts, and wallpapers. `configs/dconf/user.ini` is a portable text export rather than the binary dconf database.

Restore this layer with:

```bash
./scripts/restore-user.sh --dry-run
./scripts/restore-user.sh
```

## Portable system layer

`configs/system/portable/` mirrors selected `/etc` files for Pacman, makepkg, mkinitcpio, locales, the console, environment variables, I²C/DDC, X11 keyboard settings, UFW, Snapper, and libvirt networking.

```bash
./scripts/restore-system.sh --dry-run
./scripts/restore-system.sh
```

The restore regenerates locales and initramfs and reloads systemd after copying.

## Hardware-bound layer

`configs/system/hardware/` contains `/etc/fstab` and `/etc/hostname`. These are excluded from normal recovery. Use `--with-hardware` only after disk UUIDs, Btrfs subvolumes, mount points, and host identity have been confirmed identical.

## Reference-only layer

`configs/system/reference/` contains location-dependent files such as the mirror list. `state/hardware/` records PCI, block-device, and mount information. Neither layer is a normal restore input.

The authoritative allowlists are under `manifests/`; add paths there instead of adding ad-hoc copy commands.
