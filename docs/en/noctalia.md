# Noctalia Shell

[简体中文](../zh-CN/noctalia.md)

Noctalia provides the bar, launcher, control center, notifications, color scheme integration, and session UI on top of Niri. The managed snapshot is `configs/home/.config/noctalia/`:

+ `settings.json` — shell behavior and module settings.
+ `colors.json` and `colorschemes/` — visual palette.
+ `plugins.json` and `plugins/` — plugin selection and bundled plugin files.

Restore it through `./scripts/restore-user.sh`; do not copy generated backups or cache directories into the manifest. If settings change while Noctalia is running, use its normal reload/restart mechanism and capture only after the saved files reflect the intended state.
