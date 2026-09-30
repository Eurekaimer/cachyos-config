# Configuration map

[简体中文](../zh-CN/configuration.md)

This is the authoritative map from a feature to its live location, snapshot
location, and restore boundary. Tables are alphabetized by the first column so
a known application or manifest can be found without scanning unrelated rows.
The allowlists under `manifests/` remain the source of truth.

## User layer

Configuration is authored once, under `configs/apps/<app>/`, which mirrors the
paths that application owns relative to `$HOME`. `configs/home/` is a
**generated** install tree rebuilt from those directories by
`scripts/sync-configs.sh --to-snapshot`; `scripts/restore-user.sh` reads only
the generated tree, so `configs/home/` is never edited by hand.
`manifests/home-paths.txt` is generated from `configs/apps/*/paths` at the same
time. `configs/dconf/user.ini` is a portable text export rather than the binary
dconf database.

| Application | Directory | Owns |
| --- | --- | --- |
| AniRSS | `configs/apps/ani-rss/` | `Projects/ASS/config/{ani,config}.v2.json` |
| CachyOS Hello | `configs/apps/cachyos-hello/` | `.config/cachyos-hello.json` |
| Clash Verge | `configs/apps/clash-verge/` | autostart entry, global `Script.js` |
| Fastfetch | `configs/apps/fastfetch/` | `.config/fastfetch/` |
| Fcitx5 | `configs/apps/fcitx5/` | `.config/fcitx5/`, `fcitx5-toggle-japanese` |
| Fontconfig | `configs/apps/fontconfig/` | `.config/fontconfig/` |
| Git | `configs/apps/git/` | `.gitconfig` |
| Go-musicfox | `configs/apps/go-musicfox/` | `.config/go-musicfox/` |
| GTK | `configs/apps/gtk/` | `.config/gtk-3.0/` |
| Kitty | `configs/apps/kitty/` | `.config/kitty/` |
| KOReader | `configs/apps/koreader/` | `.config/koreader/` |
| Micro | `configs/apps/micro/` | settings and colorschemes (no `syntax/`) |
| MIME defaults | `configs/apps/mimeapps/` | `.config/mimeapps.list` |
| MPV | `configs/apps/mpv/` | `.config/mpv/` |
| Niri | `configs/apps/niri/` | `.config/niri/`, niri helpers, hotkey text |
| Noctalia | `configs/apps/noctalia/` | `.config/noctalia/` |
| Neovim | `configs/apps/nvim/` | `.config/nvim/`, Markdown desktop entry |
| OBS Studio | `configs/apps/obs-studio/` | `.config/obs-studio/` (no `service.json`) |
| OMP | `configs/apps/omp/` | `.omp/agent/config.yml` |
| Qt | `configs/apps/qt/` | `.config/QtProject.conf` |
| Shell | `configs/apps/shell/` | `.zshrc`, `.bashrc`, `.bash_profile`, `.bash_logout` |
| Sioyek | `configs/apps/sioyek/` | `.local/bin/sioyek` |
| Starship | `configs/apps/starship/` | `.config/starship.toml` |
| Thunar | `configs/apps/thunar/` | `.config/Thunar/uca.xml` |
| Timewarrior | `configs/apps/timewarrior/` | `.config/timewarrior/` config and extension |
| Wallpapers | `configs/apps/wallpapers/` | `Pictures/Wallpapers/` |
| WeChat | `configs/apps/wechat/` | `wechat.desktop` |
| XDG user dirs | `configs/apps/xdg-user-dirs/` | `.config/user-dirs.{dirs,locale}` |
| Yazi | `configs/apps/yazi/` | `.config/yazi/` |

Each application directory contains a `paths` file listing the `$HOME`-relative
paths it owns; that list is what both the capture and the restore use. See
`docs/agents/MEMORY.md` for per-application editing notes and
`docs/agents/ARCHITECTURE.md` for the data flow.

| Feature | Live location | Snapshot location |
| --- | --- | --- |
| AniRSS (anime RSS) | `ani.v2.json`, `config.v2.json` under `~/Projects/ASS/config/` | `configs/home/Projects/ASS/config/`; downloader password/API key/login password/instance UUID removed from the public snapshot |
| Autostart | Allowlisted entries under `~/.config/autostart/` | `configs/home/.config/autostart/` |
| Bash | `~/.bashrc`, `~/.bash_profile`, `~/.bash_logout` | `configs/home/` |
| CachyOS Hello | `~/.config/cachyos-hello.json` | `configs/home/.config/cachyos-hello.json` |
| Dconf | `~/.config/dconf/user` binary database | `configs/dconf/user.ini` text export |
| Docker helper | `~/.local/bin/docker-ass` | not snapshotted; install with `scripts/module.sh install docker-anirss` |
| Fastfetch | `~/.config/fastfetch/` | `configs/home/.config/fastfetch/` |
| Fcitx5 | `~/.config/fcitx5/` | `configs/home/.config/fcitx5/` |
| Fontconfig | `~/.config/fontconfig/` | `configs/home/.config/fontconfig/` |
| Git | `~/.gitconfig` | `configs/home/.gitconfig`; public snapshot removes email |
| Go-musicfox | `~/.config/go-musicfox/config.toml` | `configs/home/.config/go-musicfox/` |
| GTK | `~/.config/gtk-3.0/`, `~/.config/gtk-4.0/` | `configs/home/.config/` |
| Kitty | `~/.config/kitty/` | `configs/home/.config/kitty/` |
| Micro | `~/.config/micro/settings.json`, `~/.config/micro/colorschemes/` | `configs/home/.config/micro/` |
| MIME defaults | `~/.config/mimeapps.list` | `configs/home/.config/mimeapps.list` |
| KOReader | `~/.config/koreader/` | `configs/home/.config/koreader/` (runtime state pruned) |
| MPV | `~/.config/mpv/` | `configs/home/.config/mpv/` |
| Neovim | `~/.config/nvim/`, Neovim Markdown desktop entry | `configs/home/.config/nvim/`, `configs/home/.local/share/applications/neovim-markdown.desktop` |
| Niri | `~/.config/niri/` | `configs/home/.config/niri/` |
| Niri helpers | `~/.local/bin/niri-hotkeys-zh`, `~/.local/bin/niri-stack-column`, hotkey text | `configs/home/.local/bin/`, `configs/home/.local/share/niri/` |
| Noctalia | `~/.config/noctalia/` | `configs/home/.config/noctalia/` |
| OBS Studio | `~/.config/obs-studio/` (`global.ini`, `user.ini`, `basic/scenes/`, `basic/profiles/`, `plugin_manager/modules.json`) | `configs/home/.config/obs-studio/`; `service.json` (stream key) is deleted before publishing; logs and profiler data stay out |
| OMP (Oh My Pi frontend prefs) | `~/.omp/agent/config.yml` | `configs/home/.omp/agent/config.yml` (frontend prefs only; runtime state stays out) |
| Qt | `~/.config/QtProject.conf` | `configs/home/.config/QtProject.conf`; recent-path metadata is removed |
| Starship | `~/.config/starship.toml` | `configs/home/.config/starship.toml` |
| Thunar | `~/.config/Thunar/uca.xml` | `configs/home/.config/Thunar/uca.xml` |
| Wallpapers | `~/Pictures/Wallpapers/` | `configs/home/Pictures/Wallpapers/` |
| XDG user directories | `~/.config/user-dirs.dirs`, `~/.config/user-dirs.locale` | `configs/home/.config/` |
| Zsh | `~/.zshrc` | `configs/home/.zshrc` |

Restore this layer with:

```bash
./scripts/restore-user.sh --dry-run
./scripts/restore-user.sh
```

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

Restore this layer with:

```bash
./scripts/restore-system.sh --dry-run
./scripts/restore-system.sh
```

The restore reloads systemd, regenerates locales, and rebuilds initramfs after
copying.

## Hardware-bound layer

These files live in `configs/system/hardware/` and are excluded from default
recovery.

| Feature | Live location | Risk |
| --- | --- | --- |
| Filesystem table | `/etc/fstab` | Contains disk UUIDs, mount points, and Btrfs subvolumes |
| Hostname | `/etc/hostname` | Carries host identity |

Use `--with-hardware` only after confirming the target has the same disks,
subvolumes, mount points, and intended host identity against
`state/hardware/{lsblk,findmnt,lspci}.txt`.

## Reference-only layer

| Reference | Location | Restore behavior |
| --- | --- | --- |
| Hardware inventory | `state/hardware/` | Comparison only; never copied as configuration |
| Pacman mirror list | `configs/system/reference/etc/pacman.d/mirrorlist` | Location/time dependent; never restored automatically |

## Software and services

`packages/` splits into install inputs and capture outputs. The first column is
the actual path and is sorted alphabetically.

| Manifest | Role | Content |
| --- | --- | --- |
| `packages/profiles/full.txt` | **install input** | Current workstation profile: NVIDIA, gaming, containers, comms, heavy IDEs |
| `packages/profiles/minimal.txt` | **install input** | ThinkPad T480 class profile: Intel iGPU, no gaming/containers, CN/EN TeX |
| `packages/inventory/pacman-explicit.txt` | capture output | Explicit packages from configured repositories |
| `packages/inventory/aur-explicit.txt` | capture output | Explicit AUR or external packages |
| `packages/services/system.txt` | capture output | Enabled system services |
| `packages/services/user.txt` | capture output | Enabled user services |
| `packages/toolchains/rustup.txt` | capture output | Rust toolchains |
| `packages/toolchains/bun.txt` | capture output | Bun global tools, including Oh My Pi Agent |
| `packages/required-extra.txt` | **install input** | Dependencies required by managed configuration or recovery scripts |

Only `profiles/` and `required-extra.txt` are installer inputs; the `inventory/`,
`services/` and `toolchains/` trees record what the capturing machine actually
had. Select a profile with `scripts/profile.sh use NAME`, and inspect the
difference between two profiles with `scripts/profile.sh diff full minimal`.

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

## Excluded from the public repository

SSH/GPG keys, browser profiles, Clash profiles, NetworkManager connections,
`~/.omp` runtime state (agent.db, logs, install-id, sessions), cookies, login
databases, histories, logs, and caches must use a password manager or encrypted
backup instead. They are not recovery inputs for this public repository.
The single `.omp` exception is `agent/config.yml` (secret-free frontend
preferences), which is a managed config; any other `.omp` content is rejected by
`audit.sh`.
