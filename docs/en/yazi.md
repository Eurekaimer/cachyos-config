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
rules = [
  { use = "sioyek-new", mime = "application/pdf" },
]

[opener]
sioyek-new = [
  { run = 'sioyek --new-instance %s1', desc = "Open with Sioyek (new window)", orphan = true },
]
```

Select a PDF and press Enter to open several Sioyek windows side by side;
`orphan = true` keeps them alive after Yazi exits.

Known limitation: `--new-instance` opens a duplicate window when Enter is
pressed again on the same file. Sioyek's `--new-window` (new window in the
same instance, reusing the window of an already-open file) was tested on
2.0.0.r1147 and does not take effect when sent to an existing instance.

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
