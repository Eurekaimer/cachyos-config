# Noctalia Shell

[简体中文](../zh-CN/noctalia.md)

Noctalia provides the bar, launcher, control center, notifications, color scheme integration, and session UI on top of Niri. The managed snapshot is `configs/home/.config/noctalia/`:

+ `settings.json` — shell behavior and module settings.
+ `colors.json` and `colorschemes/` — visual palette.
+ `plugins.json` and `plugins/` — plugin selection and bundled plugin files.

The lock screen obtains the active desktop wallpaper directly from `WallpaperService`. The current visual profile uses `lockScreenBlur=0.2`, `lockScreenTint=0.16`, and lock-screen animations so the authentication panel stays readable without hiding the wallpaper. Niri forwards `Super+Shift+L` to the Noctalia lock IPC.

Restore it through `./scripts/restore-user.sh`; do not copy generated backups or cache directories into the manifest. If settings change while Noctalia is running, use its normal reload/restart mechanism and capture only after the saved files reflect the intended state.
