# Noctalia

[简体中文](../zh-CN/noctalia.md)

The active shell is native `/usr/bin/noctalia`, observed as
`v5.2.1 (5.2.1-1-dirty)` on 2026-10-10, not the retired QuickShell
`noctalia-shell` UI. It provides the bar, launcher, control center, notifications,
theme integration, and session UI on Niri. This migration does not redesign the UI.

`configs/apps/noctalia/` is the authoritative snapshot source:

+ `.config/noctalia/config.toml` and `widgets.toml` — native base configuration.
+ `.local/state/noctalia/settings.toml` — saved GUI overrides, which take
  precedence over base values (including UI scale 1.25, corner-radius scale 1.35,
  and the full control-center sidebar in the captured profile).
+ `.local/share/noctalia/plugins/storage-gb/` — the local `storage_gb` plugin.

`configs/home/` is a generated copy. `restore-user.sh` deploys copies, not
symlinks; edits in the GUI do not automatically update Git. Wait for settings
to be saved, then use `./scripts/capture.sh` and `./scripts/audit.sh` before
publishing. Keep GUI overrides separate rather than flattening them into the
base config. Histories, caches, credentials, and other private state stay out.

Native commands:

```bash
noctalia msg status
noctalia msg config-reload
noctalia msg panel-toggle launcher
noctalia msg session lock
noctalia msg wallpaper-get
noctalia msg wallpaper-set ~/Pictures/Wallpapers/project_mifeng.png
```

Niri forwards `Super+Shift+L` to `noctalia msg session lock`. Do not start
`qs -c noctalia-shell` or restore `settings.json`, `colors.json`, old QML
plugins/colorschemes, or older `config.toml` from backups. Stage 6 no longer
backfills Noctalia settings. Profiles request native `noctalia`, not the old
`noctalia-shell`/`noctalia-qs` stack; existing system packages and the CachyOS
meta package are left untouched.
