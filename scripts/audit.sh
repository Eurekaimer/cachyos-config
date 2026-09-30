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

log "Checking package profiles"
if [[ -d "$REPO_ROOT/packages/profiles" ]]; then
    # Every profile entry must resolve to a repository package or an AUR name.
    # Names that resolve nowhere are typos that would abort a restore halfway.
    while IFS= read -r profile_file; do
        while IFS= read -r package; do
            package=${package%%#*}
            package=$(printf '%s' "$package" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            [[ -n "$package" ]] || continue
            if ! pacman -Si -- "$package" >/dev/null 2>&1 && \
               ! pacman -Qq -- "$package" >/dev/null 2>&1; then
                fail "Profile entry resolves neither to a repository package nor to an installed/AUR name: ${package} (${profile_file#"$REPO_ROOT/"})"
            fi
        done <"$profile_file"
    done < <(find "$REPO_ROOT/packages/profiles" -type f -name '*.txt' | sort)
fi
# These were removed deliberately: model runtimes are a profile decision now.
# Match real entries only; a comment naming them is fine.
for banned in llama-cpp shelly; do
    if grep -rIh --exclude-dir='.git' -E "^[[:space:]]*${banned}[[:space:]]*(#.*)?$" \
        "$REPO_ROOT/packages/profiles" | grep -q .; then
        fail "Removed entry reappeared in a profile: $banned"
    fi
done

log "Checking generated home manifest"
if [[ -d "$REPO_ROOT/configs/apps" ]]; then
    generated=$(mktemp)
    # shellcheck source=scripts/lib/profile.sh
    source "$REPO_ROOT/scripts/lib/profile.sh"
    apps_manifest "$REPO_ROOT" | cut -f2 | LC_ALL=C sort -u >"$generated"
    declared=$(mktemp)
    read_list "$REPO_ROOT/manifests/home-paths.txt" | LC_ALL=C sort -u >"$declared"
    if ! diff -q -- "$generated" "$declared" >/dev/null; then
        fail "manifests/home-paths.txt is out of date; run scripts/sync-configs.sh --to-snapshot"
    fi
    rm -f -- "$generated" "$declared"
fi

log "Checking forbidden private/runtime paths"
for forbidden in .ssh .gnupg .aws .kube google-chrome mozilla NetworkManager/system-connections com.rsplwe.bili-live-hime; do
    if find "$REPO_ROOT/configs" -path "*/$forbidden*" -print -quit | grep -q .; then
        fail "Forbidden snapshot path found: $forbidden"
    fi
 done
# The application layer mirrors $HOME, so the same rules apply to configs/apps/.
# The vendored micro syntax tree shadows micro's built-in definitions and must
# never come back.
if [[ -e "$REPO_ROOT/configs/apps/micro/.config/micro/syntax" || -e "$REPO_ROOT/configs/home/.config/micro/syntax" ]]; then
    fail "configs/.../micro/syntax must not exist (it shadows micro's built-in syntax definitions)"
fi
# Only the credential-free global routing script is portable; subscriptions,
# generated configurations, credentials and runtime state remain forbidden.
clash_rel=".local/share/io.github.clash-verge-rev.clash-verge-rev/profiles/Script.js"
clash_authored="$REPO_ROOT/configs/apps/clash-verge/$clash_rel"
clash_generated="$REPO_ROOT/configs/home/$clash_rel"
if find "$REPO_ROOT/configs" -path '*/io.github.clash-verge-rev*' ! -type d \
    ! -path "$clash_authored" ! -path "$clash_generated" -print -quit | grep -q .; then
    fail "Forbidden snapshot path found: Clash Verge private/runtime data"
fi
# .omp holds runtime state (agent db, logs, install-id, sessions) and stays forbidden,
# except the agent's secret-free frontend preferences file, which is a managed config.
if find "$REPO_ROOT/configs" -path '*/.omp/*' ! -type d \
    ! -path '*/.omp/agent/config.yml' -print -quit | grep -q .; then
    fail "Forbidden snapshot path found: .omp"
fi

for runtime_path in \
    configs/home/.timewarrior \
    configs/home/.local/share/timewarrior \
    configs/home/.config/timewarrior/data \
    configs/home/.config/mpv/cache \
    configs/home/.config/mpv/memo-history.log \
    configs/home/.config/koreader/cache \
    configs/home/.config/koreader/data \
    configs/home/.config/koreader/clipboard \
    configs/home/.config/koreader/help \
    configs/home/.config/koreader/ota \
    configs/home/.config/koreader/screenshots \
    configs/home/.config/koreader/history.lua \
    configs/home/.config/koreader/settings/wikipedia_history.lua \
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
secret_pattern="BEGIN (OPENSSH|RSA|EC|DSA) PRIVATE KEY|AKIA[0-9A-Z]{16}|Authorization:[[:space:]]*Bearer|(^|[^[:alnum:]])(password|passwd|api[_-]?key|access[_-]?token|client[_-]?secret)[[:space:]]*[:=][[:space:]]*[\"']?[^[:space:]\"']{8,}"
# Vendored uosc (mpv) ships its own public OpenSubtitles API key as a built-in
# default. Tolerate exactly that value; user overrides live in
# script-opts/uosc.conf and stay fully scanned, as does everything else.
uosc_public_key="b0rd16N0bp7DETMpO4pYZwIqmQkZbYQr"
while IFS= read -r match; do
    [[ -n "$match" ]] || continue
    fail "Potential secret: ${match#"$REPO_ROOT/"}"
done < <(grep -RInE -i --exclude='audit.sh' --exclude='PolkitWindow.qml' --exclude-dir='.git' --exclude-dir='.venv' --exclude-dir='__pycache__' --binary-files=without-match "$secret_pattern" "$REPO_ROOT" \
    | grep -vF -- "$uosc_public_key" || true)

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
