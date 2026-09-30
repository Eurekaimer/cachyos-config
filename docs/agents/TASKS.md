# TASKS — open gaps and planned work

Known gaps, with enough context to act on them without re-deriving the
situation. Durable facts belong in `MEMORY.md`; resolved items move there or
into `JOURNAL.md`.

## Modules

- **`modules/sddm/` does not satisfy the module contract.** It holds a
  submodule (`sugar-candy`), `qt6.patch`, `theme.conf.user`, `sddm.conf` and
  `wallpaper.path`, but no `install.sh`/`uninstall.sh`; only
  `scripts/sync-sddm-theme.sh` consumes it, and it is invoked directly from
  `restore-all.sh` stage 4. Decide between:
  1. completing the contract (`install.sh` wrapping `sync-sddm-theme.sh
     --from-snapshot`, `uninstall.sh` removing the theme and
     `/etc/sddm.conf.d/10-eurekaimer-theme.conf`, `installed-check` on the
     installed theme directory), or
  2. moving the payload out of `modules/` into an assets directory.

  Until then `scripts/module.sh list` prints a skip warning for it.

- **`touchpad-boot-recovery` is not installed on the current workstation.**
  `/usr/local/sbin/touchpad-boot-recovery` and
  `/etc/systemd/system/touchpad-boot-recovery.service` are absent, so
  `module.sh list` reports `missing`. The module itself is complete; it is
  simply unused on this hardware. If the touchpad failure returns, run
  `scripts/module.sh install touchpad-boot-recovery`.

## Verification

- **`packages/inventory/` and `configs/home/` consistency is enforced by
  `scripts/audit.sh`** (profile resolvability, generated-manifest equality,
  forbidden paths). The first run after a large refactor needs a rebuilt
  baseline: run `scripts/sync-configs.sh --to-snapshot` before auditing.

- **`scripts/install-progress.sh` reports "N remaining" for profile packages
  only.** It counts `pacman -Q` hits over the profile, so AUR packages that are
  installed but renamed upstream, and dependency installs, can skew the final
  percentage. It is a progress display, not an acceptance check.

## Documentation

- **`docs/zh-CN/koreader.md` and `docs/en/koreader.md` overlap with
  `modules/koreader/README.md`.** The user docs keep the full shortcut tables;
  the module README keeps install/verify/remove. Re-check both when the module
  changes.

- **`AGENT.md` duplicates parts of `docs/agents/ARCHITECTURE.md`.** `AGENT.md`
  is the operational quick path for a fresh-machine restore; the agent docs are
  the reference. Keep the quick path short.

## Deferred

- **`micro/syntax` removal leaves a live `~/.config/micro/syntax` backup only.**
  No further action needed; recorded because the deleted tree was byte-identical
  to what the machine had, and restoring it would shadow micro's built-in
  syntax definitions.

- **`noctalia` (the package) remains installed** solely as a hard dependency of
  `cachyos-niri-noctalia`, although nothing references its binary. Removing it
  would break that package's dependency resolution; it stays listed in both
  profiles so the dependency graph is reproduced explicitly.
