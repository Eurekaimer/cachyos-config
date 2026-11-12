# 软件包与服务

[English](../en/packages-services.md)

`packages/` 分别保存软件包安装输入和本机采集记录。

**安装输入**——由 `scripts/install-packages.sh` 读取：

| 路径 | 作用 |
| --- | --- |
| `packages/profiles/full.txt` | 工作站档：NVIDIA 独显、游戏、容器、通讯 |
| `packages/profiles/minimal.txt` | ThinkPad T480 级档：Intel 核显、无游戏/容器、中英精简 TeX |
| `packages/required-extra.txt` | 托管配置或恢复脚本自身依赖的软件 |
| `packages/core.txt` | 用户指定的核心保护软件；不会被采集覆盖 |

安装器合并选定的 profile 与 `required-extra.txt`，先解析仓库软件包，其余交给
AUR helper。profile 是恢复时的安装选择，不等于本机当前已安装软件的清单。

**采集产物**——由 `scripts/capture.sh` 写入：

| 路径 | 内容 |
| --- | --- |
| `packages/inventory/explicit.txt` | 显式安装的仓库及外部软件包，不含作为依赖安装的软件 |
| `packages/services/system.txt` | 已启用的、由已安装软件包提供的系统服务 |
| `packages/services/user.txt` | 已启用的、由已安装软件包提供的用户服务 |
| `packages/toolchains/rustup.txt` | Rust 工具链 |
| `packages/toolchains/bun.txt` | Bun 全局工具，包括 Oh My Pi agent |

软件清单依据 pacman 的显式安装标记（`pacman -Qqe`），包括通过 pacman 或 paru
安装的软件，不包含标记为依赖的软件。它是当前状态，不是历史命令记录：更改软件包
安装原因会改变清单内容。该清单不作为安装输入；服务与工具链清单也会用于恢复。

`packages/core.txt` 中的核心软件不得卸载或从完整恢复档移除，除非用户先明确
调整分级。其他软件在用户决定前均为待分级，不代表可以删除；`scripts/audit.sh`
会检查核心软件是否仍在完整恢复档中。

只统计记录的数量，或仅刷新软件清单而不采集本机配置：

```bash
wc -l packages/inventory/explicit.txt
pacman -Qqe | LC_ALL=C sort -u > packages/inventory/explicit.txt
```

用 `./scripts/profile.sh diff full minimal` 比较两档，用
`./scripts/profile.sh use minimal` 或
`./scripts/install-packages.sh --profile minimal` 选择档位。
`./scripts/install-packages.sh` 恢复软件，`./scripts/restore-services.sh` 恢复服务启用状态。
