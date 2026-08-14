# Configuration map

[简体中文](../zh-CN/configuration.md)

This is the authoritative map from a feature to its live location, snapshot
location, and restore boundary. Tables are alphabetized by the first column so
a known application or manifest can be found without scanning unrelated rows.
The allowlists under `manifests/` remain the source of truth.

## User layer

`configs/home/` mirrors allowlisted paths under `$HOME`.
`configs/dconf/user.ini` is a portable text export rather than the binary dconf
database.

| Feature | Live location | Snapshot location |
| --- | --- | --- |
| Autostart | Allowlisted entries under `~/.config/autostart/` | `configs/home/.config/autostart/` |
| Bash | `~/.bashrc`, `~/.bash_profile`, `~/.bash_logout` | `configs/home/` |
| CachyOS Hello | `~/.config/cachyos-hello.json` | `configs/home/.config/cachyos-hello.json` |
| Dconf | `~/.config/dconf/user` binary database | `configs/dconf/user.ini` text export |
| Docker helper | `~/.local/bin/docker-ass` | not snapshotted; install with `scripts/install-docker-anirss.sh` |
| Fastfetch | `~/.config/fastfetch/` | `configs/home/.config/fastfetch/` |
| Fcitx5 | `~/.config/fcitx5/` | `configs/home/.config/fcitx5/` |
| Fontconfig | `~/.config/fontconfig/` | `configs/home/.config/fontconfig/` |
| Git | `~/.gitconfig` | `configs/home/.gitconfig`; public snapshot removes email |
| GTK | `~/.config/gtk-3.0/`, `~/.config/gtk-4.0/` | `configs/home/.config/` |
| Kitty | `~/.config/kitty/` | `configs/home/.config/kitty/` |
| Micro | `~/.config/micro/settings.json`, `~/.config/micro/colorschemes/` | `configs/home/.config/micro/` |
| MIME defaults | `~/.config/mimeapps.list` | `configs/home/.config/mimeapps.list` |
| MPV | `~/.config/mpv/` | `configs/home/.config/mpv/` |
| Neovim | `~/.config/nvim/`, Neovim Markdown desktop entry | `configs/home/.config/nvim/`, `configs/home/.local/share/applications/neovim-markdown.desktop` |
| Niri | `~/.config/niri/` | `configs/home/.config/niri/` |
| Niri helpers | `~/.local/bin/niri-hotkeys-zh`, `~/.local/bin/niri-stack-column`, hotkey text | `configs/home/.local/bin/`, `configs/home/.local/share/niri/` |
| Noctalia | `~/.config/noctalia/` | `configs/home/.config/noctalia/` |
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

The first column is the actual manifest path and is sorted alphabetically.

| Manifest | Content |
| --- | --- |
| `packages/aur-explicit.txt` | Explicit AUR or external packages |
| `packages/bun-global.txt` | Bun global tools, including Oh My Pi Agent |
| `packages/pacman-explicit.txt` | Explicit packages from configured repositories |
| `packages/required-extra.txt` | Dependencies required by managed configuration or recovery scripts |
| `packages/rustup-toolchains.txt` | Rust toolchains |
| `packages/system-services.txt` | Enabled system services |
| `packages/user-services.txt` | Enabled user services |

## Excluded from the public repository

SSH/GPG keys, browser profiles, Clash profiles, NetworkManager connections,
`~/.omp` runtime state, cookies, login databases, histories, logs, and caches
must use a password manager or encrypted backup instead. They are not recovery
inputs for this public repository.
