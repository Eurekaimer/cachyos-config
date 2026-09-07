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
restore, Yazi gains the multi-window PDF behavior with no extra steps.
