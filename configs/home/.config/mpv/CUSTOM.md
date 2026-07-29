# mpv 配置架构手册

> 所有文件位于 `~/.config/mpv/` (链接自 `/etc/nixos/modules/home/config/mpv-config/`)
> 修改后重启 mpv 即生效

---

## 架构总览

```
~/.config/mpv/
├── mpv.conf              # 播放器核心参数 (视频/音频/字幕/常规)
├── input.conf            # 快捷键 & uosc 右键菜单
├── profiles.conf         # 条件配置 (自动触发)
├── fonts.conf            # 字体路径
├── CUSTOM.md             # ← 本手册
├── memo-history.log      # 播放历史数据
├── cache/                # 缩略图/续播缓存
├── fonts/                # uosc 图标字体
├── scripts/              # Lua 脚本
│   ├── uosc/             #   现代 UI (菜单/控制栏/进度条)
│   ├── autoload.lua      #   自动加载同目录文件到播放列表
│   ├── memo.lua          #   播放历史记录
│   ├── thumbfast.lua     #   进度条缩略图预览
│   ├── evafast.lua       #   右键按住临时快进
│   ├── autodeint.lua     #   自动反交错
│   ├── webtorrent 相关    #   磁力链接 / 种子播放
│   └── inputevent.lua    #   命名输入事件
└── script-opts/          # 脚本配置
    ├── uosc.conf         #   UI 参数
    ├── memo.conf         #   播放历史参数
    ├── evafast.conf      #   快进参数
    ├── thumbfast.conf    #   缩略图参数
    └── webtorrent.conf   #   BT 下载参数
```

---

## 1. mpv.conf — 播放器核心

### 视频

| 参数 | 值 | 说明 |
|------|---|------|
| `vo` | gpu-next | 现代渲染后端 |
| `gpu-api` | auto | 自动 Vulkan / OpenGL |
| `hwdec` | auto | 硬件解码 (vaapi/nvdec) |
| `profile` | high-quality | 高质量渲染预设 |
| `video-sync` | display-resample | 视频帧率同步显示器刷新率 |
| `interpolation` | yes | 插帧 (24fps → 60/120/144Hz) |
| `tscale` | oversample | 插帧算法 |
| `deband` | no | 去色带 (默认关, Anime 目录自动开) |
| `deband-iterations` | 1 | 去色带迭代次数 |
| `deband-threshold` | 48 | 色带检测阈值 |
| `deband-range` | 16 | 色带模糊范围 |
| `deband-grain` | 32 | 去色带后加噪粒 |
| `temporal-dither` | yes | 时间抖动 (减少色阶) |

### 音频

| 参数 | 值 | 说明 |
|------|---|------|
| `alang` | ja,... | 音轨语言优先级: 日语 > 中文 > 英语 |
| `volume-max` | 150 | 最大音量 (%) |
| `audio-channels` | auto | 自动检测声道数 |
| `audio-file-auto` | fuzzy | 外挂音轨模糊匹配 |
| `audio-pitch-correction` | yes | 变速时音调修正 |
| `audio-normalize-downmix` | yes | 响度均衡 + 下混立体声 |

### 字幕

| 参数 | 值 | 说明 |
|------|---|------|
| `slang` | zh-Hans,zh-CN,... | 字幕语言优先级: 中文简体 > 英语 |
| `sub-auto` | fuzzy | 字幕匹配模式: 根据数字标识模糊匹配 |
| `sub-codepage` | auto | 字幕编码自动检测 |
| `sub-fix-timing` | yes | 自动修正字幕时间轴漂移 |
| `sub-ass-override` | yes | 允许 ASS 样式覆写 |
| `blend-subtitles` | yes | 字幕边缘抗锯齿混合 |
| `sub-file-paths` | sub;subs;subtitles | 字幕搜索子目录 |
| `demuxer-mkv-subtitle-preroll` | yes | MKV 内挂字幕预加载 |

### 常规

| 参数 | 值 | 说明 |
|------|---|------|
| `osc` | no | 关闭原生 OSC (由 uosc 接管) |
| `idle` | yes | 无文件时保持窗口 |
| `fullscreen` | no | 启动不全屏 |
| `keep-open` | yes | 播放结束后保持窗口 |
| `save-position-on-quit` | yes | Q 键退出时记住位置 |
| `cursor-autohide` | 1000 | 光标自动隐藏延迟 (ms) |
| `input-terminal` | no | 不从终端读取键盘输入 |

### 串流与缓存

| 参数 | 值 | 说明 |
|------|---|------|
| `ytdl` | yes | 支持 URL 直链 (依赖 yt-dlp) |
| `ytdl-format` | bestvideo[height<=?2160]+bestaudio | 最高 4K |
| `cache` | yes | 启用缓存 |
| `demuxer-max-bytes` | 512MiB | 最大内存缓存 |
| `demuxer-max-back-bytes` | 128MiB | 回看缓存 |
| `demuxer-readahead-secs` | 30 | 预读秒数 |

### 截图

| 参数 | 值 | 说明 |
|------|---|------|
| `screenshot-directory` | ~/Pictures/mpv | 保存目录 |
| `screenshot-format` | png | 格式 |
| `screenshot-high-bit-depth` | yes | 高色深 |
| `screenshot-template` | %F-%P | 文件名模板 |

---

## 2. profiles.conf — 条件配置

条件配置在满足触发条件时**自动生效**，无需手动开关。

| Profile | 触发条件 | 应用选项 | 效果 |
|---------|---------|---------|------|
| `Deband-Medium` | 手动 (右键菜单) | 去色带 2 次迭代 | 中强度去色带 |
| `Deband-Strong` | 手动 (右键菜单) | 去色带 3 次迭代 | 高强度去色带 |
| `Downmix-Audio-5.1` | 5.1 声道 | lavfi 声道映射 | 立体声下混 |
| `Downmix-Audio-7.1` | 7.1 声道 | lavfi 声道映射 | 立体声下混 |
| `audio-filter` | 声道数 > 2 | dynaudnorm 滤镜 | 动态响度均衡 |
| `Anime` | 路径含 `Anime` | deband=yes, sub-scale=0.75 | 动画优化 |
| `Webtorrent-Entries` | webtorrent 播放 | memo-enabled=no | 隐藏种子历史 |
| `Timeline-Fullscreen` | 全屏 | uosc timeline_size=56 | 全屏进度条加厚 |
| `Timeline-Windowed` | 窗口模式 | uosc timeline_size=40 | 窗口进度条收窄 |

### Anime 配置详解

触发条件: `路径中任意一级文件夹名为 Anime`

自动开启:
- `deband=yes` — 去色带 (动画中常见色阶条纹)
- `sub-scale=0.75` — 字幕缩小到 75% (动画字幕通常较大)

---

## 3. input.conf — 快捷键 & 菜单

### 鼠标

| 按键 | 功能 |
|------|------|
| 左键单击 | 暂停 / 播放 |
| 右键按住 | 临时快进 (evafast, 松开恢复) |
| 中键单击 | 弹出 uosc 模糊菜单 |
| 滚轮 | 音量 ±2 |
| `Shift+↑↓` | 音量 ±5 |

### 播放控制

| 按键 | 功能 |
|------|------|
| `Space` | 暂停 / 播放 |
| `→` `←` | 快进/后退 5 秒 |
| `↑` `↓` | 快进/后退 60 秒 |
| `Shift+→` `Shift+←` | 精准快进/后退 30 秒 |
| `PgUp` `PgDn` | 上/下一集 (播放列表) |
| `Enter` | 全屏切换 |
| `Tab` | 显示/隐藏 UI |
| `q` | 退出 |
| `Q` | 退出并记住播放进度 |

### 字幕

| 按键 | 说明 |
|------|------|
| `y` | 加载外部字幕文件 |
| `Y` | 选择字幕轨道 |
| `Alt+J` | 字幕放大 |
| `Alt+K` | 字幕缩小 |
| `z` | 字幕提前 0.1s |
| `Z` | 字幕延后 0.1s |
| `Alt+B` | 在线下载字幕 |

### 音频

| 按键 | 说明 |
|------|------|
| `a` | 响度均衡开关 |
| `F1` | 对话增强 (loudnorm) |
| `F2` | 动态音量均衡 (dynaudnorm) |

### 视频

| 按键 | 说明 |
|------|------|
| `d` | 去色带开关 |
| `g` | 视频插帧开关 |
| `c` | 清除所有着色器 |
| `Ctrl+D` | 反交错的隔行扫描 |

### 文件 / 截图 / 工具

| 按键 | 说明 |
|------|------|
| `h` | 播放历史 |
| `b` / `Ctrl+O` | 打开文件 |
| `Ctrl+P` | 播放列表 |
| `Alt+C` | 章节列表 |
| `s` | 截图 (含字幕) |
| `S` | 截图 (纯视频) |
| `Ctrl+S` | 截图 (含窗口) |
| `p` | WebTorrent 信息 |
| `/` | 控制台 |

### 右键菜单结构

```
文件            视频            音频            字幕            工具          使用手册
├ 播放历史     ├ 滤镜         ├ 对话增强     ├ 加载字幕     ├ 控制台     ├ 播放控制
├ 播放列表     ├ 着色器       ├ 动态音量均衡 ├ 选择字幕     └ 设置       ├ 字幕
├ 章节         ├ 插帧         ├ 响度均衡开关 ├ 字体调大                 ├ 音频
├ 打开文件     └ 选择视频轨道  ├ 清除滤镜     ├ 字体调小                 ├ 视频
└ 文件管理器                  ├ 均衡器       ├ 字幕提前                 ├ 截图与导航
                              ├ 音量均衡器   └ 字幕延后                 ├ 自动功能
                              ├ 压缩器                                   ├ 条件配置
                              └ 选择音频轨道                              └ 常见问题
```

---

## 4. uosc.conf — UI 界面

### 进度条

| 参数 | 值 | 默认 | 说明 |
|------|---|------|------|
| `timeline_style` | line | line | 线型 (bar = 条型) |
| `timeline_size` | 56 | 40 | 展开时厚度 (px) |
| `timeline_persistency` | paused | — | 暂停时始终展开 |
| `timeline_step` | 5 | 5 | 滚轮快进步长 (秒) |
| `progress` | windowed | windowed | 窗口模式显示细线 |
| `progress_size` | 2 | 2 | 细线厚度 (px) |

### 控制栏

| 参数 | 值 | 说明 |
|------|---|------|
| `controls` | (见文件) | 按钮布局: 菜单 → 上一集/下一集 → 打开 → 列表 → 字幕... |
| `controls_size` | 42 | 35 | 按钮大小 (px) |
| `controls_margin` | 8 | 距底部边缘间距 |
| `autoload` | yes | 播完自动下一集 |
| `shuffle` | no | 随机播放 |

### 外观

| 参数 | 值 | 默认 | 说明 |
|------|---|------|------|
| `font_scale` | 1.18 | 1 | 字体缩放 |
| `font_bold` | yes | no | 全局粗体 |
| `border_radius` | 2 | 3 | 按钮圆角 |
| `curtain` (opacity) | 0 | 0.8 | 底部暗色遮罩 (0=关闭) |
| `menu` (opacity) | 0.84 | 1 | 菜单不透明度 |
| `timeline` (opacity) | 0.8 | 0.9 | 进度条不透明度 |
| `title` (opacity) | 0 | 1 | 顶部栏不透明度 |

### 章节范围

| 参数 | 值 | 说明 |
|------|---|------|
| `chapter_ranges` | openings/endings | 动画 OP/ED 在进度条上标记 |
| `chapter_range_patterns` | オープニング/エンディング | 匹配日语章节名 |

---

## 5. script-opts/ — 脚本配置

### memo.conf — 播放历史

| 参数 | 值 | 说明 |
|------|---|------|
| `history_path` | `~~/memo-history.log` | 历史记录文件 (空=仅内存) |
| `entries` | 10 | 显示条目数 |
| `pagination` | yes | 分页 |
| `hide_duplicates` | yes | 去重 |
| `hide_deleted` | yes | 隐藏已删除文件 |
| `use_titles` | yes | 显示标题而非文件名 |
| `truncate_titles` | 60 | 标题截断长度 |

### evafast.conf — 右键快进

| 参数 | 值 | 说明 |
|------|---|------|
| `seek_distance` | 5 | 按下的跳转距离 (秒) |
| `speed_increase` | 0.1 | 加速步长 |
| `speed_cap` | 2 | 加速上限 (倍速) |
| `subs_speed_cap` | 1.8 | 有字幕时的加速上限 |

### thumbfast.conf — 缩略图

| 参数 | 值 | 说明 |
|------|---|------|
| `max_height` | 200 | 缩略图最大高度 |
| `max_width` | 200 | 缩略图最大宽度 |
| `spawn_first` | yes | 加载时预生成 |
| `hwdec` | yes | 硬件解码缩略图 |
| `network` | yes | 网络视频也生成 |

### webtorrent.conf — BT 下载

| 参数 | 值 | 说明 |
|------|---|------|
| `path` | ~/ | 下载目录 |
| `maxConns` | 100 | 最大连接数 |
| `utp` | yes | μTP 协议 |
| `dht` | yes | DHT 网络 |
| `lsd` | yes | 本地发现 |

---

## 常见问题

**Q: 改配置后没生效?**
A: 重启 mpv。如果还不行，检查 `~/.config/mpv/` 下是否还是 Nix Store 符号链接 — 手动 `cp` 覆盖一下即可。

**Q: 字幕没自动加载?**
A: 确保字幕文件与视频同目录，文件名包含相同数字 (如 `01`)。也可按 `y` 手动选择。

**Q: 进度条太细/太粗?**
A: 改 `uosc.conf` 中 `timeline_size`(展开) 和 `progress_size`(细线)。

**Q: 播放历史为空?**
A: 检查 `memo.conf` 中 `history_path` 是否设为 `~~/memo-history.log`。
