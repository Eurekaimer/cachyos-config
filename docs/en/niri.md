# Niri window manager

[简体中文](../zh-CN/niri.md)

Niri is the workstation's Wayland compositor and window manager. Its snapshot lives under `configs/home/.config/niri/`:

+ `config.kdl` — top-level includes.
+ `cfg/input.kdl` and `cfg/display.kdl` — input and output setup.
+ `cfg/layout.kdl`, `cfg/animation.kdl`, and `cfg/rules.kdl` — appearance and window behavior.
+ `cfg/keybinds.kdl` — keyboard workflow.
+ `cfg/autostart.kdl` — session services.
+ `cfg/misc.kdl` — environment variables, including the local Clash proxy at port `7897`.

Helper scripts are captured in `configs/home/.local/bin/`; the curated Chinese shortcut sheet used by `niri-hotkeys-zh` is captured in `configs/home/.local/share/niri/hotkeys-zh.txt`. The proxy environment defines lowercase and uppercase HTTP(S), SOCKS, and no-proxy variables so Chromium/Electron and command-line tools inherit consistent settings. No Clash subscriptions, nodes, or credentials are stored.

`Super+Shift+L` (`Mod+Shift+L` in Niri syntax) calls Noctalia's `lockScreen lock` IPC. Niri only dispatches the key binding; Noctalia owns the actual session lock.

`Super+S` opens the global input for the vendored
[Sioyek ECDICT plugin](sioyek-ecdict.md). The binding becomes functional after
running `scripts/install-sioyek-ecdict.sh`; selected-text lookup inside Sioyek
uses the unmodified `s` key.

Validate and reload after a change:

```bash
niri validate
niri msg action load-config-file
```

Restart already-running applications after environment changes because existing processes do not retroactively inherit them.
