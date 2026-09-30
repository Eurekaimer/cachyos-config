# koreader: desktop patches + canonical keyboard config

Installs the KOReader desktop integration in two independent halves. Entry
point: `scripts/module.sh install koreader`.

```bash
./scripts/module.sh install koreader --dry-run   # preview both halves
./scripts/module.sh install koreader             # apply
./scripts/module.sh status koreader              # check the installed state
./scripts/module.sh uninstall koreader           # restore upstream Lua files
```

## Half 1 — system Lua patches (needs sudo)

The AUR `koreader-bin` build ships two defects on this desktop, both fixed in
`/usr/lib/koreader/frontend/`:

1. **Startup crash.** KOReader treats an existing `/usr/bin/hwdetect` as a Kobo
   firmware marker, but Arch's extra repository ships that exact binary, so the
   probe matches, KOReader loads the Kobo device module, and the desktop launch
   aborts. The patch removes the bogus
   `or lfs.attributes("/usr/bin/hwdetect")` term from `device.lua`.
2. **PDF crash on open.** `DCREREADER_VIEW_MODE = "scroll"` in
   `defaults.custom.lua` leaks into PDFs, and `ReaderFooter`'s scroll branch
   then calls `getPosFromXPointer()` — an API only the CRE (EPUB/FB2/TXT)
   engine implements — so every PDF crashes with
   `readerfooter.lua: attempt to call method 'getPosFromXPointer' (a nil value)`.
   The patch adds a one-line capability guard to
   `apps/reader/modules/readerfooter.lua`, so non-CRE documents keep
   page-based progress.

Both patches are idempotent and take a dated backup next to the file
(`device.lua.bak-YYYYMMDD`, `readerfooter.lua.bak-YYYYMMDD`) on first apply.
`/usr/lib` is package-owned, so a `koreader-bin` upgrade silently restores the
broken files: rerun this module after every upgrade. If a future package
version changes either probe's shape, the installer refuses with an explicit
error instead of guessing.

## Half 2 — keyboard config from koreader-keystream-config

`Eurekaimer/koreader-keystream-config` is the canonical source for key
bindings, the Vim Keys plugin, the font patch, and the KOReader ECDICT
installer. The module clones it to a temporary directory and restores into
`~/.config/koreader/`:

| Source | Destination | Overwrite behavior |
|---|---|---|
| `plugins/vimkeys.koplugin/` | `plugins/` | always mirrored |
| `patches/*.lua` | `patches/` | always mirrored (code, not prefs) |
| `examples/defaults.custom.lua` | `defaults.custom.lua` | only if absent; `--force` overwrites |
| `examples/settings/hotkeys.lua` | `settings/hotkeys.lua` | only if absent; `--force` overwrites |
| `scripts/install-ecdict.sh` | builds `data/dict/ecdict-en-zh/` | reused when valid; `--refresh-dictionary` rebuilds |

Per the upstream README, existing `hotkeys.lua` / `defaults.custom.lua` are
**not** overwritten by default, so device bindings and per-machine defaults
survive; only `--force` replaces them with the repo examples. The dictionary
step downloads a pinned, SHA-256-verified ECDICT source and streams 3,402,564
English-Chinese StarDict entries. Skip it with `--skip-dictionary` when only
the keyboard configuration is wanted. Requires `7zip` and `curl` (listed in
`packages/required-extra.txt`).

## Options

```
--dry-run             Print the commands that would be run without changing files
--restore             Restore both system Lua files to the upstream originals and stop
--force               Overwrite existing destination files from the keystream repo
--skip-dictionary     Restore keyboard/config files without installing ECDICT
--refresh-dictionary  Rebuild ECDICT even when the expected version is present
-h, --help            Show this help
```

## Uninstall

`modules/koreader/uninstall.sh` (via `scripts/module.sh uninstall koreader`)
forwards `--restore`: it puts both `/usr/lib/koreader` files back to the
upstream originals, preferring the dated `.bak-*` backup and falling back to a
clone of the `koreader/koreader` tag matching the installed `koreader-bin`
version. The `~/.config/koreader` keyboard configuration is deliberately kept —
it is managed by the generic snapshot under `configs/apps/koreader/`.

## Verify

```bash
koreader                                   # no startup crash, no PDF crash
grep -c 'hwdetect' /usr/lib/koreader/frontend/device.lua   # 0 after patching
pacman -Qkk koreader-bin                   # lists both files as modified
```

After installing, restart KOReader, leave "Use external dictionary" disabled,
and enable Vim Keys in Tools > More tools > Plugin manager.

## Snapshot boundary

The portable snapshot (`configs/apps/koreader/`) publishes `settings.reader.lua`,
`defaults.custom.lua`, `patches/`, `plugins/vimkeys.koplugin/`, and the
`settings/*.lua` files. Reading history, caches, `data/`, `settings/*.sqlite3`,
and the recent-file keys inside `settings.reader.lua` are pruned by
`scripts/capture.sh` and rejected by `scripts/audit.sh`. Full user-facing
documentation: `docs/en/koreader.md` and `docs/zh-CN/koreader.md`.
