# Capture and snapshot maintenance

[简体中文](../zh-CN/capture.md)

Run the capture as the desktop user whenever managed configuration, packages, toolchains, or enabled services change:

```bash
./scripts/capture.sh
./scripts/audit.sh

git add -A
git commit -m "sync: refresh snapshot"
git push
```

`capture.sh` rebuilds the managed snapshot from the allowlists in `manifests/`, exports dconf, records explicit Pacman/AUR packages, Rust and Bun tools, enabled services, system metadata, and hardware references. The workstation-local model tools `llama-cpp` and `ollama` are omitted from the restorable package list. Before the snapshot is considered publishable, capture removes the public Git email, MPV playback history and cache data, recent paths from Qt and desktop file choosers, gThumb recent files, and application metadata under the wallpaper directory.

Expected missing paths are reported as warnings. Readable system files are copied directly; protected files are copied through `sudo`, and unreadable ones without `sudo` access are reported as warnings and skipped. After capture, inspect `configs/`, `packages/`, and `state/`, then require a clean audit before publishing. The capture never reads or writes disk UUIDs, `/etc/machine-id`, `/etc/fstab`, or `/etc/hostname`; the last two are handled by the separate hardware layer only.

Do not edit generated package lists or state files by hand. Add a new managed path to the appropriate manifest, capture again, and verify the result.
