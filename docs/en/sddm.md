# SDDM display manager

[简体中文](../zh-CN/sddm.md)

This workstation uses a **Qt6 port of Sugar Candy** for the SDDM login screen. Niri itself is written in Rust on Smithay and does not depend on Qt. The theme explicitly loads through `sddm-greeter-qt6`; it neither installs nor switches to the Qt5 greeter.

## Repository layout

+ `modules/sddm/sugar-candy/` — the upstream Sugar Candy Git submodule.
+ `modules/sddm/qt6.patch` — replaces `QtGraphicalEffects` with `Qt5Compat.GraphicalEffects`, declares `QtVersion=6`, and simplifies the single-user login layout.
+ `modules/sddm/theme.conf.user` — the 3840×2160 glass panel, Chinese labels, sunset accent, and LXGW WenKai font.
+ `modules/sddm/sddm.conf` — selects `sugar-candy-qt6` and matches the Capitaine cursor and desktop font.
+ `modules/sddm/wallpaper.path` — records the home-snapshot-relative wallpaper path.
+ `scripts/sync-sddm-theme.sh` — builds, installs, and synchronizes the theme and wallpaper.

The portable system snapshot is `configs/system/portable/etc/sddm.conf.d/10-eurekaimer-theme.conf`. The generated theme is installed under `/usr/share/sddm/themes/sugar-candy-qt6/`; its background is copied into the theme so the SDDM user never needs access to the private home directory.

## Synchronize the current Noctalia wallpaper

After selecting the desired wallpaper in Noctalia, run:

```bash
./scripts/sync-sddm-theme.sh
```

The script reads `~/.cache/noctalia/wallpapers.json`, synchronizes the image into `configs/home/`, updates `modules/sddm/wallpaper.path`, applies the Qt6 patch, and deploys the SDDM theme. An explicit image can be selected instead:

```bash
./scripts/sync-sddm-theme.sh --wallpaper ~/Pictures/Wallpapers/project_mifeng.png
```

Preview without ending the current Niri session:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sugar-candy-qt6
```

Do not run `sudo systemctl restart sddm` from an unsaved graphical session: it terminates the whole Niri session. Let the new theme take effect at the next logout or reboot.

## Restore on another machine

Initialize the submodule after cloning:

```bash
git submodule update --init --recursive
```

After packages, system configuration, and user configuration are restored, `./scripts/restore-all.sh` automatically runs:

```bash
./scripts/sync-sddm-theme.sh --from-snapshot
```

Qt6 graphical effects come from the explicitly captured `qt6-5compat` pacman package. No Sugar Candy AUR package or Qt5 runtime is required.
