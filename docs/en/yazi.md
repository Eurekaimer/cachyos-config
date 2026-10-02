# Yazi file manager

[简体中文](../zh-CN/yazi.md)

Yazi is the workstation's terminal file manager. Its configuration file
`~/.config/yazi/yazi.toml` is managed by this repository via the `.config/yazi`
entry in `manifests/home-paths.txt`.

## Multi-window PDF opening

**Problem**: Sioyek is a single-instance application. The first PDF opens
normally, but later launches send the path to the existing instance and exit;
the instance does not open a new window, so you must close every existing
window before a new one can appear.

**Fix**: a dedicated opener for `application/pdf` uses `--new-instance` so
each document gets its own process and window:

```toml
[open]
prepend_rules = [
  { use = "sioyek-new", mime = "application/pdf" },
]

[opener]
sioyek-new = [
  { run = '~/.local/bin/sioyek --new-instance %s1', desc = "Open with Sioyek (new window)", orphan = true },
]
```

The opener calls `~/.local/bin/sioyek` directly instead of `sioyek` because
the wrapper is what makes Sioyek present correctly under this compositor:
`QT_QPA_PLATFORM=xcb`. Apps launched by niri keybindings (e.g. `Super+Y`)
inherit niri's PATH, which does not contain `~/.local/bin`; the bare command
would find the unwrapped `/usr/bin/sioyek`, whose native Wayland path fails
to present its first frame under Qt 6.11 + niri.

Select a PDF and press Enter to open several Sioyek windows side by side;
`orphan = true` keeps them alive after Yazi exits.

Known limitation: `--new-instance` opens a duplicate window when Enter is
pressed again on the same file. Sioyek's `--new-window` (new window in the
same instance, reusing the window of an already-open file) was tested on
2.0.0.r1147 and does not take effect when sent to an existing instance.

## Multi-window Markdown opening

Markdown MIME types and `*.{md,markdown,mdown,mkd}` paths use
`gtk-launch neovim-markdown %s` to invoke the captured Kitty/Neovim desktop
launcher directly. Each Enter opens a separate window without blocking Yazi.
Restart Yazi after changing its configuration. The path rule also covers
Markdown detected as `text/plain`; bypassing `xdg-open` avoids opening it in
Kate. Other plain-text associations are unchanged.

## HTML opens in Chrome

`text/html` and `*.{html,htm}` use a dedicated `chrome` opener:

```toml
[open]
prepend_rules = [
  { use = "chrome", mime = "text/html" },
  { use = "chrome", url = "*.{html,htm}" },
]

[opener]
chrome = [
  { run = 'google-chrome-stable --new-window %s1', desc = "Open in Chrome (new window)", orphan = true },
]
```

Enter on a lesson or reference `.html` opens a new Chrome window. A bare
`xdg-open` routes through `google-chrome.desktop`, which reuses an existing
session and can look like a no-op; `--new-window` makes each Enter visibly do
something. The MIME rule also covers HTML detected as `text/plain`.

## Directory sizes in the file list

**Problem**: the built-in `size` linemode prints an item count for
directories, so the list never says how much space a folder occupies, and
counts mixed with sizes make one column look ragged.

**Fix**: the `dirsize` plugin measures every directory listed on the current
page in the background and publishes the result into the file list, exactly
like the built-in folder spotter (`<Tab>`) does. Three files cooperate:

| File | Purpose |
| --- | --- |
| `plugins/dirsize.yazi/main.lua` | fetcher: measures directories and emits `FilesOp::Size` |
| `init.lua` | plugin setup, the `size` linemode override, and the status-bar child |
| `yazi.toml` | `[plugin] fetchers` rule `{ url = "*/", run = "dirsize", prio = "low", group = "size" }` |

The `size` linemode prints a size only, so the column stays aligned, and a
directory whose size has not been measured yet stays blank instead of showing
a count. The item count of the hovered directory is appended to its name in
the status bar: `2 items`, `1 item`, or `empty`.

Measurements are cached per directory and invalidated by its mtime; a
directory that is already being measured is claimed, so concurrent fetchers
never walk the same tree twice; a running measurement stops when the user
navigates away. Unreadable directories are skipped with a single
`dirsize: cannot measure …` line in `~/.local/state/yazi/yazi.log`. The value
is the sum of file lengths — the same number `sort_by = "size"` and the folder
spotter show — not allocated disk blocks.

## Missing Sioyek libraries after an upgrade

On 2026-09-07, upgrading `libmupdf` from 1.28.0 to 1.28.3 left the locally
built AUR `sioyek-git` linked to `libmupdf.so.28.0`. Rebuilding and reinstalling
the same source revision against the installed library restored startup.
Do not substitute library symlinks or downgrade the library as a workaround.
Use full updates (`paru -Syu`) and run the installed `checkrebuild` afterward:
AUR packages may require rebuilding after dependency ABI changes even when
their own version has not changed.

## Yazi 26 configuration syntax notes

Upgrading to Yazi 26 changes opener configuration in three ways; following
the old syntax makes opening fail silently:

1. **Opener definitions live in the `[opener]` section of `yazi.toml`**; a
   standalone `openers.toml` is no longer read.
2. **Opener values must be lists**: `name = [{ run = …, desc = … }]`, not a
   map.
3. **File placeholders are `%s1` (first file) / `%s` (spread)**; `$@` and `$n`
   are deprecated.

## Preview

PDF previews use `pdftoppm` (provided by poppler, already in the package
manifest); other file types use Yazi's built-in preloaders or plugins. Preview
image caches live in `/tmp/yazi-<uid>/`.

## Restore behavior

`restore-user.sh` restores `~/.config/yazi/` from the allowlist. After
restore, Yazi gains the multi-window PDF behavior and the directory-size
plugin with no extra steps.
