# 采集与快照维护

[English](../en/capture.md)

每当纳管配置、软件包、工具链或已启用服务发生变化时，以桌面用户身份执行：

```bash
./scripts/capture.sh
./scripts/audit.sh
```

`capture.sh` 按 `manifests/` 中的白名单重建快照，导出 dconf，并记录显式安装的 Pacman/AUR 软件包、Rust 与 Bun 工具、已启用服务、系统信息和硬件参考。公开快照生成前会移除 Git 邮箱、MPV 播放历史和 MPV 缓存。

缺失的可选路径会显示警告；受保护的系统文件需要 `sudo`。采集后应人工检查 `configs/`、`packages/` 和 `state/`，并且只有审计通过后才可发布。

不要手工修改自动生成的软件清单或状态文件。新增纳管项时应修改对应 manifest，重新采集并检查结果。
