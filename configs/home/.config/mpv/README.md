# mpv Config

This directory is installed as `~/.config/mpv` by Home Manager.
Keep player behavior here; the Nix module should only install packages and link this directory.

## Layout

- `mpv.conf`: playback defaults, cache, subtitles, screenshots, OSD.
- `input.conf`: keyboard and mouse bindings, plus uosc menu entries.
- `profiles.conf`: conditional profiles and optional quality/audio profiles.
- `script-opts/`: settings for bundled scripts.
- `scripts/`: bundled Lua scripts such as uosc, thumbfast, autoload, memo, and evafast.
- `fonts/`: local fonts used by uosc.

## Daily Keys

- `Space` or left click: pause/resume.
- Right mouse hold: temporary fast-forward with evafast.
- `Enter`: fullscreen.
- `Right` / `Left`: seek 5 seconds.
- `Up` / `Down`: seek 60 seconds.
- `Wheel`: volume.
- `s`: screenshot with subtitles/UI-free video output.
- `S`: screenshot video only.
- `Ctrl+s`: screenshot window.
- `q`: quit.
- `Q`: quit and save playback position.
- `Ctrl+o`: open file menu.
- `Ctrl+p`: playlist/files menu.
- `h`: recent history menu.
- `/`: console.

## Validate

```sh
timeout 3s mpv --config-dir=/etc/nixos/modules/home/config/mpv-config \
  --idle --vo=null --ao=null --frames=0
```
