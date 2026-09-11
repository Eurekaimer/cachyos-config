# bili-live-hime：B 站直播姬替代启动器

来源：[Rsplwe/bili-live-hime](https://github.com/Rsplwe/bili-live-hime)（MIT）。

官方直播姬的轻量化跨平台替代工具，用于获取 B 站 RTMP/SRT 推流地址与流密钥、
修改直播间标题与分区、查看和发送弹幕、管理房管与屏蔽词。推流本身仍由 OBS 完成：
把本工具给出的地址和密钥填入 OBS 即可开播。

## 安装

```bash
./scripts/install-bili-live-hime.sh
```

安装器按需补齐，不会重复做已有的事：

1. 项目目录（默认 `~/Projects/bili-live-hime`，可用 `BILI_LIVE_HIME_DIR` 覆盖）
   不存在时从上游 `git clone --depth 1`；
2. 缺少 `node_modules` 时执行 `npm install`；
3. 缺少发布版产物时执行 `npm run tauri build -- --no-bundle`（首次约需数分钟）；
4. 把启动器安装到 `~/.local/bin/bili-live-hime`。

安装后直接运行：

```bash
bili-live-hime
```

Windows/macOS 或不想构建时，可直接使用上游
[Release](https://github.com/Rsplwe/bili-live-hime/releases/latest) 的预编译版本。

## 运行方式

| 操作 | 命令 |
| --- | --- |
| 启动（用已有产物） | `bili-live-hime` |
| 重新构建后启动 | `bili-live-hime --rebuild` |
| 指定项目目录 | `BILI_LIVE_HIME_DIR=/path/to/project bili-live-hime` |

启动器优先使用 `src-tauri/target/release/bili-live-hime`；产物缺失时自动构建
一次。若 `src/`、`src-tauri/src/` 或 `package.json` 比产物新，会提示用
`--rebuild` 重建，但不会擅自重编译。

## 依赖

- Node.js 20+（`npm`，打包在 `pacman-explicit.txt`）；
- Rust 工具链（`rustup`）；
- Tauri/WebKitGTK 原生依赖：`webkit2gtk-4.1`、`libsoup3`、`gtk3`、`librsvg`。

## 凭据边界

登录态与推流密钥保存在 `~/.config/com.rsplwe.bili-live-hime/app-config.json`
（`SESSDATA`、`bili_jct` 等 Cookie 与 stream key），属于公开仓库明确排除的
Cookie/密钥类别：该路径不在 `manifests/home-paths.txt` 中，`audit.sh` 也会在它
意外进入 `configs/` 时拒绝发布。换机器后需要重新扫码登录。

## 卸载

```bash
modules/bili-live-hime/uninstall.sh
```

只移除 `~/.local/bin/bili-live-hime`；项目目录与构建产物保留，可手动删除。
