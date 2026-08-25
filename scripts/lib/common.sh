#!/usr/bin/env bash
set -Eeuo pipefail

export REPO_ROOT
REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
DRY_RUN=${DRY_RUN:-0}

log() {
    printf '\033[1;32m==>\033[0m %s\n' "$*"
}

warn() {
    printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2
}

die() {
    printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
    exit 1
}

print_cmd() {
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
}

run() {
    print_cmd "$@"
    (( DRY_RUN )) || "$@"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

require_non_root_user() {
    (( EUID != 0 )) || die "Run this script as the target desktop user, not root; it invokes sudo when required."
}

read_list() {
    local file=$1
    [[ -f "$file" ]] || return 0
    sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$file"
}
# Fail fast when an unattended run cannot elevate: sudo may prompt interactively,
# but a non-interactive session (CI/agent) needs a temporary NOPASSWD entry.
ensure_sudo() {
    (( DRY_RUN )) && return 0
    sudo -n true 2>/dev/null && return 0
    [[ -t 0 ]] && return 0
    warn "sudo requires a password and stdin is not a terminal."
    warn "Unattended runs need a temporary NOPASSWD entry; see AGENT.md §5."
    return 1
}
