# 恢复流程

[English](../en/recovery.md)

在没有本仓库的机器上，先克隆仓库：

```bash
git clone https://github.com/Eurekaimer/cachyos-config.git
cd cachyos-config
```

以目标桌面用户身份运行恢复命令，不要用 root。先审计并预览所有改动：

```bash
./scripts/audit.sh
./scripts/restore-all.sh --dry-run
./scripts/restore-all.sh
sudo reboot
```

恢复对任何机器都安全：它不会读写磁盘 UUID、`/etc/machine-id`、`/etc/fstab`
或 `/etc/hostname`；目标用户名不同也没关系，采集的 home 绝对路径会在恢复时
改写为当前用户。

组合恢复会依次安装软件包与工具链、恢复可移植系统配置、恢复用户配置与 dconf，
最后启用记录在案的服务。所有会改动文件的脚本都支持 `--dry-run`；每一层也可以
单独执行：

```bash
./scripts/install-packages.sh
./scripts/restore-system.sh
./scripts/restore-user.sh
./scripts/restore-services.sh
```

内置的 Sioyek 离线词典会下载 ECDICT 数据，因此保留为显式的恢复后步骤。AUR
软件层装好 Sioyek 后执行：

```bash
./scripts/install-sioyek-ecdict.sh
```

重启 Sioyek，选中英文单词并按 `s` 即可查词。生成的文件与卸载方法见
[插件说明](sioyek-ecdict.md)。

如果暂时无法访问 AUR，可以先用 `install-packages.sh --skip-aur` 装完仓库软件包，
之后再单独重试该层。

不要在全新的磁盘或主机上使用 `--with-hardware`。该选项会覆盖 `/etc/fstab`
和 `/etc/hostname`；考虑使用前，先用 `lsblk -f` 和 `findmnt --real` 与
`state/hardware/` 比对，确认磁盘布局一致。

恢复完成后，再运行 `./scripts/audit.sh`、`niri validate`，核对必备命令与已启用
服务，并按各组件文档测试桌面快捷键和默认应用。
