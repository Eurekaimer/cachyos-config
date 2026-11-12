# 采集与快照维护

[English](../en/capture.md)

每当纳管配置、软件包、工具链或已启用服务发生变化时，以桌面用户身份执行：

```bash
./scripts/capture.sh
./scripts/audit.sh

git add -A
git commit -m "sync: refresh snapshot"
git push
```

`capture.sh` 按 `manifests/` 中的白名单重建快照，导出 dconf，并记录显式安装的
Pacman/AUR 软件包、Rust 与 Bun 工具以及已启用服务。

`$HOME` 层交给 `scripts/sync-configs.sh --to-snapshot`：它把
`configs/apps/<应用>/paths` 声明的每条路径从 `$HOME` 复制到对应应用目录，按下面的
规则清洗，再重建 `manifests/home-paths.txt`。该应用目录就是唯一副本——不存在生成的
`configs/home/` 安装树，一旦它重新出现，`audit.sh` 直接失败。是否安装 `llama-cpp`
这类模型运行时属于档位决策（`packages/profiles/`），不是采集特例。

公开快照生成前会剔除凭据、运行态和陈旧备份：

| 内容 | 处理 |
| --- | --- |
| Git 用户邮箱 | 移除 |
| Shell rc（`.zshrc`、`.zshenv`、`.bashrc`、`.bash_profile`）中名字含 `KEY`/`TOKEN`/`SECRET`/`PASSWORD` 的导出变量 | 值置空，变量名保留；恢复后从密码管理器补回 |
| OBS `basic/profiles/*/service.json`（推流密钥） | 删除 |
| AniRSS 下载器密码/API Key/登录密码/实例 UUID | 置空 |
| pi `agent/auth.json`（OAuth 令牌、API 密钥）、`agent/sessions/`、`agent/npm/node_modules/` | 删除 |
| pi `agent/settings.json` 中的 `deviceId` | 移除该键 |
| KOReader 缓存、历史、`lookup_history.lua`、`wikipedia_history.lua`、统计数据库、阅读器最近文件 | 删除 |
| MPV 播放历史与缓存、Qt 与桌面文件选择器的最近路径、gThumb 最近文件 | 移除 |
| 壁纸目录中的应用元数据 | 删除 |
| 应用目录下任意位置的 `*.bak`、`*.bak-*`、`*.old` | 删除 |

缺失的可选路径会显示警告；受保护的系统文件通过 `sudo` 复制，无法使用 `sudo` 时
不可读文件会显示警告并跳过。采集后应人工检查 `configs/` 与 `packages/`，并且只有
审计通过后才可发布。采集不会读写磁盘 UUID、`/etc/machine-id`、`/etc/fstab` 或
`/etc/hostname`；`configs/system/portable/` 之外的内容都不会被恢复。

不要手工修改生成文件。`manifests/home-paths.txt`、`packages/inventory/`、
`packages/services/`、`packages/toolchains/` 都由工具生成。要纳管新路径，把它写进
所属 `configs/apps/<应用>/paths`（没有合适应用时新建目录），再运行
`scripts/sync-configs.sh --to-snapshot`，最后用 `scripts/audit.sh` 验证。

## 不采集时的核对

```bash
./scripts/sync-configs.sh --check   # $HOME 与 app 层比对（含消毒）
```

`--check` 会按 capture 的同一套消毒规则，把每条声明路径与 `configs/apps/<应用>/`
比对，因此快照有意丢弃的运行态不会误报为差异。它不修改任何文件，存在差异时退出码为 `1`。
