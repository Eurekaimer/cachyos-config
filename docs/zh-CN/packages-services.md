# 软件包与服务

[English](../en/packages-services.md)

`packages/` 里只有两类文件，其中一类真正参与安装。

**安装输入**——由 `scripts/install-packages.sh` 读取：

| 路径 | 作用 |
| --- | --- |
| `packages/profiles/full.txt` | 工作站档：NVIDIA 独显、游戏、容器、通讯 |
| `packages/profiles/minimal.txt` | ThinkPad T480 级档：Intel 核显、无游戏/容器、中英精简 TeX |
| `packages/required-extra.txt` | 托管配置或恢复脚本自身依赖的软件 |

`profiles/*.txt` 是安装器唯一读取的软件清单；安装器先把每个名字解析到仓库，
剩下的交给 AUR helper，所以新增软件只需加一行。不再需要的软件要从两个档位里
都删掉——安装器没有分组过滤，留在文件里的行就会被安装。

**采集产物**——由 `scripts/capture.sh` 写入，描述快照来源机器：

| 路径 | 内容 |
| --- | --- |
| `packages/inventory/pacman-explicit.txt` | 显式安装的仓库软件包 |
| `packages/inventory/aur-explicit.txt` | 显式安装的 AUR/外部软件包 |
| `packages/services/system.txt` | 已启用的、由已安装软件包提供的系统服务 |
| `packages/services/user.txt` | 已启用的、由已安装软件包提供的用户服务 |
| `packages/toolchains/rustup.txt` | Rust 工具链 |
| `packages/toolchains/bun.txt` | Bun 全局工具，包括 Oh My Pi agent |

服务快照不是安装清单：只记录由已安装软件包提供的单元，因此模块安装或手工安装
的服务不会让目标机器上的 `restore-services.sh` 报警。软件包清单是来源机器的记录，
不是安装输入——某软件从档位移除并卸载后，要等下一次采集清单才会再次一致。

用 `./scripts/profile.sh diff full minimal` 比较两档，用
`./scripts/profile.sh use minimal` 或
`./scripts/install-packages.sh --profile minimal` 选择档位。
`./scripts/install-packages.sh` 恢复软件，`./scripts/restore-services.sh` 恢复服务启用状态。
