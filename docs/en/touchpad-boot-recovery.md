# Touchpad boot self-recovery (Lenovo 82XF I2C touchpad)

[简体中文](../zh-CN/touchpad-boot-recovery.md)

## Symptom

The I2C touchpad on this Lenovo 82XF (IdeaPad Slim 5 16IRL8, i5-13500H Raptor
Lake-P, BIOS LACN22WW 02/17/2023) fails to register on some boots. Kernel log
signature of a failing boot (2026-09-10, `6.18.48-1-cachyos-lts`):

```text
[ 4.926] irq 27: nobody cared (try booting with the "irqpoll" option)
        handlers: [idma64_irq] [i2c_dw_isr]
[ 8.543] i2c_designware i2c_designware.0: controller timed out
[ 8.543] i2c_hid_acpi i2c-MSFT0002:00: can't add hid device: -110
[ 8.543] i2c_hid_acpi i2c-MSFT0002:00: probe with driver i2c_hid_acpi failed with error -110
```

IRQ 27 is shared by `idma64.0` and `i2c_designware.0`. The same kernel version
has both good and bad boots; historical logs show `6.18.42-1-cachyos-lts`,
`7.2.0-1-cachyos`, and `7.2.2-1-cachyos` producing the same signature, so this
**is not a single-version regression, and switching kernels is not a
guaranteed fix**. A registered touchpad can also stop producing events at
runtime (reproduced 2026-09-10 at 11:05; rebind of the controller restored it;
a root capture at 11:10 then showed 34 real EV_ABS/EV_KEY multitouch events),
so "device registered" does not mean "touchpad usable".

The root cause is undetermined: boot timing, firmware (BIOS LACN22WW,
2023-02), or a driver interaction are all only possibilities. Do not claim a
kernel upgrade will fix this based on the current evidence.

## Upstream reports (searched 2026-09-10)

There are several related reports upstream. None of them contains this
machine's data point (82XF + `06CB:CEFE` + multiple kernel versions + runtime
death), so the useful move is to add it as a comment rather than file a new
issue:

+ [CachyOS/linux-cachyos#858](https://github.com/CachyOS/linux-cachyos/issues/858):
  HP ENVY 13-ba1xxx (Tiger Lake, SYNA329D), works on `7.0.9`, broken on
  `7.0.10`, `6.18.33-lts` also broken; the signature is identical to this
  machine (`irq 27: nobody cared` with handlers `[idma64_irq] [i2c_dw_isr]`
  → `i2c_designware.0: controller timed out` → `-110`). ptr1337 checked the
  upstream commits and found nothing related; removing `acpi_osi=Linux` was
  suggested as a test.
+ [CachyOS/linux-cachyos#982](https://github.com/CachyOS/linux-cachyos/issues/982):
  deferred i2c_designware probe with a missing touchpad on 7.2.0-rc7 (a
  different machine, closely related mechanism).
+ [Arch Linux forums 312363](https://bbs.archlinux.org/viewtopic.php?id=312363):
  Lenovo IdeaPad Slim 5 16IRL8 (Alder Lake-P, ELAN06FA, 6.18.9-arch1) fails on
  roughly 12 of 13 cold boots with `controller timed out` + `-110`; the
  reporter tried `i8042.reset`, `acpi_osi=`, `acpi=noirq`, and `irqpoll` with
  no effect; the thread contains a PCI remove/rescan workaround
  (`/sys/bus/pci/devices/0000:00:15.0/remove` + rescan).
+ [Ubuntu bug 2072612](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/2072612):
  Lenovo 82ND (Yoga 6 13ALC6, i2c_designware AMDI0010) touchpad dies
  **intermittently at runtime** with `controller timed out` + `timeout waiting
  for bus ready`; only a reboot restores it; it still reproduced on upstream
  6.10-rc4; forwarded to
  [bugzilla.kernel.org 219101](https://bugzilla.kernel.org/show_bug.cgi?id=219101).
+ [bugzilla.kernel.org 181003](https://bugzilla.kernel.org/show_bug.cgi?id=181003):
  i2c_designware problem dating back to 2016; the problem family is old.

Related but not matching this signature:

+ `d3429178ee51` (Jinhui Guo, 2025-10) `i2c: designware: Disable SMBus
  interrupts to prevent storms from mis-configured firmware`: prevents an SMBus
  interrupt storm when firmware wrongly leaves `IC_SMBUS` enabled; backported
  to stable (6.6–6.18). This machine's failure is a controller timeout plus
  probe failure, not an SMBus storm, but it is the same designware-firmware
  interaction family.
+ pinctrl build-form hypothesis: the CachyOS kernel builds
  `CONFIG_PINCTRL_ICELAKE=m` (Tiger Lake family; `lsmod` on the current kernel
  shows `pinctrl_tigerlake` loaded). Intel pinctrl being a module rather than
  built-in could allow a probe-deferral race. Hypothesis only, unverified.

## Machine-side response: device-limited boot self-recovery

`modules/touchpad-boot-recovery` installs a oneshot systemd unit
(`Before=display-manager.service`, so it finishes before sddm;
`WantedBy=graphical.target`):

+ after boot it waits up to 10 s (checking every 0.25 s) for the touchpad
  input device to register;
+ if it is still missing while the `i2c_designware.0` /
  `i2c-0/i2c-MSFT0002:00` topology exists, it writes `i2c_designware.0` to
  `/sys/bus/platform/drivers/i2c_designware/unbind` and then `bind` exactly
  once (only that controller is rebound; no shared module is unloaded);
+ it then waits up to 5 s for `MSFT0002:00 06CB:CEFE Touchpad` to appear in
  `/sys/class/input/event*/device/name` with the device resolving under this
  controller's sysfs path (full-text name match plus path constraint, so a
  bare "Mouse" sub-device or any other touchpad can never count);
+ already-registered, missing topology, and write failures all exit safely
  (exit 0 means nothing was needed/possible, 1 means the rebind happened but
  the device is still absent); no retry loop, no timer/udev rules, no boot
  parameters or BIOS changes.

Install and verify instructions:
[modules/touchpad-boot-recovery/README.md](../../modules/touchpad-boot-recovery/README.md).

## Boundaries and rollback

+ The self-recovery is a persistent response to an intermittent failure, **not
  a kernel root-cause fix**. If a rebind fails once, keep the logs and stop;
  the next step is independent kernel/firmware diagnosis, not a global
  `irqpoll` parameter or unbounded retries.
+ If the device registers but the user still reports failure, that is not a
  successful recovery: switch to runtime input diagnostics (udev/libinput/
  compositor layer) instead of adding a rebind loop.
+ Rollback: `modules/touchpad-boot-recovery/uninstall.sh` (disables the unit
  and removes both files; it does not unbind the touchpad). If install.sh
  backed up pre-existing files, restore the backup instead of deleting.
+ Config/current-session verification is not a real next-boot verification:
  the user must reboot on their own and check
  `journalctl -b _COMM=touchpad-boot-recovery` plus actual pad use. No
  automatic reboot.
