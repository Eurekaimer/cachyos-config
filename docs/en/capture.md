# Capture and snapshot maintenance

[简体中文](../zh-CN/capture.md)

Run the capture as the desktop user whenever managed configuration, packages, toolchains, or enabled services change:

```bash
./scripts/capture.sh
./scripts/audit.sh
```

`capture.sh` rebuilds the managed snapshot from the allowlists in `manifests/`, exports dconf, records explicit Pacman/AUR packages, Rust and Bun tools, enabled services, system metadata, and hardware references. It removes the public Git email, MPV playback history, and MPV cache data before the snapshot is considered publishable.

Expected missing paths are reported as warnings. Readable system files are copied directly; protected files require `sudo`. After capture, inspect `configs/`, `packages/`, and `state/`, then require a clean audit before publishing.

Do not edit generated package lists or state files by hand. Add a new managed path to the appropriate manifest, capture again, and verify the result.
