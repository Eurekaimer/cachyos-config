# External storage diagnostics

[简体中文](../zh-CN/storage-diagnostics.md)

The recorded external SSD is a ZHITAI TiPlus5000 1 TB behind a Realtek RTL9210 bridge. The investigated slow transfer path negotiated only `480 Mbit/s` over USB 2.0 and used `usb-storage`; 20–40 MB/s was therefore a link limitation, not evidence of failed NAND. SMART data was healthy at the time of diagnosis.

The fix is physical: safely disconnect the drive, use a verified USB 3.x/10 Gbit/s port and a 5/10 Gbit/s data cable, then check:

```bash
./scripts/diagnostics/storage-link.sh /dev/sda
lsusb -t
```

A corrected link should report at least `5000 Mbit/s` and normally use `uas`. Kernel parameters, I/O schedulers, or NTFS mount tuning cannot convert a link negotiated at 480 Mbit/s into SuperSpeed. If it remains at 480 Mbit/s, isolate the cable, port, and enclosure one at a time.
