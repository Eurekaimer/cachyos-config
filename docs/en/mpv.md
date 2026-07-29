# MPV media stack

[简体中文](../zh-CN/mpv.md)

The MPV snapshot under `configs/home/.config/mpv/` contains player options, key bindings, profiles, fonts, script options, and Lua scripts. It includes the uosc interface plus playback helpers such as thumbfast, autoload, autodeint, evafast, inputevent, memo, and webtorrent configuration.

Runtime state is not configuration. `capture.sh` removes `memo-history.log` and the MPV `cache/` tree, including watch-later entries, so filenames and playback history are not published. `audit.sh` rejects those paths if they reappear.

Restore with `./scripts/restore-user.sh`. After changing window behavior, restart MPV before validating Niri stacking; existing windows retain their process state.
