# 软件包与服务

[English](../en/packages-services.md)

`2026-07-29T22:31:32+08:00` 采集的快照包含：

| 来源 | 数量 | 清单 |
|---|---:|---|
| CachyOS/Arch 仓库软件包 | 220 | `packages/pacman-explicit.txt` |
| AUR/外部软件包 | 13 | `packages/aur-explicit.txt` |
| Rustup 工具链 | 1 | `packages/rustup-toolchains.txt` |
| Bun 全局软件包 | 1 | `packages/bun-global.txt` |
| 已启用系统服务 | 29 | `packages/system-services.txt` |
| 已启用用户服务 | 6 | `packages/user-services.txt` |

`packages/required-extra.txt` 保存恢复工具自身需要的依赖。安装脚本直接读取这些清单，README 中的表格仅用于说明。

使用 `./scripts/capture.sh` 刷新全部生成清单；`./scripts/install-packages.sh` 仅恢复软件，`./scripts/restore-services.sh` 恢复服务启用状态。不存在的服务单元会跳过，不会伪造。
