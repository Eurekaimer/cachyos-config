# 软件包与服务

[English](../en/packages-services.md)

以下数量取自已提交的清单（`packages/profiles/*.txt` 为安装输入，其余为
采集到的状态）。"刷新量"由 `./scripts/capture.sh` 生成；采集时间记录在
`state/system-info.txt` 的 `captured_at` 字段。

| 来源 | full | minimal | 清单 |
|---|---:|---:|---|
| 仓库软件包 | 246 | — | `packages/inventory/pacman-explicit.txt` |
| AUR/外部软件包 | 22 | — | `packages/inventory/aur-explicit.txt` |
| **档位安装输入** | **277** | **180** | `packages/profiles/full.txt`、`packages/profiles/minimal.txt` |
| Rustup 工具链 | 1 | 1 | `packages/toolchains/rustup.txt` |
| Bun 全局软件包 | 3 | 3 | `packages/toolchains/bun.txt` |
| 已启用系统服务 | 31 | 31 | `packages/services/system.txt` |
| 已启用用户服务 | 9 | 9 | `packages/services/user.txt` |

软件安装的唯一输入是 `packages/profiles/*.txt`；`packages/required-extra.txt`
另外补齐恢复工具自身依赖。`inventory/`、`services/`、`toolchains/` 是采集产物，
描述快照来源机器的状态。用 `./scripts/profile.sh diff full minimal` 比较两档，
用 `./scripts/profile.sh use minimal` 或
`./scripts/install-packages.sh --profile minimal` 选择档位。

使用 `./scripts/capture.sh` 刷新全部生成清单；`./scripts/install-packages.sh` 仅恢复软件，`./scripts/restore-services.sh` 恢复服务启用状态。不存在的服务单元会跳过，不会伪造。
