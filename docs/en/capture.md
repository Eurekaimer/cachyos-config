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

`capture.sh` rebuilds the managed snapshot from the allowlists in `manifests/`, exports dconf, records explicit Pacman/AUR packages, Rust and Bun tools, and enabled services.

The `$HOME` layer is delegated to `scripts/sync-configs.sh --to-snapshot`, which copies every path declared in `configs/apps/<app>/paths` from `$HOME` into the matching application directory, scrubs the content below, and regenerates `manifests/home-paths.txt`. That application tree is the only copy: there is no generated `configs/home/` install tree, and `audit.sh` fails if one reappears. Whether a model runtime such as `llama-cpp` is installed is a profile decision (`packages/profiles/`), not a capture-time special case.

Before the snapshot is considered publishable, capture strips credentials, runtime state and stale backups:

| Content | Handling |
| --- | --- |
| Git user email | Removed |
| Exported shell-rc variables (`.zshrc`, `.zshenv`, `.bashrc`, `.bash_profile`) whose names contain `KEY`/`TOKEN`/`SECRET`/`PASSWORD` | Value blanked, name kept; re-add from the password manager after a restore |
| OBS `basic/profiles/*/service.json` (stream key) | Deleted |
| AniRSS downloader password/API key/login password/instance UUID | Blanked |
| pi `agent/auth.json` (OAuth tokens, API keys), `agent/sessions/`, `agent/npm/node_modules/` | Deleted |
| pi `deviceId` in `agent/settings.json` | Key removed |
| KOReader cache, history, `lookup_history.lua`, `wikipedia_history.lua`, statistics databases, reader recent files | Deleted |
| MPV playback history and cache, recent paths from Qt and desktop file choosers, gThumb recent files | Removed |
| Application metadata under the wallpaper directory | Deleted |
| `*.bak`, `*.bak-*`, `*.old` anywhere in an application tree | Deleted |

Expected missing paths are reported as warnings. Readable system files are copied directly; protected files are copied through `sudo`, and unreadable ones without `sudo` access are reported as warnings and skipped. After capture, inspect `configs/` and `packages/`, then require a clean audit before publishing. The capture never reads or writes disk UUIDs, `/etc/machine-id`, `/etc/fstab`, or `/etc/hostname`; nothing outside `configs/system/portable/` is restored.

Do not edit generated files by hand. `manifests/home-paths.txt`, `packages/inventory/`, `packages/services/` and `packages/toolchains/` are all produced by tooling. To manage a new path, add it to the owning `configs/apps/<app>/paths` file (creating a new application directory when none fits), then run `scripts/sync-configs.sh --to-snapshot` and verify with `scripts/audit.sh`.

## Checking without capturing

```bash
./scripts/sync-configs.sh --check   # $HOME vs the application layer, sanitized
```

`--check` compares every declared path against `configs/apps/<app>/` after
running the same sanitizer a capture would, so runtime state the snapshot
intentionally drops never shows as a difference. It changes nothing and exits
`1` when a path would change.
