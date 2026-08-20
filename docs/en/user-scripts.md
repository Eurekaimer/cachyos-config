# Optional user scripts

Three machine-specific helpers are kept out of the generic
snapshot restore because not every machine needs them. Install each one with
its own script; each module ships an `uninstall.sh`.

| Script | Purpose | Install | Remove |
| --- | --- | --- | --- |
| `campus-login` | Open the Nankai campus-network authentication page in an isolated Chrome profile with proxies bypassed, so Clash/mihomo cannot intercept the captive portal | `./scripts/install-campus-login.sh` | `modules/campus-login/uninstall.sh` |
| `docker-ass` | Manage the ANI-RSS + qBittorrent docker compose stack and open its web interfaces | `./scripts/install-docker-anirss.sh` | `modules/docker-anirss/uninstall.sh` |
| `komari-call` | Build the KOMABELIKA terminal companion from GitHub with cargo and link it into `~/.local/bin` | `./scripts/install-komari-call.sh` | `modules/komari-call/uninstall.sh` |

All installers accept `--dry-run` to preview without changing the machine.
Installed files land in `~/.local/bin`; previous versions are backed up to
`~/.local/state/cachyos-config/module-backups/` before replacement.

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
`sg docker` when the docker daemon is not reachable, so it works in a
non-docker-group login session.

## komari-call

`cargo install --git https://github.com/Eurekaimer/KOMABELIKA.git --locked
--force komari-call`, then `~/.local/bin/komari-call` symlinks to
`~/.cargo/bin/komari-call`. Requires a Rust toolchain (CachyOS:
`sudo pacman -S rust`, or rustup). The first build takes a few minutes.
