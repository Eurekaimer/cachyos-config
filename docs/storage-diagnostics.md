# 外置 SSD 传输速度诊断

## 已确认根因

当前外置盘：

- 块设备：`/dev/sda`，分区 `/dev/sda2`；
- SSD：ZHITAI TiPlus5000 1TB；
- 桥接器：Realtek RTL9210（USB ID `0bda:9210`）；
- 文件系统：内核 `ntfs3`，已使用 `prealloc`；
- 当前协商速率：**480 Mbit/s（USB 2.0 High-Speed）**；
- 当前驱动：`usb-storage`，队列深度为 1；
- 机器另有空闲的 10000 Mbit/s USB 3.x 根总线。

因此 20–40 MB/s 是 USB 2.0 + BOT 单队列 + NTFS/文件类型开销下的正常范围，不是 SSD 介质性能。RTL9210 和该 NVMe 都支持远高于此的速度，但当前端口或线缆没有建立 SuperSpeed 链路。

SMART 读取结果：健康状态通过、40°C、可用备用空间 100%、介质与数据完整性错误 0、错误日志 0。没有证据表明 SSD 损坏。

## 必须执行的物理修复

1. 等待当前复制完成，安全弹出磁盘。
2. 改接主机标记为 USB 3.x/SS/10G 的端口；优先机身 USB-C 或蓝色/青色 10 Gbit/s 端口。
3. 使用明确支持 5/10 Gbit/s 数据的线缆。仅充电或 USB 2.0 数据线会继续降级到 480 Mbit/s。
4. 重连后运行：

```bash
./scripts/diagnostics/storage-link.sh /dev/sda
lsusb -t
```

合格输出必须至少满足：

- `usb_speed: 5000 Mbit/s` 或 `10000 Mbit/s`；
- 通常为 `usb_driver: uas`；
- `lsusb -t` 中设备位于 `5000M`/`10000M` 总线，而不是 `480M`。

## 为什么没有写内核“加速配置”

端口已经在物理层协商成 480 Mbit/s，内核参数、I/O 调度器或 NTFS 挂载参数都无法把 USB 2.0 变成 USB 3.x。系统没有配置 `usb-storage` quirk；因此也不是本机主动禁用了 UAS。盲目修改调度器只会掩盖根因，不会达到 300 MB/s。

如果换到确认可用的 10 Gbit/s 端口和线缆后仍显示 480M，应分别更换线缆、端口和 RTL9210 硬盘盒，以定位哪一段缺失 SuperSpeed 数据线。
