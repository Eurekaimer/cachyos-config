# MEMORY — durable knowledge for agents

Load this before changing the repository. It records what is true, why, and
what will bite you. Run history lives in `JOURNAL.md`; directory layout and data
flow live in `ARCHITECTURE.md`; open gaps live in `TASKS.md`.

## Four layers, one entry point each

| Layer | Source of truth | Single entry point |
|---|---|---|
| Packages | `packages/profiles/*.txt` (install input) | `scripts/profile.sh` |
| Configuration | `configs/apps/<app>/` | `scripts/sync-configs.sh` |
| Optional modules | `modules/<name>/` | `scripts/module.sh` |
| Recovery | `scripts/` + `manifests/` | `scripts/restore-all.sh` |

## Invariants

- **`configs/home/` is generated.** Its only source is `configs/apps/<app>/`,
  rebuilt by `scripts/sync-configs.sh --to-snapshot`. Hand edits are silently
  overwritten on the next capture.
- **`manifests/home-paths.txt` is generated** from `configs/apps/*/paths` by the
  same script; `scripts/audit.sh` fails when the two disagree.
- **`packages/inventory/`, `packages/services/`, `packages/toolchains/` are
  capture output.** Only `packages/profiles/` and `packages/required-extra.txt`
  are installer inputs.
- **`niri`, `noctalia`, `noctalia-shell`, `noctalia-qs`, `zsh`, `nodejs` must be
  listed explicitly in every profile.** On the current workstation all six are
  installed as *dependencies* of `cachyos-niri-noctalia`, so `pacman -Qqen` does
  not report them; without explicit entries a restore has no desktop and no
  shell.
- **The desktop shell is `noctalia-shell` + `noctalia-qs`** (`qs -c
  noctalia-shell`). The `noctalia` package is only a hard dependency of
  `cachyos-niri-noctalia`; no process or configuration references its binary.
- **TeX Live is exactly four packages**: `texlive-basic texlive-latex
  texlive-latexrecommended texlive-langchinese`. `xelatex` and its
  `xelatex.ini` format definition ship in `texlive-basic`; `texlive-xetex`
  adds only Arabic/Persian font mappings and is deliberately absent.
- **`configs/apps/micro/.config/micro/syntax` must not exist.** The 146 vendored
  YAML files shadow micro's built-in syntax definitions. `scripts/audit.sh`
  asserts its absence.
- **Recovery never writes `/etc/fstab`, `/etc/hostname`, `/etc/machine-id`, or
  disk UUIDs** unless `--with-hardware` is passed after explicit review.
- **Module state is declared, not guessed.** A module's `installed-check` file
  lists the absolute paths (with `$HOME`) that must exist after install;
  `scripts/module.sh list` reports `unknown` when the file is missing.

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
| niri | `.config/niri/`, `.local/bin/niri-hotkeys-zh`, `.local/bin/niri-stack-column`, `.local/share/niri/hotkeys-zh.txt` | all | — | `cfg/display.kdl` output scaling is machine-specific and re-applied by `post-restore-tweaks.sh`. The `jq`-based `niri-stack-column` is why `jq` is in `required-extra.txt` |
| noctalia | `.config/noctalia/` | `settings.json`, `colors.json`, `plugins/polkit-agent/` | vendored plugin QML/i18n | Runtime `colorschemes/` and `config.toml` are restored from the backup by `post-restore-tweaks.sh` |
| nvim | `.config/nvim/`, `.local/share/applications/neovim-markdown.desktop` | `init.lua`, `lua/**` | `doc/` | Lazy-lock pins plugin revisions; requires `fd` (Snacks picker), `tree-sitter-cli` (parser builds) and `curl` |
| obs-studio | `.config/obs-studio/{global.ini,user.ini,basic/scenes,basic/profiles,plugin_manager/modules.json}` | all | profiler logs (excluded) | `basic/profiles/*/service.json` holds the stream key and is deleted before publishing |
| omp | `.omp/agent/config.yml` | yes | everything else in `.omp/` | Only the secret-free frontend preferences file is portable; `audit.sh` rejects any other `.omp` content |
| qt | `.config/QtProject.conf` | yes | — | `history`, `lastVisited`, `qtVersion` lines leak paths and are deleted |
| shell | `.zshrc`, `.bashrc`, `.bash_profile`, `.bash_logout` | all | — | Values of `*KEY*`/`*TOKEN*`/`*SECRET*`/`*PASSWORD*` exports are blanked; variable names stay so a restore reproduces the structure |
| sioyek | `.local/bin/sioyek` | wrapper script | — | The ECDICT plugin integration itself is a module (`modules/sioyek-ecdict`) |
| starship | `.config/starship.toml` | yes | — | — |
| thunar | `.config/Thunar/uca.xml` | yes | — | — |
| timewarrior | `.config/timewarrior/timewarrior.cfg`, `.config/timewarrior/extensions/totals.py` | both | — | Timing data is never captured; `scripts/sync-timewarrior.sh` handles just these two files |
| wallpapers | `Pictures/Wallpapers/` | images | — | `.comments/` metadata is runtime state; `sync-sddm-theme.sh` copies one into the SDDM theme |
| wechat | `.local/share/applications/wechat.desktop` | yes | — | — |
| xdg-user-dirs | `.config/user-dirs.dirs`, `.config/user-dirs.locale` | both | — | `migrate-home-dirs-zh.sh` must run before `restore-user.sh` on old installs |
| yazi | `.config/yazi/` | `yazi.toml`, `keymap.toml`, `theme.toml` | — | — |

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
- **A profile is not a package list of the machine.** `pacman -Qqen` misses
  dependency-installed desktop packages; the six-name invariant above exists
  because of exactly that gap.
- **`pacman -Qm` output changes when models are added.** The old capture deleted
  `llama-cpp`/`ollama` by name; that special case is gone — a profile decides
  whether a model runtime is installed.
- **A service snapshot is not an install list.** `touchpad-boot-recovery.service`
  was removed from `packages/services/system.txt`: the unit only exists after
  the module installs it, and `restore-services.sh` would warn on every machine
  that never ran the module.
- **`koreader-bin` overwrites the patched Lua files on upgrade.** The module
  must be re-run after every upgrade; `scripts/install-packages.sh` does it
  automatically whenever the package is present.
- **Sudo may be unavailable to an agent.** `ensure_sudo` warns instead of
  hanging; unattended runs need a temporary NOPASSWD entry, removed afterwards
  and recorded in `JOURNAL.md`.
