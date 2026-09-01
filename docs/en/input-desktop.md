# Input methods and desktop integration

[简体中文](../zh-CN/input-desktop.md)

Fcitx5 configuration for Chinese and Japanese input is stored under `configs/home/.config/fcitx5/`. GTK 3/4 settings, Qt settings, XDG user directories, MIME associations, and the allowlisted Clash Verge autostart entry are captured alongside it.

## Chinese/English and Japanese/English input lock

Two Fcitx5 input-method groups keep `Super+R` as a two-state toggle instead of creating a Chinese/English/Japanese cycle:

| Mode | Fcitx5 group | `Super+R` toggles |
|---|---|---|
| Chinese/English (default) | `Default` | US keyboard / Pinyin |
| Japanese/English | `Japanese` | US keyboard / Mozc |

`Super+Shift+R` runs `~/.local/bin/fcitx5-toggle-japanese`, switches between the two groups, and sends a notification for the active mode. The script creates no separate state file: the current Fcitx5 group is the sole state source, and an unknown group falls back to `Default`.

Restore dependencies:

+ `packages/pacman-explicit.txt` includes the official `fcitx5-mozc` package.
+ `manifests/home-paths.txt` captures the group-toggle script; `restore-user.sh` restores it under `~/.local/bin/` with its executable mode.
+ `configs/home/.config/niri/cfg/keybinds.kdl` retains the existing `Super+R` binding and adds `Super+Shift+R`.

After restoring, log back into niri or restart Fcitx5 in the current session, then verify group switching:

```bash
fcitx5 -rd --replace
fcitx5-remote -m mozc
fcitx5-remote -g Default && fcitx5-remote -q
~/.local/bin/fcitx5-toggle-japanese && fcitx5-remote -q
~/.local/bin/fcitx5-toggle-japanese && fcitx5-remote -q
```

The addon query should print `mozc`; the three group queries should print `Default`, `Japanese`, and `Default`. Complete the check in a text field: verify the English/Chinese and English/Japanese `Super+R` pairs and the mode notifications from `Super+Shift+R`.

Desktop application intent is explicit:

+ Nautilus is the primary graphical file manager and the `Super+E` target.
+ Thunar remains installed but is not the `Super+E` target.
+ Images open with imv.
+ Markdown uses the captured `neovim-markdown.desktop` launcher.
+ Wallpapers are restored from `configs/home/Pictures/Wallpapers/`.

The dconf database is exported to `configs/dconf/user.ini` and loaded by the user restore script. This text export is portable and reviewable; the binary `~/.config/dconf/user` file is not copied.
