# KOReader 阅读器

[English](../en/koreader.md)

KOReader 通过 AUR 的 `koreader-bin` 安装，在 Niri 桌面上以原生应用运行。本文
覆盖安装、桌面启动崩溃修复、PDF 打开崩溃修复、快照收录边界，以及桌面版实用
的快捷键。

## 安装

```bash
paru -S koreader-bin
```

`paru` 默认需要交互式终端来确认 sudo。如果是在非交互会话里驱动安装，请配合
askpass 助手和 paru 的 sudo 参数：

```bash
SUDO_ASKPASS=/path/to/askpass paru -S --sudoflags=-A koreader-bin
```

## 启动崩溃：根因与修复

KOReader 在加载设备模块前会探测设备类型。它的检测逻辑把任何存在的
`/usr/bin/hwdetect` 都当作 Kobo 固件标记，但 Arch extra 仓库恰好提供了同名
二进制，于是本机误命中、加载 Kobo 设备模块，桌面启动随即崩溃。

本仓库把修复做成 `scripts/patch-koreader-desktop.sh`——手工修复落在
`/usr/lib`（属于软件包文件），`koreader-bin` 升级后会自动还原坏掉的探测行、
崩溃复发。每次升级后重跑该脚本：

```bash
./scripts/patch-koreader-desktop.sh             # 应用修复；会提示输入 sudo
./scripts/patch-koreader-desktop.sh --dry-run   # 只预览不修改
```

脚本幂等地保留按日期的备份——首次运行把出厂文件复制为
`/usr/lib/koreader/frontend/device.lua.bak-YYYYMMDD`——然后删掉 Kobo 探测里的
误导项 `or lfs.attributes("/usr/bin/hwdetect")`。已打补丁后再次运行会提示
「already patched」并跳过。若未来版本改了探测代码形态，脚本会明确报错而不猜测。

用以下命令确认软件包文件是否被改动：

```bash
pacman -Qkk koreader-bin   # 一旦打过补丁会列出 device.lua 与 readerfooter.lua 被修改
```

## PDF 打开崩溃与滚动默认值

`defaults.custom.lua` 里的 `DCREREADER_VIEW_MODE = "scroll"` 同样会泄漏到
PDF：`ReaderView.view_mode` 对所有文档都读全局默认，而 `ReaderPaging` 不会
重置它。在默认 footer 设置（`toc_markers` 开启）下，`ReaderFooter` 因此进入
scroll 分支并调用 `document:getPosFromXPointer()`——这是 CRE 引擎
（EPUB/FB2/TXT）独有的 API——于是每个 PDF 打开即崩：

```
readerfooter.lua:2203: attempt to call method 'getPosFromXPointer' (a nil value)
```

`scripts/patch-koreader-desktop.sh` 同时修复此问题：在
`/usr/lib/koreader/frontend/apps/reader/modules/readerfooter.lua` 加一行能力
守卫（幂等，日期备份 `readerfooter.lua.bak-YYYYMMDD`），非 CRE 文档改用基于
页数的进度。无论滚动默认值如何，PDF 始终保持翻页模式。此 bug 已整理为上游
issue/PR 材料（见 `~/Projects/koreader-issue.md`）；上游合并该守卫后即可移除
本补丁。

## 快照边界

`configs/home/.config/koreader/` 镜像 `~/.config/koreader/` 下的配置：
`settings.reader.lua`、`defaults.custom.lua` 以及 `settings/` 里的 Lua 文件
（hotkeys、gestures、电池统计、书签快捷键、云存储、profiles、wallabag）。
两类运行态永不公开：

- 阅读历史与缓存——`history.lua`（最近文件列表）、`cache/`、`data/`、
  `clipboard/`、`help/`、`ota/`、`screenshots/`、以及 `settings/*.sqlite3`
  （书目缓存、阅读统计、生词本）；
- `settings.reader.lua` 中的最近文件键（`lastfile`、`lastdir`）会被剔除，
  与 `history.lua` 的文件名泄露理由一致。

`capture.sh` 拷贝后会对上述全部做剪枝；`audit.sh` 会拒绝这些路径在快照中
重新出现。`plugins/` 发布本快照的 `scrollstep.koplugin`（阅读器 30% 滚动、
历史记录与目录翻页，以及历史记录/文件浏览器返回键）。`patches/` 发布
`1-lxgw-fonts.lua`，将已安装的霞鹜文楷用于 KOReader 界面角色、可重排文档
默认与回退字体、页眉、页脚和等宽文本；找不到字体文件时补丁直接退出，
不改变设置。`scripts/`、`styletweaks/` 保留空目录（KOReader 期待这些配置点
存在）但不发布任何文件。

用 `./scripts/restore-user.sh` 恢复。

## 阅读模式

KOReader 有 `page`（翻页）与 `continuous`（连续滚动）两种模式。本快照通过
`defaults.custom.lua` 把所有版式可重排文档（EPUB / FB2 / TXT）预置为连续
滚动：

```lua
return {
    DCREREADER_VIEW_MODE = "scroll",
}
```

`view_mode` 本身是按书记录的阅读设置：以前手动切过模式的书记住自己的模式，
从未动过的书默认以连续滚动打开。想在单本书里改回翻页：齿轮⚙ 菜单 → 阅读
模式 → page。

PDF 不受此默认值影响：它们始终以翻页模式打开。该默认值同样会泄漏到 PDF，
上文「PDF 打开崩溃与滚动默认值」里的 footer 守卫正是为此——PDF 保持翻页，
进度条正常工作。

## 快捷键速查

下表是带键盘设备上 KOReader 的出厂默认绑定，另加本快照的覆盖（标注
「本方案」）：`settings/hotkeys.lua` 的按键绑定，以及 `scrollstep.koplugin`：
`Ctrl+J`/`Ctrl+K` 在阅读器滚动 30%，在历史记录与目录内翻页；`f` 从历史记录
直接回文件浏览器。Vim/Sioyek 风格：`j`/`k` 小幅滚动、`h` 历史记录、`f`
文件浏览器、`m` 上方主菜单、`p` 富信息状态栏开关、`q` 退出；章节跳转用
`t`（目录）。

| 键 | 动作 |
| --- | --- |
| `j`（本方案） | 向下滚动（小幅） |
| `k`（本方案） | 向上滚动（小幅） |
| `Ctrl+J`（本方案） | 向下滚动约 30% 屏幕（滚动模式）；翻页模式/PDF 下翻一页；历史记录或目录下一页 |
| `Ctrl+K`（本方案） | 向上滚动约 30% 屏幕（滚动模式）；翻页模式/PDF 上翻一页；历史记录或目录上一页 |
| `h`（本方案） | 历史记录——阅读器与文件管理器均可用 |
| `f`（本方案） | 文件浏览器（从阅读器或已打开的历史记录关闭当前书并返回） |
| `m`（本方案） | 打开阅读器上方主菜单 |
| `p`（本方案） | 显示/隐藏完整状态栏 |
| `q`（本方案） | 退出 KOReader |
| `t` | 目录 |
| `b` | 书签 |
| Enter | 打开/确认当前焦点项目 |
| Esc | 返回/关闭菜单 |
| Shift+Back | 打开上一个文档 |
| Space | 翻页模式（PDF）下一页；滚动模式下无绑定 |
| ↑ / ↓ | 小幅滚动，与 `j`/`k` 相同；翻页模式下翻页 |
| ← / → | 滚动模式下滚一屏；翻页模式下上/下一页 |
| PgUp / PgDn | 滚动模式下滚一屏；翻页模式下上/下一页 |
| 1-0 | 跳到全书 0/11/22/33/44/55/66/77/88/100% 处 |
| F6 / F7 | 上一视图/下一视图 |
| Home | 回到文件管理主页（书库） |
| 齿轮菜单 | 阅读模式切换（page / continuous 滚动） |

### 上方主菜单键盘流

按 `m` 打开上方主菜单后，`j` / `k` 向下/向上移动焦点，`h` 返回父菜单
（在根部关闭菜单），`l` / Enter 激活当前项目。原生方向键、Tab、Enter 和
Esc 导航仍然可用。

### 富信息状态栏

本快照启用“同时显示所有选中项目”：当前/总页码、百分比、时钟、章节剩余
页数、章节/全书剩余时间以及进度条都放在同一条 footer 中。`p` 在完整
状态栏和隐藏之间切换，不再逐项循环模式。时钟每分钟自动刷新，当前文档
无法提供的项目会自动省略。

### 桌面版无法绑定的键

- `Shift+J` / `Shift+K` 不存在：快捷键插件只把 Shift 与光标/翻页/导航键
  配对；本桌面版字母修饰键是 `Ctrl`，所以 `Ctrl+J` / `Ctrl+K` 承载 30% 滚动。
- `Tab` 在 KOReader 里不可绑定；「上一个文档」已有 `Shift+Back` 覆盖。
- `Space` 无需绑定：翻页模式（PDF）即下一页。


### 文件管理器（首页）

Vim 风格，来自本快照的 `settings/hotkeys.lua`：

| 键 | 动作 |
| --- | --- |
| `h`（本方案） | 历史记录 |
| `Ctrl+J` / `Ctrl+K`（本方案） | 文件列表下一页/上一页 |

文件管理器保留原生条目快捷字母，但插件将 `H` 留给历史记录。光标移动仍使用
原生 ↑ / ↓；`Ctrl+J` / `Ctrl+K` 对文件列表翻页。

原生按键，无需绑定：

| 键 | 动作 |
| --- | --- |
| PgDn / PgUp | 文件列表下一页/上一页 |
| Shift+PgDn / Shift+PgUp | 最后一页/第一页 |
| Shift+↓ | 跳页对话框 |
| Enter | 打开所选文件/目录 |
| Esc | 返回上级目录/关闭 |
## 切书

- `h` 从阅读器或文件管理器打开历史记录（最近书库）。KOReader 启动仍落在
  文件浏览器（`lastdir`），没有原生的「启动即历史」选项，因此 `h` 是一键
  最近书架。
- 历史记录内保留每本书的字母快捷键，但将 `F` 留给导航；`Ctrl+J` /
  `Ctrl+K` 翻最近文件列表，`f` 关闭历史记录及当前书并回到文件浏览器。
- 文件管理器菜单 →「打开上一个文档」（Open last document）续读最近一本
  书。
- `Shift+Back` 直接打开上次读的文档。
- `Home` 回到文件管理主页（书架），在此选下一本。
- 想要「文件夹内上一本/下一本」，可在键盘快捷键菜单里给
  `open_next_document_in_folder` / `open_previous_document_in_folder`
  绑定按键（见下方「改键」）。

## 书架

桌面版没有独立的「书架」页面：`Home` 打开的文件管理主页就是书库/书架，
`h`（历史记录）即最近书架。收藏（Favorites）集合在 KOReader 内的收藏屏
管理。

## 改键方法

齿轮⚙ 菜单 → 工具 → 更多工具 → 键盘快捷键（Keyboard shortcuts）→
Alphabet keys (single key)。可重绑任意单字母，例如把 `j`/`k` 指向
上一页/下一页（Page-turn buttons）而非滚动，或把 `Ctrl+J`/`Ctrl+K` 改回
快速翻页。注意 `type_to_search` 开启时，单字母会触发全文搜索而不会执行
绑定；需在同一快捷键菜单里关闭它（带键盘的设备上会显示该开关）。

改完快捷键要重启 KOReader——KOReader 在干净退出时才刷新设置，完整绑定在下次
启动时生效。
