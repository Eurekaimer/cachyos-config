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
