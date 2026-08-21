#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

failures=0

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    failures=$((failures + 1))
}

log "Checking shell syntax"
while IFS= read -r -d '' script; do
    bash -n "$script" || fail "Invalid shell syntax: ${script#"$REPO_ROOT/"}"
done < <(find "$REPO_ROOT/scripts" -type f -name '*.sh' -print0)

log "Checking forbidden private/runtime paths"
for forbidden in .ssh .gnupg .aws .kube .omp google-chrome mozilla NetworkManager/system-connections io.github.clash-verge-rev; do
    if find "$REPO_ROOT/configs" -path "*/$forbidden*" -print -quit | grep -q .; then
        fail "Forbidden snapshot path found: $forbidden"
    fi
done

for runtime_path in \
    configs/home/.config/mpv/cache \
    configs/home/.config/mpv/memo-history.log \
    configs/home/.config/koreader/cache \
    configs/home/.config/koreader/data \
    configs/home/.config/koreader/clipboard \
    configs/home/.config/koreader/help \
    configs/home/.config/koreader/ota \
    configs/home/.config/koreader/screenshots \
    configs/home/.config/koreader/history.lua \
    configs/home/.config/koreader/settings/bookinfo_cache.sqlite3 \
    configs/home/.config/koreader/settings/statistics.sqlite3 \
    configs/home/.config/koreader/settings/vocabulary_builder.sqlite3; do
    [[ ! -e "$REPO_ROOT/$runtime_path" ]] || fail "Runtime snapshot path found: $runtime_path"
done
if find "$REPO_ROOT/configs/home/.config/koreader" -type f \
    \( -name '*.old' -o -name '*.bak-*' \) -print -quit | grep -q .; then
    fail "KOReader backup file found in portable snapshot"
fi

log "Checking secret-shaped content"
secret_pattern="BEGIN (OPENSSH|RSA|EC|DSA) PRIVATE KEY|AKIA[0-9A-Z]{16}|Authorization:[[:space:]]*Bearer|(^|[^[:alnum:]_])(password|passwd|api[_-]?key|access[_-]?token|client[_-]?secret)[[:space:]]*[:=][[:space:]]*[\"']?[^[:space:]\"']{8,}"
while IFS= read -r match; do
    [[ -n "$match" ]] || continue
    fail "Potential secret: ${match#"$REPO_ROOT/"}"
done < <(grep -RInE -i --exclude='audit.sh' --exclude='PolkitWindow.qml' --exclude-dir='.git' --exclude-dir='.venv' --exclude-dir='__pycache__' --binary-files=without-match "$secret_pattern" "$REPO_ROOT" || true)

log "Checking escaping symlinks"
while IFS= read -r -d '' link; do
    target=$(readlink -f -- "$link" || true)
    [[ -z "$target" || "$target" == "$REPO_ROOT"/* ]] || fail "Symlink leaves repository: ${link#"$REPO_ROOT/"} -> $target"
done < <(find "$REPO_ROOT/configs" -type l -print0)

log "Checking GitHub file-size limit"
while IFS= read -r -d '' file; do
    size=$(stat -c %s "$file")
    (( size < 90000000 )) || fail "File is 90 MB or larger: ${file#"$REPO_ROOT/"}"
done < <(
    find "$REPO_ROOT" \
        -path "$REPO_ROOT/.git" -prune -o \
        -path '*/.venv' -prune -o \
        -type f -print0
)

if (( failures )); then
    die "$failures audit check(s) failed; do not publish this snapshot"
fi
log "Audit passed"
