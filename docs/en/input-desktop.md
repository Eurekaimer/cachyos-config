# Input methods and desktop integration

[简体中文](../zh-CN/input-desktop.md)

Fcitx5 configuration is stored under `configs/home/.config/fcitx5/` for Chinese input. GTK 3/4 settings, Qt settings, XDG user directories, MIME associations, and the allowlisted Clash Verge autostart entry are captured alongside it.

Desktop application intent is explicit:

+ Nautilus is the primary graphical file manager and the `Super+E` target.
+ Thunar remains installed but is not the `Super+E` target.
+ Images open with imv.
+ Markdown uses the captured `neovim-markdown.desktop` launcher.
+ Wallpapers are restored from `configs/home/Pictures/Wallpapers/`.

The dconf database is exported to `configs/dconf/user.ini` and loaded by the user restore script. This text export is portable and reviewable; the binary `~/.config/dconf/user` file is not copied.
