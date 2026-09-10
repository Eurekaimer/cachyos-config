# 触摸板开机自恢复（Lenovo 82XF I2C 触摸板）

[English](../en/touchpad-boot-recovery.md)

## 问题现象

本机 Lenovo 82XF（IdeaPad Slim 5 16IRL8，i5-13500H Raptor Lake-P，BIOS
LACN22WW 02/17/2023）的 I2C 触摸板在部分开机时无法注册。失败启动的内核日志
签名（2026-09-10，`6.18.48-1-cachyos-lts`）：

```text
[ 4.926] irq 27: nobody cared (try booting with the "irqpoll" option)
        handlers: [idma64_irq] [i2c_dw_isr]
[ 8.543] i2c_designware i2c_designware.0: controller timed out
[ 8.543] i2c_hid_acpi i2c-MSFT0002:00: can't add hid device: -110
[ 8.543] i2c_hid_acpi i2c-MSFT0002:00: probe with driver i2c_hid_acpi failed with error -110
```

IRQ 27 同时挂 `idma64.0` 与 `i2c_designware.0`。同一内核版本既有成功也有失败
启动；历史日志显示 `6.18.42-1-cachyos-lts`、`7.2.0-1-cachyos`、`7.2.2-1-cachyos`
同样出现该签名，**不能称为单版本回归，换内核不保证解决**。另外，已注册的触摸板
在运行中也可能停止产生事件（2026-09-10 11:05 复现，重绑控制器后恢复；重绑后
11:10 root 捕获到 34 个真实 EV_ABS/EV_KEY 多指事件），因此“设备已注册”不等于
“触摸板可用”。

根因未定：启动时序、固件（BIOS LACN22WW，2023-02）或驱动交互都只是可能性。
不要据此宣称升级内核必然解决。

## 上游报告（2026-09-10 检索）

问题已有相当多的同族报告，本机的数据点（82XF + `06CB:CEFE` + 多内核版本 +
运行中失效）尚未见于任何一条，建议作为评论补充而不是另开新票：

+ [CachyOS/linux-cachyos#858](https://github.com/CachyOS/linux-cachyos/issues/858)：
  HP ENVY 13-ba1xxx（Tiger Lake，SYNA329D）`7.0.9` 正常 / `7.0.10` 失效，
  `6.18.33-lts` 同样失效；签名与本机完全一致（`irq 27: nobody cared`
  handlers `[idma64_irq] [i2c_dw_isr]` → `i2c_designware.0: controller timed
  out` → `-110`）。ptr1337 已排查过上游提交未找到相关修复，建议试过
  去掉 `acpi_osi=Linux`。
+ [CachyOS/linux-cachyos#982](https://github.com/CachyOS/linux-cachyos/issues/982)：
  7.2.0-rc7 上 i2c_designware 延迟探测，触摸板缺失（另一机型，机制相近）。
+ [Arch Linux 论坛 312363](https://bbs.archlinux.org/viewtopic.php?id=312363)：
  Lenovo IdeaPad Slim 5 16IRL8（Alder Lake-P，ELAN06FA，6.18.9-arch1）
  约 12/13 冷启动失败，`controller timed out` + `-110`；楼主试过
  `i8042.reset`、`acpi_osi=`、`acpi=noirq`、`irqpoll` 均无效；楼内有一个
  PCI 移除/重枚举的 workaround（`/sys/bus/pci/devices/0000:00:15.0/remove` +
  rescan）。
+ [Ubuntu bug 2072612](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/2072612)：
  Lenovo 82ND（Yoga 6 13ALC6，i2c_designware AMDI0010）**运行中**间歇失效，
  `controller timed out` + `timeout waiting for bus ready`，重启才恢复；
  6.10-rc4 上游内核仍复现，已转入
  [bugzilla.kernel.org 219101](https://bugzilla.kernel.org/show_bug.cgi?id=219101)。
+ [bugzilla.kernel.org 181003](https://bugzilla.kernel.org/show_bug.cgi?id=181003)：
  i2c_designware 相关问题（2016 年起），该问题族历史很长。

相关但未命中本签名的上游线索：

+ `d3429178ee51`（Jinhui Guo，2025-10）`i2c: designware: Disable SMBus
  interrupts to prevent storms from mis-configured firmware`：防止固件错误
  置位 `IC_SMBUS` 导致的 SMBus 中断风暴，已回稳定树（6.6–6.18）。本机
  故障是控制器超时 + 探测失败，不是 SMBus 中断风暴，方向不同，但同属
  designware 固件交互问题。
+ pinctrl 构建形式假说：CachyOS 内核 `CONFIG_PINCTRL_ICELAKE=m`
  （Tiger Lake 同族，当前内核 `lsmod` 可见 `pinctrl_tigerlake` 已加载），
  Intel pinctrl 为模块而非内建时存在探测延迟/竞争的可能。仅为假说，无
  已验证结论。

## 本机应对：限定设备的开机自恢复

`modules/touchpad-boot-recovery` 安装一个 oneshot systemd 服务
（`Before=display-manager.service`，即在 sddm 之前完成；`WantedBy=graphical.target`）：

+ 开机后最多等 10 秒（每 0.25 秒检查一次）触摸板输入设备是否注册；
+ 仍未注册且 `i2c_designware.0` / `i2c-0/i2c-MSFT0002:00` 拓扑存在时，
  向 `/sys/bus/platform/drivers/i2c_designware/unbind` 与 `bind` 各写一次
  `i2c_designware.0`（只重绑该控制器，不卸载任何共享模块）；
+ 再等最多 5 秒确认 `MSFT0002:00 06CB:CEFE Touchpad` 出现在
  `/sys/class/input/event*/device/name` 且设备解析到该控制器 sysfs 路径下
  （完整文本匹配 + 路径约束，不会误认 Mouse 子设备或其他触摸板）；
+ 已注册、拓扑缺失、写入失败均安全退出（退出码 0 表示无需/无法操作，
  1 表示重绑后仍失败）；不循环重试，不加 timer/udev 规则，不修改引导
  参数或 BIOS。

安装与验证见 [modules/touchpad-boot-recovery/README.md](../../modules/touchpad-boot-recovery/README.md)。

## 边界与回滚

+ 自恢复是持久化的故障应对，**不是内核根因修复**；若某次重绑失败，保留日志
  停止，下一步是独立的内核/固件诊断，而不是 `irqpoll` 全局参数或无限重试。
+ 注册成功但用户仍报告失灵时，不能称为恢复成功：转为运行时输入诊断
  （udev/libinput/合成器层），不添加循环重绑。
+ 回滚：`modules/touchpad-boot-recovery/uninstall.sh`（停用服务并删除两个文件，
  不解绑触摸板）。若安装前备份过旧文件，恢复备份而非直接删除。
+ 配置/当前会话验证不等于真实下一次启动验证：需要用户自主重启后确认
  `journalctl -b _COMM=touchpad-boot-recovery` 与实际操作，不自动 reboot。
