# MEMORY — durable knowledge for agents

Load this before changing the repository. It records what is true, why, and
what will bite you. Directory layout and data flow live in `ARCHITECTURE.md`;
open gaps live in `TASKS.md`.

## Four layers, one entry point each

| Layer | Source of truth | Single entry point |
|---|---|---|
| Packages | `packages/profiles/*.txt` (install input) | `scripts/profile.sh` |
| Configuration | `configs/apps/<app>/` | `scripts/sync-configs.sh` |
| Optional modules | `modules/<name>/` | `scripts/module.sh` |
| Recovery | `scripts/` + `manifests/` | `scripts/restore-all.sh` |

## Invariants

- **`configs/apps/<app>/` is the only copy of the managed configuration.**
  `scripts/restore-user.sh` reads it back directly; there is no generated
  `configs/home/` install tree, and `scripts/audit.sh` fails if one reappears.
- **`manifests/home-paths.txt` is generated** from `configs/apps/*/paths` by the
  same script; `scripts/audit.sh` fails when the two disagree.
- **`packages/inventory/explicit.txt` records pacman's explicit install
  reasons**, from repositories and foreign sources, without dependencies.
  It is capture output, not a package-install input. Package installation reads
  `packages/profiles/` and `packages/required-extra.txt`; captured services and
  toolchains are also used during recovery.
- **Core software is protected.** Never uninstall a package in
  `packages/core.txt` or remove it from the full profile unless the user first
  explicitly changes its tier. Other packages remain unclassified, not
  automatically removable; ask before any package operation.
- **Publishing is capture → audit → commit.** `scripts/capture.sh` rewrites the
  snapshot from the live machine, `scripts/audit.sh` refuses to publish when a
  secret, a runtime path or a stale backup leaked in, and only then does the
  operator `git add/commit/push`. Nothing else tracks sync position, and no
  per-machine state file is committed; `scripts/sync-configs.sh --check` is the
  only way to ask whether the live `$HOME` still matches.
- **`niri`, `noctalia`, `zsh`, `nodejs` must be listed in every profile.**
  Profile membership and pacman's explicit/dependency install reasons differ.
- **The desktop shell is native `/usr/bin/noctalia`**, observed as
  `v5.2.1 (5.2.1-1-dirty)` on 2026-10-10 and `v5.4.1 (5.4.1-1-dirty)` on
  2026-11-01. Use `noctalia msg`, not QuickShell IPC.
  Profiles do not explicitly install `noctalia-shell` or `noctalia-qs`; leave
  the CachyOS meta package and existing system packages alone.
- **`~/.local/state/noctalia/settings.toml` must open with a `config_version`
  the installed package accepts.** `noctalia 5.4.1` accepts `14` and rejects
  `15` with “Config Error: version 15 is newer than version 14”; a snapshot
  captured under an older binary can therefore break a restore. Check the first
  line after restoring it. Observed 2026-11-07: this workstation runs
  `noctalia 5.4.0-1.1` and accepts `config_version = 16`, so a snapshot taken
  here can be rejected by an older laptop build — the shell then falls back to
  default bar/tray layout, which looks like "the config did not sync".
- **Wallpaper and transitions are declarative.** `[wallpaper.default].path` and
  `[wallpaper.last].path` are both
  `Pictures/Wallpapers/project_mifeng.png`. `transition` is a candidate pool,
  so a single entry pins the effect: `[wallpaper]` and `[lockscreen]` each hold
  `transition = ["fade"]`; the lock screen has its own duration and edge
  smoothness and does not inherit from `[wallpaper]`.
- **`/etc/vconsole.conf` must name a keymap `kbd` actually ships.** `KEYMAP=cn`
  does not exist (`/usr/share/kbd/keymaps` has no `cn`/`zh`), so the initramfs
  stage of `systemd-vconsole-setup` fails with `loadkeys: Unable to open file:
  cn` three times before plymouth hides it — that is the "failed to open" line
  seen at boot, and it is a virtual console unit, not a virtual machine. The
  console is pinned to `us`; `XKBLAYOUT=cn` stays because it only drives X11
  (`/etc/X11/xorg.conf.d/00-keyboard.conf` reads it too). The `sd-vconsole` hook
  embeds the file into the initramfs, so editing it requires
  `update-initramfs` (`limine-mkinitcpio`; images land in
  `/boot/<machine-id>/<kernel>/initramfs`, not `/boot/initramfs-*.img`).
- **`libvirtd.service` is deliberately not enabled.** Only the libvirt sockets
  (`libvirtd{,-ro,-admin}.socket`, `virtlockd{,-admin}.socket`,
  `virtlogd{,-admin}.socket`) are enabled, so the daemon starts on the first real
  client connection. `QEMU-win10` lives in `qemu:///session`, has no autostart
  link, and is started by hand with `manage.sh start`; `virbr0` therefore appears
  only when system-level libvirt is first used. `restore-services.sh` only
  enables, so a machine that already had the daemon enabled needs
  `sudo systemctl disable --now libvirtd.service` after restoring.
- **TeX Live is exactly four packages**: `texlive-basic texlive-latex
  texlive-latexrecommended texlive-langchinese`. `xelatex` and its
  `xelatex.ini` format definition ship in `texlive-basic`; `texlive-xetex`
  adds only Arabic/Persian font mappings and is deliberately absent.
- **`configs/apps/micro/.config/micro/syntax` must not exist.** The 146 vendored
  YAML files shadow micro's built-in syntax definitions. `scripts/audit.sh`
  asserts its absence.
- **Recovery writes only `configs/system/portable/`.** No disk UUIDs,
  `/etc/machine-id`, `/etc/fstab`, or `/etc/hostname` are read or written, and
  location-generated files such as `mirrorlist` are never restored.
- **Module state is declared, not guessed.** A module's `installed-check` file
  lists the absolute paths (with `$HOME`) that must exist after install;
  `scripts/module.sh list` reports `unknown` when the file is missing.
- **`modules/campus-login` installs `~/.local/bin/campus-login`** on THIS
  workstation (`./scripts/module.sh install campus-login`; `installed-check`
  is `$HOME/.local/bin/campus-login`). It launches a throwaway Chrome profile
  with every proxy variable cleared and `--proxy-server=direct://` to reach the
  Nankai captive portal. It cannot bypass Clash TUN mode, which intercepts at
  the network layer. The network itself needs web authentication before any
  node works; see `modules/campus-login/README.md`.

## Per-application configuration notes

Everything below lives under `configs/apps/<app>/`, mirroring paths relative to
`$HOME`. "Hand-written" means the file is ours and should be edited; "vendored"
means upstream code that must stay untouched.

| App | Paths | Hand-written | Vendored — do not edit | Watch out for |
|---|---|---|---|---|
| ani-rss | `Projects/ASS/config/{ani,config}.v2.json` | both | — | `config.v2.json` carries downloader/API credentials, the login password and the instance UUID; `sanitize.sh` blanks them |
| cachyos-hello | `.config/cachyos-hello.json` | yes | — | — |
| clash-verge | `.config/autostart/Clash Verge.desktop`, `.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles/Script.js` | both | — | `Script.js` is the only portable Clash file; subscriptions and credentials are excluded and rejected by `audit.sh` |
| fastfetch | `.config/fastfetch/` | yes | — | — |
| fcitx5 | `.config/fcitx5/`, `.local/bin/fcitx5-toggle-japanese` | `conf/`, the helper script | `pinyin/`, caches | `conf/cached_layouts` is a cache but harmless |
| fontconfig | `.config/fontconfig/fonts.conf` | yes | — | — |
| git | `.gitconfig` | yes | — | `user.email` is stripped from the public snapshot |
| go-musicfox | `.config/go-musicfox/config.toml` | yes | — | — |
| gtk | `.config/gtk-3.0/` | yes | — | GTK4 config is not snapshotted |
| kitty | `.config/kitty/` | `kitty.conf` | `themes/shorin.conf` | — |
| koreader | `.config/koreader/` | `defaults.custom.lua`, `settings/*.lua`, `patches/*.lua` | `plugins/vimkeys.koplugin/` | Two runtime layers are pruned by `sanitize.sh`: histories/caches/data, and `lastfile`/`lastdir` inside `settings.reader.lua`. `settings/*.sqlite3` never ship |
| micro | `.config/micro/settings.json`, `.config/micro/colorschemes/` | settings | vendored colorschemes | `syntax/` was deliberately deleted — never restore it |
| mimeapps | `.config/mimeapps.list` | yes | — | — |
| mpv | `.config/mpv/` | `mpv.conf`, `input.conf`, `profiles.conf`, `script-opts/*.conf`, `scripts/memo.lua` | `scripts/uosc/` + `fonts/` + `scripts/{autoload,evafast,inputevent,thumbfast}.lua` + `script-opts/uosc.conf`'s upstream defaults | `memo.lua` is ours; `script-opts/uosc.conf` is locally tuned; the playback cache and `memo-history.log` are runtime state |
| niri | `.config/niri/`, `.local/bin/niri-hotkeys-zh`, `.local/bin/niri-screenshot-window`, `.local/bin/niri-stack-column`, `.local/share/niri/hotkeys-zh.txt` | all | — | `cfg/display.kdl` output scaling is machine-specific and re-applied by `post-restore-tweaks.sh`. `niri-stack-column` requires `jq`; opaque window screenshots require Python, ImageMagick and `wl-clipboard`, all in `required-extra.txt`. Niri writes PNGs asynchronously; the screenshot helper waits for IEND before conversion |
| noctalia | `.config/noctalia/`, `.local/state/noctalia/settings.toml`, `.local/share/noctalia/plugins/storage-gb` | `config.toml`, `widgets.toml`, GUI overrides, local `storage_gb` plugin | native plugin files | GUI settings override config defaults; the local storage widget displays Chinese labels and decimal GB. History/cache/private state are excluded. No backup backfill |
| nvim | `.config/nvim/`, `.local/share/applications/neovim-markdown.desktop` | `init.lua`, `lua/**` | `doc/` | Lazy-lock pins plugin revisions; `clangd` comes from the system `clang` package, not Mason. Required extras also include `fd`, `tree-sitter-cli` and `curl` |
| obs-studio | `.config/obs-studio/{global.ini,user.ini,basic/scenes,basic/profiles,plugin_manager/modules.json}` | all | profiler logs (excluded) | `basic/profiles/*/service.json` holds the stream key and is deleted before publishing |
| omp | `.omp/agent/config.yml`, `.omp/agent/models.yml`, `.omp/agent/themes/` | all three | everything else in `.omp/` | Only secret-free configuration is portable: `models.yml` must reference API keys by env var, custom themes stay JSON; `audit.sh` rejects any other `.omp` content |
| pi | `.pi/agent/settings.json`, `.pi/agent/models-store.json`, `.pi/agent/npm/package.json` | all three | `auth.json`, `agent/sessions/`, `npm/node_modules/` | `auth.json` holds live OAuth tokens and an API key and is deleted by `sanitize.sh`; `deviceId` is stripped from `settings.json` as a machine identifier; the npm tree is a declaration only, never vendored; `audit.sh` rejects any other `.pi` content |
| qt | `.config/QtProject.conf` | yes | — | `history`, `lastVisited`, `qtVersion` lines leak paths and are deleted |
| shell | `.zshrc`, `.zshenv`, `.bashrc`, `.bash_profile`, `.bash_logout` | all | — | Values of `*KEY*`/`*TOKEN*`/`*SECRET*`/`*PASSWORD*` exports are blanked; variable names stay so a restore reproduces the structure. `.zshenv` is captured because every zsh invocation reads it and it is where agent API keys are exported |
| sioyek | `.local/bin/sioyek` | wrapper script | — | The ECDICT plugin integration itself is a module (`modules/sioyek-ecdict`) |
| starship | `.config/starship.toml` | yes | — | — |
| thunar | `.config/Thunar/uca.xml` | yes | — | — |
| wallpapers | `Pictures/Wallpapers/` | images | — | `.comments/` metadata is runtime state; `sync-sddm-theme.sh` copies one into the SDDM theme |
| wechat | `.local/share/applications/wechat.desktop` | yes | — | — |
| xdg-user-dirs | `.config/user-dirs.dirs`, `.config/user-dirs.locale` | both | — | Renaming directories on an old install is a manual step; no script rewrites XDG dirs |
| yazi | `.config/yazi/` | `yazi.toml`, `keymap.toml`, `init.lua`, `plugins/dirsize.yazi/` | — | Both TOMLs hold only overrides over the shipped presets (`prepend_*`/`append_*`), never full copies. `y` also writes `text/uri-list` to the Wayland clipboard through `wl-copy` (`wl-clipboard`) |
| zed | `.config/zed/settings.json`, `.config/zed/keymap.json` | both | — | `ui_font_family` is `Monaspace Radon`, provided by `otf-monaspace` in `packages/profiles/`; `ui_font_size` 22 applies to chrome only, buffers stay on `buffer_font_*`. The keymap exists to undo two Linux defaults: vim mode binds `ctrl-v` (`vim::PushLiteral` when inserting, `vim::ToggleVisualBlock` in normal mode) and `Editor && extension == md` binds `ctrl-shift-v` to `markdown::OpenPreview`, so `ctrl-v` is rebound to `editor::Paste` and the Markdown preview stays on `ctrl-k v` |

## Common traps and how they are handled

- **`local a=$1 b="$a/…"` is broken in bash.** All names are declared unset
  before any assignment runs, so `b` sees an empty `a` and `set -u` kills the
  script. Declare them as separate `local` statements. This has already bitten
  `scripts/lib/profile.sh` twice.
- **A `trap … EXIT` handler's last command sets the script's exit status.**
  End cleanup functions with `return 0`, or a successful run reports failure
  when the last `[[ -n "" ]]` test fails.
- **Variables read inside an EXIT trap must be file-scope.** A `local clone_dir`
  inside the function that created it is already out of scope when the trap
  fires, and the temp directory leaks.
- **Never call a helper that assigns a global inside `$(…)`.** The subshell
  gets the assignment; the caller keeps the old value. `fetch_original` in
  `modules/koreader/install.sh` was restructured for this reason.
- **`comm` must run under the same collation as the preceding `sort`.** Pair
  `LC_ALL=C sort -u` with `LC_ALL=C comm`, or it reports "input is not in sorted
  order" on perfectly sorted UTF-8 input.
- **A profile is not a package list of the machine.** `pacman -Qqe` excludes
  dependency-installed packages even when a profile lists them.
- **`pacman -Qm` output changes when models are added.** The old capture deleted
  `llama-cpp`/`ollama` by name; that special case is gone — a profile decides
  whether a model runtime is installed.
- **A service snapshot is not an install list.** `capture.sh` records only
  enabled units whose `FragmentPath` belongs to an installed package
  (`pacman -Qo`), for both buses. Module-installed and hand-written units
  (`sioyek-ecdict.service`, one-off experiments such as `tp-ab-*.service`) are
  excluded: they exist only after
  their installer runs, and recording them would make `restore-services.sh`
  warn on every machine that never ran it. The module's own `install.sh`
  enables its unit.
- **`koreader-bin` overwrites the patched Lua files on upgrade.** The module
  must be re-run after every upgrade; `scripts/install-packages.sh` does it
  automatically whenever the package is present.
- **Sudo may be unavailable to an agent.** `ensure_sudo` warns instead of
  hanging; unattended runs need a temporary NOPASSWD entry, removed afterwards.
