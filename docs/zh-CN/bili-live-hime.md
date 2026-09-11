# B 站直播：bili-live-hime + OBS

[English](../en/bili-live-hime.md)

开播链路只做两件事：用轻量客户端 `bili-live-hime` 从 B 站取推流地址与流密钥，
把这对凭据填进 OBS 推流。官方直播姬不是必需组件。

```mermaid
flowchart LR
    A[扫码登录 bili-live-hime] --> B[获取 RTMP/SRT 地址与流密钥]
    B --> C[填入 OBS 推流设置]
    C --> D[B 站直播间]
```

## bili-live-hime（可选安装）

上游：[Rsplwe/bili-live-hime](https://github.com/Rsplwe/bili-live-hime)（MIT）。
提供获取推流地址/流密钥、修改直播间标题与分区、弹幕收发、房管与屏蔽词管理，
以及在线观众统计。

它不进通用快照恢复：项目源码与构建产物在 `$HOME` 白名单之外，且每次重建都与
本机工具链相关。用独立安装脚本：

```bash
./scripts/install-bili-live-hime.sh
./scripts/install-bili-live-hime.sh --dry-run   # 只预览
```

安装器按需补齐，不重复已有工作：项目目录缺失则从上游 `git clone --depth 1`；
缺 `node_modules` 则 `npm install`；缺发布版产物则
`npm run tauri build -- --no-bundle`（首次约需数分钟）；最后把启动器装到
`~/.local/bin/bili-live-hime`。

| 操作 | 命令 |
| --- | --- |
| 启动（复用已有产物） | `bili-live-hime` |
| 重新构建后启动 | `bili-live-hime --rebuild` |
| 换项目目录 | `BILI_LIVE_HIME_DIR=/path/to/project bili-live-hime` |

启动器优先使用 `src-tauri/target/release/bili-live-hime`；产物缺失时自动构建
一次。若 `src/`、`src-tauri/src/` 或 `package.json` 比产物新，只提示
`--rebuild`，不会擅自重编译。依赖：Node.js 20+、Rust 工具链，以及
`webkit2gtk-4.1`、`libsoup3`、`gtk3`、`librsvg`。

卸载启动器用 `modules/bili-live-hime/uninstall.sh`；项目目录与产物保留。

## OBS Studio

`obs-studio`（当前 32.2.2）显式安装在 `packages/pacman-explicit.txt`，配置进入
托管快照：

| 快照内容 | 说明 |
| --- | --- |
| `configs/home/.config/obs-studio/global.ini`、`user.ini` | 界面与通用设置 |
| `basic/scenes/` | 场景集 |
| `basic/profiles/` | 编码器与推流配置（不含 `service.json`） |
| `plugin_manager/modules.json` | 插件清单 |

`basic/profiles/*/service.json` 保存推流密钥，`scripts/capture.sh` 在发布前删除
它和它的 `.bak`；`logs/`、`profiler_data/`、`plugin_config/` 不在白名单内。
因此恢复后 OBS 保留场景与编码器设置，但推流地址与密钥需要重新填写：从
bili-live-hime 重新获取即可。

## 凭据边界

bili-live-hime 的登录态与推流信息保存在
`~/.config/com.rsplwe.bili-live-hime/app-config.json`，含 `SESSDATA`、
`bili_jct`、`DedeUserID` 等 Cookie 和 stream key。该路径不在
`manifests/home-paths.txt` 中，`scripts/audit.sh` 也把
`com.rsplwe.bili-live-hime` 列为禁止路径，意外进入 `configs/` 时会拒绝发布。
换机器后需要重新扫码登录，推流密钥由 B 站按房间重新下发。
