# Configuration map

[简体中文](../zh-CN/configuration.md)

`configs/apps/<app>/` is the single copy of every managed `$HOME` path: the
directory mirrors the path the application owns, and `configs/apps/<app>/paths`
declares which paths those are. `manifests/home-paths.txt` is generated from
those declarations and never edited by hand; `scripts/audit.sh` fails when the
two disagree, when a path is declared twice, or when a generated copy
(`configs/home/`) reappears. `configs/dconf/user.ini` is a portable text export
rather than the binary dconf database.

Capture writes the app trees, restore reads them back — there is no generated
install tree in between.

## User layer

| Application | Directory | Owns, relative to `$HOME` |
| --- | --- | --- |
| AniRSS | `configs/apps/ani-rss/` | `Projects/ASS/config/{ani,config}.v2.json` |
| CachyOS Hello | `configs/apps/cachyos-hello/` | `.config/cachyos-hello.json` |
| Clash Verge | `configs/apps/clash-verge/` | `.config/autostart/Clash Verge.desktop`, `.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles/Script.js` |
| Fastfetch | `configs/apps/fastfetch/` | `.config/fastfetch/` |
| Fcitx5 | `configs/apps/fcitx5/` | `.config/fcitx5/`, `.local/bin/fcitx5-toggle-japanese` |
| Fontconfig | `configs/apps/fontconfig/` | `.config/fontconfig/` |
| Git | `configs/apps/git/` | `.gitconfig` |
| Go-musicfox | `configs/apps/go-musicfox/` | `.config/go-musicfox/` |
| GTK | `configs/apps/gtk/` | `.config/gtk-3.0/` |
| Kitty | `configs/apps/kitty/` | `.config/kitty/` |
| KOReader | `configs/apps/koreader/` | `.config/koreader/` |
| Micro | `configs/apps/micro/` | `.config/micro/settings.json`, `.config/micro/colorschemes/` |
| MIME defaults | `configs/apps/mimeapps/` | `.config/mimeapps.list` |
| MPV | `configs/apps/mpv/` | `.config/mpv/` |
| Neovim | `configs/apps/nvim/` | `.config/nvim/`, `.local/share/applications/neovim-markdown.desktop` |
| Niri | `configs/apps/niri/` | `.config/niri/`, `.local/bin/niri-{hotkeys-zh,screenshot-window,stack-column}`, `.local/share/niri/hotkeys-zh.txt` |
| Noctalia | `configs/apps/noctalia/` | `.config/noctalia/`, `.local/state/noctalia/settings.toml`, `.local/share/noctalia/plugins/storage-gb/` |
| OBS Studio | `configs/apps/obs-studio/` | `.config/obs-studio/{global.ini,user.ini,basic/scenes,basic/profiles,plugin_manager/modules.json}` |
| OMP | `configs/apps/omp/` | `.omp/agent/config.yml`, `.omp/agent/models.yml`, `.omp/agent/themes/` |
| Pi | `configs/apps/pi/` | `.pi/agent/settings.json`, `.pi/agent/models-store.json`, `.pi/agent/npm/package.json` |
| Qt | `configs/apps/qt/` | `.config/QtProject.conf` |
| Shell | `configs/apps/shell/` | `.zshrc`, `.zshenv`, `.bashrc`, `.bash_profile`, `.bash_logout` |
| Sioyek | `configs/apps/sioyek/` | `.local/bin/sioyek`, `.config/sioyek/` |
| Starship | `configs/apps/starship/` | `.config/starship.toml` |
| Thunar | `configs/apps/thunar/` | `.config/Thunar/uca.xml` |
| Wallpapers | `configs/apps/wallpapers/` | `Pictures/Wallpapers/` |
| WeChat | `configs/apps/wechat/` | `.local/share/applications/wechat.desktop` |
| Wine | `configs/apps/wine/` | `.local/share/applications/wine.desktop` |
| XDG user dirs | `configs/apps/xdg-user-dirs/` | `.config/user-dirs.dirs`, `.config/user-dirs.locale` |
| Yazi | `configs/apps/yazi/` | `.config/yazi/` |
| Zed | `configs/apps/zed/` | `.config/zed/settings.json`, `.config/zed/keymap.json`, `.config/zed/snippets/` |

The capture sanitizer (`scripts/lib/sanitize.sh`) runs on every app tree before
it is committed:

- runtime state is deleted, not versioned: mpv cache and play history, KOReader
  reading history/caches/per-book databases, wallpaper comment metadata, pi
  session transcripts and `node_modules/`;
- backups (`*.bak`, `*.bak-*`, `*.old`) are deleted, because a restore
  reproduces the live file from the pristine copy;
- credentials are blanked while the structure stays: `KEY`/`TOKEN`/`SECRET`/
  `PASSWORD` values in shell rc files, OBS `service.json` stream keys, the git
  `user.email`, ani-rss downloader password/API key/UUID, `.omp` and `.pi`
  runtime state, and `agent/auth.json`.

Restore this layer with:

```bash
./scripts/restore-user.sh --dry-run
./scripts/restore-user.sh
```

Existing paths are copied to `~/.local/state/cachyos-config/backup/home` first;
that directory is cleared on every restore, so exactly one backup generation is
kept.

## Portable system layer

`configs/system/portable/` mirrors selected `/etc` files that are safe to apply
to another reviewed CachyOS installation.

| Feature | Live location |
| --- | --- |
| Console and locale | `/etc/locale.conf`, `/etc/locale.gen`, `/etc/vconsole.conf` |
| DDC/CI | `/etc/modules-load.d/i2c-dev.conf`; runtime tool is `ddcutil` |
| Environment | `/etc/environment` |
| Initramfs | `/etc/mkinitcpio.conf` |
| Libvirt network | `/etc/libvirt/qemu/networks/default.xml` |
| Makepkg | `/etc/makepkg.conf` |
| Pacman | `/etc/pacman.conf` |
| SDDM | `/etc/sddm.conf.d/10-eurekaimer-theme.conf` |
| Snapper | `/etc/snapper/configs/root`, `/etc/conf.d/snapper` |
| UFW | `/etc/default/ufw`, `/etc/ufw/ufw.conf`, `user.rules`, `user6.rules` |
| X11 keyboard | `/etc/X11/xorg.conf.d/00-keyboard.conf` |

The console keymap is pinned to `KEYMAP=us`: `kbd` ships no Chinese console layout, so
`loadkeys cn` fails with `Unable to open file: cn` and `systemd-vconsole-setup` exits 1
(one flash of `Failed to start Virtual Console Setup` at boot). Chinese input belongs to
fcitx5 in the GUI; `XKBLAYOUT=cn` only affects X11 and must stay. The `sd-vconsole` hook
embeds `/etc/vconsole.conf` into the initramfs, so any edit must be followed by an
initramfs rebuild (`update-initramfs`), otherwise the initramfs stage keeps the old value.

Nothing outside this layer is written by recovery: no disk UUIDs,
`/etc/machine-id`, `/etc/fstab`, or `/etc/hostname`. Location-generated files
such as `/etc/pacman.d/mirrorlist` are never restored automatically.

Restore this layer with:

```bash
./scripts/restore-system.sh --dry-run
./scripts/restore-system.sh
```

The restore reloads systemd, regenerates locales, and rebuilds initramfs after
copying. Replaced files are backed up to `/var/backups/cachyos-config`, which is
cleared first so one backup generation is kept.

## Software and services

`packages/profiles/` and `packages/required-extra.txt` are **install inputs**;
`packages/inventory/`, `packages/services/` and `packages/toolchains/` are
**capture outputs** recording what the capturing machine actually had. See
[packages and services](packages-services.md).

Only `profiles/` feeds the installer. Select a profile with
`scripts/profile.sh use NAME` and inspect the difference with
`scripts/profile.sh diff full minimal`.

### Clash Verge domestic routing

The managed file
`~/.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles/Script.js`
is the global extension script. It routes Bilibili web/video/image/API domains
and `GEOSITE,cn` directly, adds a China-IP fallback if absent, and preserves
the subscription's remaining rules and overseas node selection.
It survives subscription refreshes and applies across profiles.

Capture and restore manage only this file, not the surrounding Clash directory.
Exit Clash Verge before restoring it, then reopen the application to regenerate
the effective configuration. Use Rule mode; Global mode bypasses these rules.
Subscriptions and credentials must be restored separately.

### Libvirt: no daemon at boot

`libvirtd.service` is deliberately **absent** from `packages/services/system.txt`. Boot only
enables `libvirtd{,-ro,-admin}.socket`, `virtlockd{,-admin}.socket` and
`virtlogd{,-admin}.socket` for socket activation; the daemon starts on the first real client
connection. `QEMU-win10` lives in `qemu:///session`, has no autostart
(`~/.config/libvirt/qemu/autostart/` does not exist), and is started only by hand with
`~/Downloads/QEMU-win10/manage.sh start`.

Trade-off: the `virbr0` NAT network no longer appears at boot but comes up with the daemon
on first system-level libvirt use; that domain uses `<interface type='user'>` and does not
need `virbr0`. Roll back with `sudo systemctl enable --now libvirtd.service`.

## Recorded software versions

CachyOS is rolling, so the packages move; the configuration files do not follow
automatically. The versions below are what each managed configuration was
validated against. After a version jump, re-read the upstream release notes for
the schema the config depends on (niri `.kdl` node names, Noctalia settings,
kitty keys, mpv `script-opts`, KOReader `settings.reader.lua`, Sioyek
`prefs.config`, Zed settings, Micro bindings, fcitx5 profile format) and update
both the config and this table in the same commit.

| Component | Version at capture | Config format that can break |
| --- | --- | --- |
| niri | 26.04 | `.config/niri/*.kdl` layout and action names |
| Noctalia | 5.4.0 | `.config/noctalia/` schema, `settings.toml` state keys |
| kitty | 0.49.2 | `.config/kitty/kitty.conf` options |
| mpv | 0.41.0 | `mpv.conf` options, `script-opts/uosc.conf` |
| KOReader | 2026.07.1 | `settings.reader.lua`, `defaults.lua`, plugin layout |
| Sioyek | 2.0.0 | `prefs.config` shared keys |
| Zed | 1.26.2 | `settings.json` keys, snippet JSON schema |
| Neovim | 0.12.6 | plugin APIs, LSP `vim.lsp.config` shape |
| Micro | 2.0.15 | `settings.json` keys, `bindings.json` actions |
| fcitx5 | 5.1.23 | `profile`/`config` option names |
| SDDM + Sugar Candy | 0.21.0 / module | `theme.conf`, Qt6 QML API |
| OBS Studio | 33.0.1 | `basic/profiles/`, `basic/scenes/` JSON schema |
| Thunar | 4.20.10 | custom action XML (`uca.xml`) |
| Yazi | 26.9.1 | `yazi.toml`, `keymap.toml` keys |
| Starship | 1.27.0 | `starship.toml` modules |
| Clash Verge Rev | 2.5.8 | extension script API (`main(config)`) |
| Git | 2.56.0 | `.gitconfig` section names |
| Qt | 6.12.0 | `QtProject.conf` keys |
| zsh | 5.9.2 | rc file ordering (`.zshenv` → `.zshrc`) |

## Excluded from the public repository

SSH/GPG keys, browser profiles, Clash profiles, NetworkManager connections,
`~/.omp` runtime state (agent.db, logs, install-id, sessions), cookies, login
databases, histories, logs, and caches must use a password manager or encrypted
backup instead. They are not recovery inputs for this public repository.
The portable `.omp` set is limited to `agent/config.yml`, `agent/models.yml`
(API keys referenced by environment variable, never literals), and
`agent/themes/*.json`. Any other `.omp` content is rejected by `audit.sh`.
Likewise the portable `.pi` set is `agent/settings.json`,
`agent/models-store.json` and `agent/npm/package.json`; `agent/auth.json`
(live OAuth tokens and API keys), `agent/sessions/` and `agent/npm/node_modules/`
are excluded, `deviceId` is stripped from `settings.json`, and any other `.pi`
content is rejected by `audit.sh`.
