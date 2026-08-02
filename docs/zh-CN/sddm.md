# SDDM 登录管理器

[English](../en/sddm.md)

本工作站使用 **Qt6 版 Sugar Candy** 作为 SDDM 登录界面。Niri 本身基于 Rust/Smithay，并不依赖 Qt；SDDM 主题明确由 `sddm-greeter-qt6` 加载，不安装或切换到 Qt5 greeter。

## 仓库结构

+ `modules/sddm/sugar-candy/`：Sugar Candy 上游 Git 子模块。
+ `modules/sddm/qt6.patch`：将上游 `QtGraphicalEffects` 导入迁移到 `Qt5Compat.GraphicalEffects`，声明 `QtVersion=6`，并简化单用户登录布局。
+ `modules/sddm/theme.conf.user`：3840×2160 毛玻璃布局、中文文案、霞色强调色和 LXGW WenKai 字体。
+ `modules/sddm/sddm.conf`：选择 `sugar-candy-qt6`，同步 Capitaine 光标和字体。
+ `modules/sddm/wallpaper.path`：记录当前用于 SDDM 的 home 快照相对路径。
+ `scripts/sync-sddm-theme.sh`：构建、安装并同步主题和壁纸。

系统配置快照为 `configs/system/portable/etc/sddm.conf.d/10-eurekaimer-theme.conf`。主题安装到 `/usr/share/sddm/themes/sugar-candy-qt6/`；背景图片复制进主题目录，SDDM 用户不需要读取私人 home 目录。

## 同步当前 Noctalia 壁纸

Noctalia 当前壁纸记录在运行时缓存中。切换到满意的壁纸后执行：

```bash
./scripts/sync-sddm-theme.sh
```

脚本读取 `~/.cache/noctalia/wallpapers.json`，将壁纸同步进 `configs/home/`，更新 `modules/sddm/wallpaper.path`，应用 Qt6 补丁并部署 SDDM 主题。也可以显式指定图片：

```bash
./scripts/sync-sddm-theme.sh --wallpaper ~/Pictures/Wallpapers/project_mifeng.png
```

预览不会退出当前 Niri 会话：

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sugar-candy-qt6
```

不要在尚未保存工作的图形会话中运行 `sudo systemctl restart sddm`；它会结束整个 Niri 会话。配置可在下次注销或重启后自然生效。

## 新机器恢复

克隆仓库后先初始化子模块：

```bash
git submodule update --init --recursive
```

`./scripts/restore-all.sh` 在恢复软件包、系统配置和用户配置后自动运行：

```bash
./scripts/sync-sddm-theme.sh --from-snapshot
```

Qt6 图形效果由 `qt6-5compat` 提供，并通过普通 pacman 显式软件包清单恢复；不需要 Sugar Candy AUR 包或任何 Qt5 运行库。
