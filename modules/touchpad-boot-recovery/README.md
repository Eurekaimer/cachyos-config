# touchpad-boot-recovery: touchpad boot self-recovery (Lenovo 82XF)

[简体中文](README.md)

The I2C touchpad on the Lenovo 82XF (IdeaPad Slim 5 16IRL8, i5-13500H, BIOS
LACN22WW; `MSFT0002:00 06CB:CEFE`, Microsoft ACPI HID) fails to register on
some boots: the kernel logs `irq 27: nobody cared` and disables the interrupt,
`i2c_designware.0` times out, and `i2c_hid_acpi i2c-MSFT0002:00` probe fails
with `-110`. The same kernel version has both good and bad boots; 6.18.42-1,
7.2.0-1, and 7.2.2-1 showed the same errors, so this is **not a single-version
regression**. A registered touchpad can also stop producing events at runtime;
rebinding the controller restored it (verified 2026-09-10).

This module installs a device-limited boot recovery:
`touchpad-boot-recovery.service` (oneshot, before `graphical.target` and
before `sddm`) waits up to 10 s after boot; if the touchpad is still missing
while the `i2c_designware.0` topology exists, it writes the controller name
to sysfs `unbind` then `bind` exactly once, and waits up to 5 s for the input
device to reappear. Already-registered, missing topology, and write failures
all exit safely. No retry loop, no unloading of shared modules, no `irqpoll`,
and no other device is touched.

This is a **workaround for an intermittent failure, not a kernel root-cause
fix**. The root cause is undetermined: boot timing, firmware, or a driver
interaction are all only possibilities. Several upstream reports with the same
or closely related signatures exist (reference list in
`docs/en/touchpad-boot-recovery.md`).

## Install

```bash
./scripts/install-touchpad-boot-recovery.sh
```

Runs as the desktop user and elevates via `sudo`. Pre-existing files with the
same names are backed up to
`~/.local/state/cachyos-config/module-backups/touchpad-boot-recovery.<timestamp>/`
before replacement. Installation `enable --now`s the unit, so it runs once for
the current session immediately and at every later boot.

Verify:

```bash
systemctl is-enabled touchpad-boot-recovery.service   # enabled
/usr/local/sbin/touchpad-boot-recovery                # Touchpad already registered; no recovery needed.
grep 'MSFT0002:00 06CB:CEFE Touchpad' /proc/bus/input/devices
```

A real next-boot check is only possible after the user reboots on their own:
inspect `journalctl -b _COMM=touchpad-boot-recovery` for the rebind and
registration lines, then move and click the pad.

## Remove

```bash
modules/touchpad-boot-recovery/uninstall.sh
```

Disables the unit and removes both files. It does not unbind the touchpad, so
the running session is unaffected.
