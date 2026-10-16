# Capture and snapshot maintenance

[简体中文](../zh-CN/capture.md)

Run the capture as the desktop user whenever managed configuration, packages, toolchains, or enabled services change:

```bash
./scripts/sync-status.sh          # what moved since the last sync
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

## Incremental sync record

Reconciling a machine does not require diffing every managed path by hand. Each
capture, user restore, and full restore writes a local record:

```
~/.local/state/cachyos-config/sync-record.txt
```

It stores the revision that machine last reconciled with, a content hash of the
managed trees, and the hash of the declared `$HOME` paths. `scripts/sync-status.sh`
reads it to report only what moved:

```bash
./scripts/sync-status.sh           # state + pending-file count
./scripts/sync-status.sh --files   # repository-relative files that changed
./scripts/sync-status.sh --paths   # the managed $HOME paths they belong to
```

| State | Meaning | Action |
| --- | --- | --- |
| `clean` | The repository still equals the snapshot this machine last reconciled with | Nothing to do |
| `dirty` | Uncommitted managed changes exist here | `./scripts/capture.sh`, then commit |
| `pending` | Commits landed since the last sync | Apply with `./scripts/restore-all.sh` (or a targeted restore) |
| `rewritten` | The recorded revision is not an ancestor of HEAD | Review the whole snapshot again |

Exit codes: `0` clean, `1` pending work, `2` history rewritten.

This answers "has the repository moved?", which is what makes a full rescan
unnecessary. It does not by itself prove the live `$HOME` was not edited
afterwards; ask that question only when needed:

```bash
./scripts/sync-configs.sh --check   # $HOME vs the application layer, sanitized
```

`--check` compares every declared path against `configs/apps/<app>/` after
running the same sanitizer a capture would, so runtime state the snapshot
intentionally drops never shows as a difference. It changes nothing and exits
`1` when a path would change. The record is per-machine state and is never
committed — `scripts/audit.sh` rejects a `sync-record.txt` inside the repository.

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
