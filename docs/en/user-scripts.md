# Optional user scripts

Five machine-specific helpers are kept out of the generic
snapshot restore because not every machine needs them. Install each one with
its own script; each module ships an `uninstall.sh`.

| Script | Purpose | Install | Remove |
| --- | --- | --- | --- |
| `bili-live-hime` | Launch the release build of `~/Projects/bili-live-hime` (Bilibili streaming companion: ingest URL/key, room edits, danmaku) | `./scripts/install-bili-live-hime.sh` | `modules/bili-live-hime/uninstall.sh` |
| `campus-login` | Open the Nankai campus-network authentication page in an isolated Chrome profile with proxies bypassed, so Clash/mihomo cannot intercept the captive portal | `./scripts/install-campus-login.sh` | `modules/campus-login/uninstall.sh` |
| `docker-ass` | Manage the ANI-RSS + qBittorrent docker compose stack and open its web interfaces | `./scripts/install-docker-anirss.sh` | `modules/docker-anirss/uninstall.sh` |
| `komari-call` | Build the KOMABELIKA terminal companion from GitHub with cargo and link it into `~/.local/bin` | `./scripts/install-komari-call.sh` | `modules/komari-call/uninstall.sh` |
| `touchpad-boot-recovery` | Boot-time self-recovery for the Lenovo 82XF I2C touchpad: rebinds `i2c_designware.0` once when the touchpad is still missing after boot (intermittent-failure workaround, not a kernel fix) | `./scripts/install-touchpad-boot-recovery.sh` | `modules/touchpad-boot-recovery/uninstall.sh` |

All installers accept `--dry-run` to preview without changing the machine.
The user scripts land in `~/.local/bin`; `touchpad-boot-recovery` installs
`/usr/local/sbin/touchpad-boot-recovery` and
`/etc/systemd/system/touchpad-boot-recovery.service` (as root). Previous
versions are backed up to `~/.local/state/cachyos-config/module-backups/`
before replacement.

## bili-live-hime

Wraps the release build of `~/Projects/bili-live-hime` (override with
`BILI_LIVE_HIME_DIR`) as a `bili-live-hime` command: the installer only fills
gaps (`git clone`, `npm install`, `npm run tauri build`). Launch with
`bili-live-hime`, rebuild after pulling upstream changes with
`bili-live-hime --rebuild`. The OBS pairing and the excluded credential path are
covered in [Bilibili streaming (bili-live-hime + OBS)](bili-live-hime.md).

## campus-login

The campus network captive portal is usually unreachable while Clash/mihomo
holds the system proxy. The script clears every proxy environment variable and
launches Chrome with `--proxy-server=direct://` in a throwaway profile
(`/tmp/chrome-campus-login`, override with `CAMPUS_CHROME_PROFILE`), then opens
`https://netauth.nankai.edu.cn/`.

Requires `google-chrome-stable`, `google-chrome`, or `chromium`. If the portal
is still unreachable afterwards, check that Clash TUN mode is off: TUN
captures traffic at the network layer, which Chrome flags cannot bypass.

## docker-ass

Wrapper around `docker compose -f ~/Projects/ASS/docker-compose.yml` (override
with `ANI_RSS_COMPOSE_FILE`) for the ANI-RSS + qBittorrent stack: `start`
(default), `qbit`, `status`, `stop`, `restart`, `logs`, `update`. Runs through
`sudo -g docker -u "$USER"` when the docker daemon is not reachable, so it works in a
non-docker-group login session.

## komari-call

`cargo install --git https://github.com/Eurekaimer/KOMABELIKA.git --locked
--force komari-call`, then `~/.local/bin/komari-call` symlinks to
`~/.cargo/bin/komari-call`. Requires a Rust toolchain (CachyOS:
`sudo pacman -S rust`, or rustup). The first build takes a few minutes.

## touchpad-boot-recovery

Device-limited workaround for the Lenovo 82XF I2C touchpad that fails to
register on some boots (`irq 27: nobody cared` → `i2c_designware.0:
controller timed out` → probe `-110`). The oneshot service waits up to 10 s
after boot; if the touchpad is still missing it rebinds `i2c_designware.0`
once and verifies the input device reappears. It is a persistent response to
an intermittent failure, **not a kernel root-cause fix**; see
[Touchpad boot self-recovery](touchpad-boot-recovery.md) for the symptom
details, upstream reports, and boundaries.
