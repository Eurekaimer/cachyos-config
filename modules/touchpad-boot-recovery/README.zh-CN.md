# touchpad-boot-recovery：触摸板开机自恢复（Lenovo 82XF）

[English](README.md)

Lenovo 82XF（IdeaPad Slim 5 16IRL8，i5-13500H，BIOS LACN22WW）的 I2C 触摸板
（`MSFT0002:00 06CB:CEFE`，Synaptics/微软 ACPI HID）在部分开机时无法注册：
内核在 `irq 27: nobody cared` 后禁用该中断，`i2c_designware.0` 超时，
`i2c_hid_acpi i2c-MSFT0002:00` 探测失败（`-110`）。同一内核版本既有成功也有
失败启动；6.18.42-1、7.2.0-1、7.2.2-1 也出现过同样错误，**不是单版本回归**。
已注册的触摸板还可能在运行中停止产生事件，重绑控制器可恢复（2026-09-10 实测）。

本模块安装一个限定的开机自恢复：`touchpad-boot-recovery.service`（oneshot，
`display-manager.service`（sddm）之前）在开机后最多等 10 秒；触摸板仍未注册且
`i2c_designware.0` 拓扑存在时，向 sysfs `unbind`/`bind` 各写一次，再等最多
5 秒确认输入设备重新出现。已注册、拓扑缺失或写入失败都安全退出；不循环重试，
不卸载共享模块，不加载 `irqpoll`，不碰其他设备。

这是**间歇性故障的应对，不是内核根因修复**。根因未定：启动时序 /
固件 / 驱动交互都只是可能性。上游已有多份相同或相近报告
（见 `docs/zh-CN/touchpad-boot-recovery.md` 的引用列表）。

## 安装

```bash
./scripts/install-touchpad-boot-recovery.sh
```

需要桌面用户 + `sudo`（脚本内部提权）。已存在的同名文件会先备份到
`~/.local/state/cachyos-config/module-backups/touchpad-boot-recovery.<时间戳>/`。
安装即 `enable --now`：当前会话立即跑一次；下次开机自动生效。

验证：

```bash
systemctl is-enabled touchpad-boot-recovery.service   # enabled
/usr/local/sbin/touchpad-boot-recovery                # Touchpad already registered; no recovery needed.
grep 'MSFT0002:00 06CB:CEFE Touchpad' /proc/bus/input/devices
```

真实下一次启动的验证只能在用户自主重启后完成：看
`journalctl -b _COMM=touchpad-boot-recovery` 是否出现重绑与注册日志，并实际
移动/点击确认。

## 卸载

```bash
modules/touchpad-boot-recovery/uninstall.sh
```

停用服务并删除两个文件；不解绑触摸板，当前会话不受影响。
