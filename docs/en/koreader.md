# KOReader ebook reader

[简体中文](../zh-CN/koreader.md)

KOReader is installed from the AUR as `koreader-bin` and runs as a native
desktop application on Niri. This page covers installation, the desktop
startup-crash fix, the PDF open-crash fix, what the snapshot publishes, and
the useful desktop keyboard shortcuts.

## Installation

```bash
paru -S koreader-bin
```

By default `paru` needs an interactive terminal to confirm sudo. If you are
driving the install from a non-interactive session, use an askpass helper
plus paru's sudo flags:

```bash
SUDO_ASKPASS=/path/to/askpass paru -S --sudoflags=-A koreader-bin
```

## Startup crash: root cause and fix

KOReader probes for a Kobo device before deciding which device module to
load. Its check treats any existing `/usr/bin/hwdetect` as a Kobo firmware
marker, but Arch's extra repository ships that exact binary, so on this
machine the probe matches, KOReader loads the Kobo device module, and the
desktop launch aborts.

This repository ships the repair as `scripts/patch-koreader-desktop.sh` — the
manual fix lives in `/usr/lib`, which is package-owned, so a `koreader-bin`
upgrade silently restores the broken probe and the crash comes back. Rerun the
script after every upgrade:

```bash
./scripts/patch-koreader-desktop.sh          # apply; prompts for sudo
./scripts/patch-koreader-desktop.sh --dry-run  # preview without changing files
./scripts/patch-koreader-desktop.sh --restore  # restore upstream originals
```

`--restore` prefers the dated backup taken at patch time; without one it
clones the koreader/koreader tag matching the installed version (e.g.
`v2026.07.1`) and restores those originals. `scripts/install-packages.sh`
**auto-applies** this patch whenever koreader-bin is present.

## Keyboard config source: koreader-keystream-config

Key bindings, the Vim Keys plugin, and the font patch have their canonical
source in the standalone `Eurekaimer/koreader-keystream-config` repo. One-shot
clone-and-restore into `~/.config/koreader/`:

```bash
./scripts/install-koreader-keystream.sh            # clone + restore; temp checkout, nothing left on disk
./scripts/install-koreader-keystream.sh --force    # overwrite existing hotkeys/defaults examples
./scripts/install-koreader-keystream.sh --dry-run  # preview only
```

Per the upstream README, existing `hotkeys.lua` / `defaults.custom.lua` are
**not** overwritten (device bindings and per-machine defaults survive); only
`--force` replaces them with the repo examples. `plugins/vimkeys.koplugin` and
`patches/1-lxgw-fonts.lua` always track the repo. `scripts/install-packages.sh`
also runs this restore after package installation.

The script keeps an idempotent dated backup — the first run copies the shipped
file to `/usr/lib/koreader/frontend/device.lua.bak-YYYYMMDD` — then removes the
bogus `or lfs.attributes("/usr/bin/hwdetect")` term from the Kobo probe. A
second run on an already-patched file reports “already patched” and does
nothing. If a future version changes the probe shape, the script refuses with
a clear error instead of guessing.

Confirm whether the package's shipped files have drifted with:

```bash
pacman -Qkk koreader-bin   # will list device.lua and readerfooter.lua as modified once patched
```

## PDF open crash with the scroll default

The `DCREREADER_VIEW_MODE = "scroll"` default in `defaults.custom.lua` (see
Reading modes below) also leaks into PDFs: `ReaderView.view_mode` reads the
global default for every document and `ReaderPaging` never resets it. With the
default footer settings (`toc_markers` on), `ReaderFooter` takes its scroll
branch and calls `document:getPosFromXPointer()` — an API only the CRE engine
(EPUB/FB2/TXT) implements — so every PDF crashes on open with
`readerfooter.lua:2203: attempt to call method 'getPosFromXPointer' (a nil value)`.

`scripts/patch-koreader-desktop.sh` repairs this too: it adds a one-line
capability guard to
`/usr/lib/koreader/frontend/apps/reader/modules/readerfooter.lua` (idempotent,
dated backup `readerfooter.lua.bak-YYYYMMDD`), so non-CRE documents keep
page-based progress. PDFs always stay page-turning regardless of the scroll
default. The bug is documented for upstream in `~/Projects/koreader-issue.md`
(issue + PR material); drop this patch once upstream merges the guard.

**Config-layer belt-and-suspenders**: the snapshot also ships the same-semantics
user patch `patches/2-pdf-scroll-guard.lua` (KOReader's user-patch mechanism,
auto-run at startup): when a document engine lacks `getPosFromXPointer`
(any PDF), it forces the page-based progress branch; all other documents are
unaffected. It does not touch `/usr/lib`, so it survives koreader-bin upgrades;
either the shell script or this patch being present suffices. Verified with
KOReader's own luajit against the four PDF/CRE x scroll/page combinations.

## Snapshot boundary

`configs/home/.config/koreader/` mirrors the configuration under
`~/.config/koreader/`: `settings.reader.lua`, `defaults.custom.lua`, and the
`settings/` Lua files (hotkeys, gestures, battery stats, book shortcuts,
cloud storage, profiles, wallabag). Two runtime layers are never published:

- reading history and caches — `history.lua` (recent-file list),
  `cache/`, `data/`, `clipboard/`, `help/`, `ota/`, `screenshots/`,
  and `settings/*.sqlite3` (book info cache, statistics, vocabulary builder);
- recent-file keys inside `settings.reader.lua` (`lastfile`, `lastdir`) are
  stripped, matching the same filename-leak rationale as `history.lua`.

`capture.sh` prunes all of the above after copying; `audit.sh` rejects those
paths if they reappear in the snapshot. `plugins/` publishes this snapshot’s
`scrollstep.koplugin` (30% reader scrolling, History and TOC paging, and
History/File Browser return keys). `patches/` publishes `1-lxgw-fonts.lua`,
which selects the installed LXGW WenKai family for KOReader UI roles,
reflowable document defaults/fallbacks, headers, footers, and monospace text.
If the font files are absent, the patch exits without changing settings.
`scripts/` and `styletweaks/` keep their empty directories (KOReader expects
the config points) but publish no files.

Restore with `./scripts/restore-user.sh`.

## Reading modes

KOReader offers `page` (page-turning) and `continuous` (scroll) modes. This
snapshot presets every reflowable document (EPUB / FB2 / TXT) to continuous
scroll through `defaults.custom.lua`:

```lua
return {
    DCREREADER_VIEW_MODE = "scroll",
}
```

`view_mode` is otherwise a per-book reading setting, so a book you switched
by hand in the past keeps its own mode; a book never touched opens in
continuous scroll. Toggle any single book’s mode with the gear menu →
Reading mode.

PDFs are unaffected by this default: they always open page-turning. The
default does leak into PDFs too, which is why the footer guard in “PDF open
crash with the scroll default” above exists — PDFs stay page-based and their
progress bar keeps working.

## Keyboard shortcuts

The bindings below are KOReader’s factory defaults for a device with a
keyboard, plus this snapshot’s overrides (marked “this snapshot”): the
hotkeys in `settings/hotkeys.lua`, plus `scrollstep.koplugin`: `Ctrl+J` /
`Ctrl+K` scroll 30% in the reader and page the History/TOC lists; `f` returns
from History to the File Browser. Vim/Sioyek-style: `j`/`k` small-scroll, `h`
History, `f` File Browser, `m` top menu, `p` rich status bar toggle, `q` quit;
chapters via `t` (TOC).

| Key | Action |
| --- | --- |
| `j` (this snapshot) | Scroll down (small step) |
| `k` (this snapshot) | Scroll up (small step) |
| `Ctrl+J` (this snapshot) | Scroll down 30% of the screen (scroll mode); page turn in page mode / PDFs; next History or TOC page |
| `Ctrl+K` (this snapshot) | Scroll up 30% of the screen (scroll mode); page turn in page mode / PDFs; previous History or TOC page |
| `h` (this snapshot) | History — recent files, in both the reader and File Manager |
| `f` (this snapshot) | File Browser (closes the book from the reader or its open History view) |
| `m` (this snapshot) | Open the top reader menu |
| `p` (this snapshot) | Show/hide the complete status bar |
| `q` (this snapshot) | Quit KOReader |
| `t` | Table of contents |
| `b` | Bookmarks |
| Enter | Open / confirm the focused menu item |
| Esc | Back / close menu |
| Shift+Back | Open the previously read document |
| Space | Next page in page mode (PDFs); unbound in scroll mode |
| ↑ / ↓ | Small scroll step, same as `j`/`k`; page turn in page mode |
| ← / → | One screen up / down in scroll mode; previous / next page in page mode |
| PgUp / PgDn | One screen up / down in scroll mode; previous / next page in page mode |
| 1-0 | Jump to 0/11/22/33/44/55/66/77/88/100% of the book |
| F6 / F7 | Previous / next view |
| Home | Return to the file-manager home (library) |
| Gear menu | Switch reading mode (page / continuous scroll) |

### Top-menu keyboard flow

After `m` opens the top menu, `j` / `k` move focus down/up, `h` returns to the
parent menu (or closes the root), and `l` / Enter activates the focused item.
Native arrow, Tab, Enter, and Esc navigation remains available.

### Rich status bar

The snapshot enables “show all selected items at once”: current/total page,
percentage, clock, pages left in the chapter, chapter/book time remaining, and
the progress bar share one footer. `p` toggles this complete footer off/on
instead of cycling one field at a time. The clock auto-refreshes each minute;
unavailable values are omitted.

### Keys KOReader cannot bind on desktop

- `Shift+J` / `Shift+K` do not exist: the hotkey plugin only pairs Shift with
  the cursor / page / navigation keys; on this desktop the letter modifier is
  `Ctrl`, so `Ctrl+J` / `Ctrl+K` carry the 30% scroll.
- `Tab` is not bindable in KOReader; `Shift+Back` already covers “previous
  document”.
- `Space` needs no binding: it is next-page in page mode (PDFs).


### File manager (home page)

Vim-style, from this snapshot’s `settings/hotkeys.lua`:

| Key | Action |
| --- | --- |
| `h` (this snapshot) | History |
| `Ctrl+J` / `Ctrl+K` (this snapshot) | Next / previous page of the file list |

The File Manager keeps its native per-item letter shortcuts except `H`, which
this plugin reserves for opening History. Cursor movement stays on native
↑ / ↓; `Ctrl+J` / `Ctrl+K` page the list.

Native keys, no binding needed:

| Key | Action |
| --- | --- |
| PgDn / PgUp | Next / previous page of the file list |
| Shift+PgDn / Shift+PgUp | Last / first page |
| Shift+Down | Page-jump dialog |
| Enter | Open the selected file / folder |
| Esc | Up one directory / close |
## Switching books

- `h` opens History — the recent-files shelf — from either the reader or File
  Manager. KOReader still starts on the file browser (`lastdir`), with no
  native “start on History” option, so `h` is the one-key recent shelf.
- Inside History, per-book letter shortcuts remain enabled except reserved
  `F`; `Ctrl+J` / `Ctrl+K` page the recent-file list, and `f` closes History
  and the book into the File Browser.
- File Manager menu → “Open last document” resumes the most recent book.
- `Shift+Back` jumps straight to the previously read document.
- `Home` returns to the file-manager home (bookshelf), pick the next book there.
- For “next / previous book in folder” bind the keyboard-shortcut actions
  `open_next_document_in_folder` / `open_previous_document_in_folder`
  (see Changing keys below).

## Bookshelf

There is no separate “bookshelf” page on desktop: `Home` opens the
file-manager home, which is the library/bookshelf, and `h` (History) is the
recent bookshelf. Starred-favorites collections are managed from the
Favorites screen inside KOReader.

## Changing keys

Gear menu → Tools → More tools → Keyboard shortcuts → Alphabet keys (single
key). You can rebind any single letter, for example point `j`/`k` at page-back
/ page-forward (Page-turn buttons) instead of scrolling, or rebind `Ctrl+J`/
`Ctrl+K` back to fast page-back/forward. When `type_to_search` is on, single
letters open full-text search instead of their bindings; disable it in the
same keyboard-shortcuts screen (the toggle is visible on devices that have a
keyboard).

Restart KOReader after changing hotkeys — KOReader flushes settings on a
clean exit and applies the full bindings on the next launch.
