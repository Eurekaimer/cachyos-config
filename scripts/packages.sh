#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Single entry point for the local package tier list.
#
# ~/cachyos-packages.txt is the editable surface: `## core` and `## pending`.
# packages/core.txt is the repository copy that audit.sh and the restore flow
# read. `export` regenerates the former from the live system, `apply` writes the
# `## core` section back to the latter.

core_list="$REPO_ROOT/packages/core.txt"
full_profile="$REPO_ROOT/packages/profiles/full.txt"
tiers_file=${PACKAGES_TIERS_FILE:-$HOME/cachyos-packages.txt}
action=""
force=0
sync_profile=0
run_audit=1

usage() {
    cat <<'EOF'
Usage: scripts/packages.sh <export|apply> [options]

Maintains the local software tier list in ~/cachyos-packages.txt:
  ## core     packages never uninstalled, must stay in the full profile
  ## pending  packages whose tier is still undecided

Commands:
  export    Rebuild the tier list from the live system (pacman -Qqe)
  apply     Write the `## core` section back to packages/core.txt

Options:
  --path PATH       Tier list location (default: $HOME/cachyos-packages.txt)
  --force           Overwrite an existing tier list on export
  --sync-profile    Append core packages missing from packages/profiles/full.txt
  --no-audit        Skip scripts/audit.sh after apply
  -h, --help        Show this help

export skips dependency-installed packages and every package from the core
repository or a cachyos* repository, so kernels, firmware and distro tooling
never reach the list.
EOF
}

# Package name -> repository from the sync databases; no network access.
# CachyOS repositories come first in `pacman -Sl`, matching mirror priority.
repo_map() {
    LANG=C pacman -Sl | awk '{print $2"\t"$1}' | awk -F'\t' '!seen[$1]++'
}

# Explicit installs minus system repositories. Foreign packages have no
# repository entry and are always user-managed.
user_packages() {
    local map
    map=$(mktemp)
    repo_map >"$map"
    pacman -Qqe | LC_ALL=C sort -u | awk -F'\t' '
        NR == FNR { repo[$1] = $2; next }
        {
            r = ($1 in repo) ? repo[$1] : ""
            if (r == "core" || r ~ /^cachyos/) next
            print $1
        }
    ' "$map" -
    rm -f -- "$map"
}

# "<section>\t<package>" for every entry; comments and blanks stripped.
section_stream() {
    awk '
        /^##[[:space:]]/ {
            s = $0
            sub(/^##[[:space:]]+/, "", s)
            sub(/[[:space:]]+$/, "", s)
            if (s != "core" && s != "pending") {
                printf "error: unknown section \"%s\"\n", s > "/dev/stderr"
                exit 2
            }
            cur = s
            next
        }
        {
            line = $0
            sub(/[[:space:]]*#.*$/, "", line)
            sub(/^[[:space:]]+/, "", line)
            sub(/[[:space:]]+$/, "", line)
            if (line == "") next
            if (cur == "") {
                printf "error: %s appears before any section header\n", line > "/dev/stderr"
                exit 2
            }
            print cur "\t" line
        }
    ' "$tiers_file"
}

cmd_export() {
    local tmp users pending core_names
    if [[ -e "$tiers_file" ]] && (( force == 0 )); then
        die "$tiers_file already exists; rerun with --force to rebuild it from the live system"
    fi
    tmp=$(mktemp "$tiers_file.XXXXXX")
    users=$(mktemp)
    pending=$(mktemp)
    core_names=$(mktemp)
    read_list "$core_list" | LC_ALL=C sort -u >"$core_names"
    user_packages >"$users"
    LC_ALL=C comm -23 "$users" "$core_names" >"$pending"
    {
        printf '# cachyos-packages.txt — 本机显式安装软件的分级清单\n'
        printf '#\n'
        printf '# 重新生成：./scripts/packages.sh export --force\n'
        printf '# 写回仓库：./scripts/packages.sh apply\n'
        printf '#\n'
        printf '# `## core`    = 不得卸载，且必须留在 packages/profiles/full.txt\n'
        printf '# `## pending` = 分级未定，不代表可以删除\n'
        printf '#\n'
        printf '# 每行一个包名，行尾可用 `# 备注` 说明；空行与注释忽略。\n'
        printf '# 已排除：依赖包、core 仓库与所有 cachyos* 仓库的系统包。\n'
        printf '\n'
        printf '## core\n'
        cat "$core_names"
        printf '\n## pending\n'
        cat "$pending"
        printf '\n'
    } >"$tmp"
    mv -- "$tmp" "$tiers_file"
    log "Wrote $tiers_file: core $(wc -l <"$core_names"), pending $(wc -l <"$pending")"
    rm -f -- "$users" "$pending" "$core_names"
}

cmd_apply() {
    local names missing tmp
    [[ -f "$tiers_file" ]] || die "No tier list at $tiers_file; run scripts/packages.sh export first"
    names=$(mktemp)
    missing=$(mktemp)
    section_stream | awk -F'\t' '$1 == "core" { print $2 }' | LC_ALL=C sort -u >"$names"
    [[ -s "$names" ]] || die "## core section of $tiers_file is empty; refusing to write an empty core list"
    LC_ALL=C comm -23 "$names" <(read_list "$full_profile" | LC_ALL=C sort -u) >"$missing"
    if [[ -s "$missing" ]]; then
        if (( sync_profile )); then
            warn "Appending packages missing from the full profile: $(paste -sd' ' "$missing")"
            { printf '\n'; cat "$missing"; } >>"$full_profile"
        else
            die "Core packages missing from packages/profiles/full.txt: $(paste -sd' ' "$missing"); rerun with --sync-profile or add them there"
        fi
    fi
    tmp=$(mktemp "$core_list.XXXXXX")
    {
        printf '# 核心软件：未经用户明确调整分级，不得卸载或从完整恢复档移除。\n'
        cat "$names"
    } >"$tmp"
    mv -- "$tmp" "$core_list"
    log "Wrote $(wc -l <"$names") core packages to packages/core.txt"
    rm -f -- "$names" "$missing"
    if (( run_audit )); then
        log "Running scripts/audit.sh"
        bash "$REPO_ROOT/scripts/audit.sh"
    fi
}

require_command pacman
while (($#)); do
    case "$1" in
        export|apply)
            [[ -z "$action" ]] || die "Only one command may be given (got '$action' and '$1')"
            action=$1
            ;;
        --path)
            shift
            [[ $# -gt 0 ]] || die "--path needs a value"
            tiers_file=$1
            ;;
        --force) force=1 ;;
        --sync-profile) sync_profile=1 ;;
        --no-audit) run_audit=0 ;;
        -h|--help) usage; exit 0 ;;
        -*) die "Unknown option: $1" ;;
        *) die "Unknown argument: $1" ;;
    esac
    shift
done

[[ -n "$action" ]] || { usage >&2; exit 2; }

case "$action" in
    export) cmd_export ;;
    apply) cmd_apply ;;
esac
