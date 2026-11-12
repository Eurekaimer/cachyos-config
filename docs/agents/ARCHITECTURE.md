# ARCHITECTURE

How the repository is layered, how data flows between layers, and what each
script is allowed to do. Read `MEMORY.md` for invariants and per-app notes.

## Directory tree

```
packages/
  profiles/full.txt            # install input: current workstation
  profiles/minimal.txt         # install input: ThinkPad T480 class
  required-extra.txt           # install input: recovery-tool dependencies
  core.txt                     # user-protected core packages; not auto-generated
  inventory/explicit.txt       # capture output: pacman -Qqe, dependencies excluded
  services/{system,user}.txt   # captured enabled units, used by restore
  toolchains/{rustup,bun}.txt  # captured toolchains and global tools, used by install
manifests/
  home-paths.txt               # GENERATED from configs/apps/*/paths
  captured-home.txt            # the $HOME the snapshot came from
  system-portable-paths.txt
configs/
  apps/<app>/paths             # the $HOME paths that app owns
  apps/<app>/…                 # that app's configuration (only copy)
  dconf/user.ini               # desktop settings text export
  system/portable/             # the only restored /etc subset
modules/<name>/                # install.sh, uninstall.sh, README.md,
                               # installed-check, payload files
scripts/
  module.sh                    # module entry point
  profile.sh                   # profile entry point
  capture.sh                   # machine -> repository
  sync-configs.sh              # configs/apps <-> $HOME
  restore-{all,system,user,services}.sh
  install-packages.sh
  sync-sddm-theme.sh, post-restore-tweaks.sh
  audit.sh
  lib/{common,restore,profile,sanitize,proxy}.sh
docs/
  en/, zh-CN/                  # user documentation, bilingual
  agents/{MEMORY,ARCHITECTURE,TASKS}.md
```

## Data flow

### Configuration

```mermaid
flowchart LR
  HOME["\$HOME"] -->|"sync-configs --to-snapshot"| APPS["configs/apps/&lt;app&gt;/"]
  APPS -->|sanitize.sh| APPS
  APPS -->|"regenerate"| MAN["manifests/home-paths.txt"]
  APPS -->|restore-user.sh| TARGET["target \$HOME"]
  APPS -->|"sync-configs --to-home"| HOME
```

`configs/apps/` is the only copy of the managed configuration. The app tree and
`manifests/home-paths.txt` are rewritten inside one transaction, so a failure
leaves the previous published state intact.

### Packages

```mermaid
flowchart LR
  PROFILE["packages/profiles/&lt;name&gt;.txt"] --> RESOLVE["lib/profile.sh resolve_profile"]
  REMEMBER["~/.local/state/cachyos-config/profile"] --> RESOLVE
  RESOLVE --> INSTALL["install-packages.sh"]
  EXTRA["packages/required-extra.txt"] --> INSTALL
  INSTALL -->|"pacman -Si succeeds"| REPO["pacman"]
  INSTALL -->|"no repo entry"| AUR["paru / yay"]
  INSTALL --> TOOLCHAINS["rustup + bun lists"]
```

AUR membership is inferred from the profile itself; `packages/inventory/` is
never read by the installer.

### Modules

```mermaid
flowchart LR
  M["module.sh install NAME"] --> I["modules/NAME/install.sh"]
  U["module.sh uninstall NAME"] --> X["modules/NAME/uninstall.sh"]
  L["module.sh list"] --> C["modules/NAME/installed-check"]
```

## Module contract

A conforming module directory contains:

| File | Required | Purpose |
|---|---|---|
| `install.sh` | yes | Idempotent install; accepts `--dry-run` and `--help` |
| `uninstall.sh` | yes | Reverse install |
| `README.md` | yes | What it does, install, verify, remove |
| `installed-check` | recommended | Absolute paths (may use `$HOME`), one per line, all of which exist after a successful install |
| payload files | as needed | Scripts, units, plugin sources, submodules |

`scripts/module.sh` is the only entry point: it validates the module, refuses to
run as root, forwards module-specific flags that follow the module name, and
reports installed state from `installed-check`. A directory under `modules/`
without `install.sh` (currently `modules/sddm`, consumed by
`scripts/sync-sddm-theme.sh`) is reported and skipped; see `TASKS.md`.

## Script naming rules

| Pattern | Meaning |
|---|---|
| `capture*` | machine → repository; never touches the machine's configuration |
| `sync-*` | keeps one artifact pair in step; declare the direction explicitly |
| `restore-*` | repository → machine |
| `install-*` | installs packages or toolchains |
| `module.sh`, `profile.sh` | entry points that dispatch to the units above |
| `audit.sh` | read-only validation; must fail loudly rather than warn |

## Restore order

`scripts/restore-all.sh` runs the stages in this order, and the order matters:

0. preflight (`ensure_sudo`, submodule init)
1. packages and toolchains
2. system configuration (`/etc`, portable layer)
3. user configuration and dconf (`configs/apps/<app>/`)
4. SDDM theme (needs the submodule from stage 0)
5. service enablement
6. post-restore tweaks (eDP-1 scaling, optional native Noctalia wallpaper)

Stage 3 replaces managed paths with copies of the snapshot; stage 6 handles
output scaling and optional wallpaper/input-method actions. Noctalia's native
configuration and saved GUI overrides come from the snapshot, never older backups.
