# 采集与快照维护

[English](../en/capture.md)

每当纳管配置、软件包、工具链或已启用服务发生变化时，以桌面用户身份执行：

```bash
./scripts/sync-status.sh          # 查看自上次同步以来的变化
./scripts/capture.sh
./scripts/audit.sh

git add -A
git commit -m "sync: refresh snapshot"
git push
```

`capture.sh` 按 `manifests/` 中的白名单重建快照，导出 dconf，并记录显式安装的 Pacman/AUR 软件包、Rust 与 Bun 工具、已启用服务、系统信息和硬件参考。`llama-cpp` 与 `ollama` 属于本机模型工具，不进入可恢复软件清单。

公开快照生成前会剔除凭据与运行态：

| 内容 | 处理 |
| --- | --- |
| Git 用户邮箱 | 移除 |
| Shell rc（`.zshrc`、`.bashrc`、`.bash_profile`）中名字含 `KEY`/`TOKEN`/`SECRET`/`PASSWORD` 的导出变量 | 值置空，变量名保留；恢复后从密码管理器补回 |
| OBS `basic/profiles/*/service.json`（推流密钥） | 删除 |
| AniRSS 下载器密码/API Key/登录密码/实例 UUID | 置空 |
| KOReader 缓存、历史、`lookup_history.lua`、`wikipedia_history.lua`、统计数据库、阅读器最近文件 | 删除 |
| MPV 播放历史与缓存、Qt 与桌面文件选择器的最近路径、gThumb 最近文件 | 移除 |
| 壁纸目录中的应用元数据 | 删除 |

缺失的可选路径会显示警告；受保护的系统文件通过 `sudo` 复制，无法使用 `sudo` 时不可读文件会显示警告并跳过。采集后应人工检查 `configs/`、`packages/` 和 `state/`，并且只有审计通过后才可发布。采集不会读写磁盘 UUID、`/etc/machine-id`、`/etc/fstab` 或 `/etc/hostname`；后两者仅由单独的 hardware 层处理。

不要手工修改自动生成的软件清单或状态文件。新增纳管项时应修改对应 manifest，重新采集并检查结果。

## 增量同步记录

对齐本机与仓库不必手动逐路径比对。每次 `capture.sh`、用户配置恢复和完整恢复都会写入一份本机记录：

```
~/.local/state/cachyos-config/sync-record.txt
```

其中保存该机器上次对齐的提交、纳管目录的内容哈希，以及 `$HOME` 路径清单的哈希。`scripts/sync-status.sh` 据此只报告变化部分：

```bash
./scripts/sync-status.sh           # 状态 + 待处理文件数
./scripts/sync-status.sh --files   # 变化的仓库内文件
./scripts/sync-status.sh --paths   # 对应的纳管 $HOME 路径
```

| 状态 | 含义 | 处理 |
| --- | --- | --- |
| `clean` | 仓库仍等于本机上次对齐的快照 | 无需操作 |
| `dirty` | 本机存在未提交的纳管改动 | 运行 `./scripts/capture.sh` 后提交 |
| `pending` | 上次同步后有新提交 | 用 `./scripts/restore-all.sh`（或定向恢复）应用 |
| `rewritten` | 记录的提交不是 HEAD 的祖先 | 重新完整审核快照 |

退出码：`0` 已对齐，`1` 有待处理工作，`2` 历史被改写。

该记录回答的是「仓库是否变化」，因此无需全量重新扫描。它本身不能证明实时 `$HOME` 在之后没有被改动；需要时再单独确认：

```bash
./scripts/sync-configs.sh --check   # $HOME 与 app 层比对（含消毒）
```

`--check` 会按 capture 的同一套消毒规则，把每条声明路径与 `configs/apps/<app>/` 比对，
因此快照有意丢弃的运行态不会误报为差异。它不修改任何文件，存在差异时退出码为 `1`。
记录属于单机状态，绝不提交——`scripts/audit.sh` 会拒绝仓库内出现 `sync-record.txt`。

## Timewarrior（timew，含 totals 扩展）

纳管 `~/.config/timewarrior/timewarrior.cfg` 和
`~/.config/timewarrior/extensions/totals.py`，保留扩展的可执行权限与上游许可证。
配置启用 summary 的区间 ID 和注释显示；`totals` 按标签汇总时长。
这两个文件已加入 home manifest，常规 `capture.sh`、`restore-user.sh`
和 `restore-all.sh` 均覆盖它们；`packages/required-extra.txt` 声明 `timew`、`python` 依赖。

只同步 Timewarrior 时，在仓库根目录以桌面用户运行：

```bash
./scripts/sync-timewarrior.sh --capture           # 本机配置 → 仓库
./scripts/audit.sh
# 检查修改后自行 git add / commit / push

# 另一台机器拉取仓库后：
sudo pacman -S --needed timew python
./scripts/sync-timewarrior.sh --restore --dry-run # 预览
./scripts/sync-timewarrior.sh --restore           # 仓库 → 本机，先备份
timew extensions
timew totals :week
timew totals :month
```

独立脚本与全量恢复默认将旧文件备份到
`~/.local/state/cachyos-config/backups/<时间戳>/home/`。
独立脚本不安装软件、不提交或推送 Git，也不刷新其他配置和软件清单。
使用标准 `~/.config/timewarrior` 路径；自定义 XDG 路径或旧式
`TIMEWARRIORDB` 布局需先迁移，脚本不会自动转换。

计时记录、标签、注释、撤销记录和锁等运行数据不进入公开仓库：
不采集 `~/.local/share/timewarrior/`、旧式 `~/.timewarrior/`
或配置目录下的 `data/`，审计会拒绝这些路径。
恢复只替换两个纳管文件，不动计时数据或其他扩展；数据迁移须单独私密备份。
同一区间有多个标签时，`totals` 会给每个标签累计该区间，底部合计可能大于实际经过时间。
