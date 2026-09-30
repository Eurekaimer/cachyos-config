# Optional user scripts

Machine-specific helpers are kept out of the generic snapshot restore because
not every machine needs them. They are **modules**: each lives in
`modules/<name>/` with `install.sh`, `uninstall.sh`, `README.md` and an
`installed-check` file, and runs through the single entry point
`scripts/module.sh`:

```bash
./scripts/module.sh list                        # every module + installed state
./scripts/module.sh status komari-call          # which check paths exist
./scripts/module.sh install komari-call         # install; --dry-run to preview
./scripts/module.sh uninstall komari-call       # remove
```

| Module | Purpose | Install | Remove |
| --- | --- | --- | --- |
| `bili-live-hime` | Launch the release build of `~/Projects/bili-live-hime` (Bilibili streaming companion: ingest URL/key, room edits, danmaku) | `./scripts/module.sh install bili-live-hime` | `./scripts/module.sh uninstall bili-live-hime` |
| `campus-login` | Open the Nankai campus-network authentication page in an isolated Chrome profile with proxies bypassed, so Clash/mihomo cannot intercept the captive portal | `./scripts/module.sh install campus-login` | `./scripts/module.sh uninstall campus-login` |
| `docker-anirss` | Manage the ANI-RSS + qBittorrent docker compose stack and open its web interfaces | `./scripts/module.sh install docker-anirss` | `./scripts/module.sh uninstall docker-anirss` |
| `komari-call` | Build the KOMABELIKA terminal companion from GitHub with cargo and link it into `~/.local/bin` | `./scripts/module.sh install komari-call` | `./scripts/module.sh uninstall komari-call` |
| `koreader` | Patch the two AUR `koreader-bin` desktop defects and restore the canonical keyboard config | `./scripts/module.sh install koreader` | `./scripts/module.sh uninstall koreader` |
| `sioyek-ecdict` | Offline English-to-Chinese lookup plugin for Sioyek | `./scripts/module.sh install sioyek-ecdict` | `./scripts/module.sh uninstall sioyek-ecdict` |
| `touchpad-boot-recovery` | Boot-time self-recovery for the Lenovo 82XF I2C touchpad: rebinds `i2c_designware.0` once when the touchpad is still missing after boot (intermittent-failure workaround, not a kernel fix) | `./scripts/module.sh install touchpad-boot-recovery` | `./scripts/module.sh uninstall touchpad-boot-recovery` |

Every command accepts `--dry-run` to preview without changing the machine.
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

## koreader

Patches the two desktop defects shipped by AUR `koreader-bin` — the startup
device-probe crash in `/usr/lib/koreader/frontend/device.lua` and the PDF
footer crash in `apps/reader/modules/readerfooter.lua` — and restores the
canonical keyboard configuration from `Eurekaimer/koreader-keystream-config`
into `~/.config/koreader/`. `uninstall` rolls the system Lua files back to the
upstream originals and leaves the user configuration alone. Details:
[KOReader](koreader.md) and `modules/koreader/README.md`.

## sioyek-ecdict

Installs the vendored offline English-to-Chinese lookup plugin into the current
user's native Sioyek configuration, plus a resident user service that keeps the
ECDICT dictionary warm. `uninstall` removes the service and the plugin's
Sioyek key bindings while preserving the project directory and dictionary data.
Details: [Sioyek ECDICT](sioyek-ecdict.md).

## touchpad-boot-recovery

Device-limited workaround for the Lenovo 82XF I2C touchpad that fails to
register on some boots (`irq 27: nobody cared` → `i2c_designware.0:
controller timed out` → probe `-110`). The oneshot service waits up to 10 s
after boot; if the touchpad is still missing it rebinds `i2c_designware.0`
once and verifies the input device reappears. It is a persistent response to
an intermittent failure, **not a kernel root-cause fix**; see
[Touchpad boot self-recovery](touchpad-boot-recovery.md) for the symptom
details, upstream reports, and boundaries.
