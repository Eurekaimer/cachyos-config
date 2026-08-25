#!/usr/bin/env bash
# Proxy bootstrap for Clash Verge (or any local HTTP/SOCKS proxy).
# Source this file, then call setup_proxy before network-heavy commands:
#   source "$SCRIPT_DIR/lib/proxy.sh" && setup_proxy
#
# Host/port are overridable via PROXY_HOST / PROXY_PORT (no hardcoded edits).

# shellcheck source=scripts/lib/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

PROXY_HOST=${PROXY_HOST:-127.0.0.1}
PROXY_PORT=${PROXY_PORT:-7897}
PROXY_HTTP="http://${PROXY_HOST}:${PROXY_PORT}"
PROXY_SOCKS="socks5h://${PROXY_HOST}:${PROXY_PORT}"

proxy_available() {
    if command -v ss >/dev/null 2>&1 && ss -tln 2>/dev/null | grep -q "${PROXY_HOST}:${PROXY_PORT}"; then
        return 0
    fi
    if command -v nc >/dev/null 2>&1 && nc -z "${PROXY_HOST}" "${PROXY_PORT}" 2>/dev/null; then
        return 0
    fi
    return 1
}

setup_proxy() {
    if ! proxy_available; then
        warn "Proxy ${PROXY_HTTP} is not listening; continuing without proxy"
        return 1
    fi
    export http_proxy=$PROXY_HTTP
    export https_proxy=$PROXY_HTTP
    export HTTP_PROXY=$PROXY_HTTP
    export HTTPS_PROXY=$PROXY_HTTP
    export all_proxy=$PROXY_SOCKS
    export ALL_PROXY=$PROXY_SOCKS
    export no_proxy="localhost,127.0.0.1,::1,.local,api.github.com"
    export NO_PROXY="localhost,127.0.0.1,::1,.local,api.github.com"
    log "Proxy enabled: ${PROXY_HTTP} (socks ${PROXY_SOCKS})"
}
