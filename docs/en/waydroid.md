# Waydroid (Android container, NVIDIA/Venus variant)

[简体中文](../zh-CN/waydroid.md)

This page documents the previous NVIDIA/Venus Android-container setup.
As of the 2026-10-19 capture, Waydroid is no longer installed on this workstation:
neither `waydroid-nvidia-bin` nor `waydroid-container.service` is restored
automatically. The remaining `wd-venus.service` and UFW configuration are kept.

That setup used `waydroid-nvidia-bin` for Venus/Virtio-GPU guest drivers and a
patched surfaceflinger, `wd-venus.service` for the virgl render server, and a
udev rule granting `uaccess` on `/dev/udmabuf`. Commands below require an
explicitly installed, supported Waydroid/NVIDIA package.

```mermaid
flowchart LR
    A[waydroid-container.service] --> B[Android container rootfs]
    C[wd-venus.service] --> D[Venus render server]
    D --> E[NVIDIA render node]
    B --> F[Waydroid app window]
```

## Relationship to the snapshot

| Item | Location | Restore behavior |
| --- | --- | --- |
| Package | `waydroid-nvidia-bin` | Removed from the captured inventory and `full` install profile; not installed automatically |
| System service | `waydroid-container.service` | Absent from the captured enabled-service list; not enabled automatically |
| User service | `wd-venus.service` | Still listed in `packages/services/user.txt`; `restore-services.sh` re-enables it when the unit exists |
| UFW rules | DHCP/DNS and forwarding rules for `waydroid0` | Restored with `configs/system/portable/etc/ufw/` |
| Container data | `/var/lib/waydroid/` (rootfs, images, `waydroid.cfg`, `waydroid.prop`, `nv/`; ~2.5 GB) | Not allowlisted — machine-local; re-initialize after a restore |

No kernel configuration is needed: the CachyOS kernel has
`CONFIG_ANDROID_BINDER_IPC` and `CONFIG_ANDROID_BINDERFS` built in, and
`/etc/modules-load.d/` contains no related entry.

## Daily use

| Action | Command |
| --- | --- |
| Check status | `waydroid status` |
| Start the session | `waydroid session start` |
| Show the full UI | `waydroid show-full-ui` |
| Launch one app | `waydroid app launch <package>` |
| Stop the session | `waydroid session stop` |

In the previous setup, `Vendor type` in `waydroid status` was `MAINLINE`
(the image source), and the desktop launcher entry was called `Waydroid`.

## Re-initialize after a restore

After explicitly installing a supported Waydroid/NVIDIA package on the target,
initialize its machine-local container data in this order:

```bash
sudo waydroid init                      # downloads and initializes the Android image (several GB; proxy needed on restricted networks)
sudo waydroid-nvidia-setup --refresh 144  # configures the NVIDIA/Venus stack for your monitor's refresh rate
```

`waydroid-nvidia-setup` must run after `waydroid init` and is safe to re-run;
repeat it after changing the monitor refresh rate or updating the kernel. Above
240 Hz it enables the vsync-snap path in the package's patched surfaceflinger,
which lower refresh rates do not need.
