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

`capture.sh` rebuilds the managed snapshot from the allowlists in `manifests/`, exports dconf, records explicit Pacman/AUR packages, Rust and Bun tools, enabled services, system metadata, and hardware references.

The `$HOME` layer is delegated to `scripts/sync-configs.sh --to-snapshot`, which copies every path declared in `configs/apps/<app>/paths` from `$HOME` into the matching application directory, scrubs the content below, rebuilds the generated `configs/home/` install tree, and regenerates `manifests/home-paths.txt`. Whether a model runtime such as `llama-cpp` is installed is a profile decision (`packages/profiles/`), not a capture-time special case.

Before the snapshot is considered publishable, capture strips credentials and runtime state:

| Content | Handling |
| --- | --- |
| Git user email | Removed |
| Exported shell-rc variables (`.zshrc`, `.bashrc`, `.bash_profile`) whose names contain `KEY`/`TOKEN`/`SECRET`/`PASSWORD` | Value blanked, name kept; re-add from the password manager after a restore |
| OBS `basic/profiles/*/service.json` (stream key) | Deleted |
| AniRSS downloader password/API key/login password/instance UUID | Blanked |
| KOReader cache, history, `lookup_history.lua`, `wikipedia_history.lua`, statistics databases, reader recent files | Deleted |
| MPV playback history and cache, recent paths from Qt and desktop file choosers, gThumb recent files | Removed |
| Application metadata under the wallpaper directory | Deleted |

Expected missing paths are reported as warnings. Readable system files are copied directly; protected files are copied through `sudo`, and unreadable ones without `sudo` access are reported as warnings and skipped. After capture, inspect `configs/`, `packages/`, and `state/`, then require a clean audit before publishing. The capture never reads or writes disk UUIDs, `/etc/machine-id`, `/etc/fstab`, or `/etc/hostname`; the last two are handled by the separate hardware layer only.

Do not edit generated files by hand. `configs/home/`, `manifests/home-paths.txt`, `packages/inventory/`, `packages/services/` and `packages/toolchains/` are all produced by tooling. To manage a new path, add it to the owning `configs/apps/<app>/paths` file (creating a new application directory when none fits), then run `scripts/sync-configs.sh --to-snapshot` and verify with `scripts/audit.sh`.

## Timewarrior (timew, including totals)

The home manifest manages `~/.config/timewarrior/timewarrior.cfg` and
`~/.config/timewarrior/extensions/totals.py`, preserving the extension's executable
permission and upstream license. The configuration enables summary IDs and
annotations; `totals` reports time by tag. Regular `capture.sh`, `restore-user.sh`,
and `restore-all.sh` include these files. `packages/required-extra.txt` declares
the `timew` and `python` dependencies.

To sync only Timewarrior, run from the repository root as the desktop user:

```bash
./scripts/sync-timewarrior.sh --capture           # local configuration → repository
./scripts/audit.sh
# Review changes, then git add / commit / push yourself.

# After pulling the repository on another machine:
sudo pacman -S --needed timew python
./scripts/sync-timewarrior.sh --restore --dry-run # preview
./scripts/sync-timewarrior.sh --restore           # repository → home, with backup
timew extensions
timew totals :week
timew totals :month
```

Both targeted and full restoration default to backing up existing files under
`~/.local/state/cachyos-config/backups/<timestamp>/home/`.
The targeted script does not install packages, commit/push Git changes, or refresh
unrelated configuration or package lists. It uses the standard
`~/.config/timewarrior` layout; custom XDG paths or legacy `TIMEWARRIORDB` layouts
require migration first and are not automatically converted.

Timing records, tags, annotations, undo history, and locks are private runtime
data. `~/.local/share/timewarrior/`, legacy `~/.timewarrior/`, and `data/` under the
configuration directory are not captured; the audit rejects those paths.
Restoration replaces only the two managed files, leaving timing data and other
extensions untouched. Back up timing data separately through a private channel.
For intervals with multiple tags, `totals` counts the interval once per tag, so
the grand total can exceed elapsed time.
