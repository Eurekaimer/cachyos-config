#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# The single entry point for every optional module under modules/. A module is
# a directory holding install.sh, uninstall.sh, README.md and an optional
# installed-check file (one absolute path per line; $HOME is expanded).

modules_root="$REPO_ROOT/modules"

usage() {
    cat <<'EOF'
Usage: scripts/module.sh <list|status|install|uninstall> [MODULE] [--dry-run]

Optional modules live in modules/<name>/ and are independent of the generic
snapshot restore: they install personal helpers, services or plugins that only
some machines need.

Commands:
  list                 List every module and whether it is installed
  status MODULE        Show the existence of each installed-check path
  install MODULE       Run modules/<MODULE>/install.sh
  uninstall MODULE     Run modules/<MODULE>/uninstall.sh

Options:
  --dry-run            Print the command that would run; change nothing
  -h, --help           Show this help

Installed state comes from modules/<MODULE>/installed-check, which lists
absolute paths (with $HOME) that must all exist after a successful install.
A module without that file reports "unknown".
EOF
}

# Expand the $HOME placeholder written in installed-check files. Parameter
# expansion only: installed-check content never runs as code.
expand_check_path() {
    printf '%s\n' "${1//\$HOME/$HOME}"
}

require_module() {
    local name=$1
    [[ -n "$name" ]] || { usage >&2; exit 2; }
    module_dir="$modules_root/$name"
    [[ -d "$module_dir" ]] || die "Unknown module: $name"
    [[ -f "$module_dir/install.sh" ]] || die "Module '$name' has no install.sh; see docs/agents/TASKS.md"
}

# Print the installed state of one module: installed / partial / missing /
# unknown (no installed-check file).
module_state() {
    local name=$1
    local dir="$modules_root/$name"
    local check
    local path
    local total=0
    local present=0
    check="$dir/installed-check"
    if [[ ! -f "$check" ]]; then
        printf 'unknown\n'
        return 0
    fi
    while IFS= read -r path; do
        [[ -n "$path" && "$path" != \#* ]] || continue
        total=$((total + 1))
        path=$(expand_check_path "$path")
        [[ -e "$path" || -L "$path" ]] && present=$((present + 1))
    done <"$check"
    if (( total == 0 )); then
        printf 'unknown\n'
    elif (( present == total )); then
        printf 'installed\n'
    elif (( present == 0 )); then
        printf 'missing\n'
    else
        printf 'partial\n'
    fi
}

cmd_list() {
    local dir name state conforming=0
    for dir in "$modules_root"/*/; do
        [[ -d "$dir" ]] || continue
        name=$(basename -- "$dir")
        if [[ ! -f "$dir/install.sh" ]]; then
            warn "Skipping non-conforming module directory: modules/$name (no install.sh)"
            continue
        fi
        conforming=$((conforming + 1))
        state=$(module_state "$name")
        printf '%-24s %s\n' "$name" "$state"
    done
    (( conforming )) || warn "No modules with install.sh found under modules/"
}

cmd_status() {
    local name=$1
    local check="$modules_root/$1/installed-check"
    local path
    if [[ ! -f "$check" ]]; then
        printf 'unknown: %s has no installed-check file\n' "$name"
        return 0
    fi
    while IFS= read -r path; do
        [[ -n "$path" && "$path" != \#* ]] || continue
        path=$(expand_check_path "$path")
        if [[ -e "$path" || -L "$path" ]]; then
            printf 'present  %s\n' "$path"
        else
            printf 'missing  %s\n' "$path"
        fi
    done <"$check"
}

cmd_run() {
    local action=$1
    local name=$2
    local dry_run=$3
    require_module "$name"
    require_non_root_user
    local script="$module_dir/$action.sh"
    [[ -f "$script" ]] || die "Module '$name' has no $action.sh"

    # Module-specific flags after MODULE (e.g. koreader --force) are forwarded
    # verbatim. --dry-run is forwarded only when the module's own parser knows
    # it (which yields a per-step preview); otherwise module.sh prints the
    # command and does not run the module at all.
    local args=("${extra_args[@]}")
    if (( dry_run )); then
        if grep -q -- '--dry-run)' "$script"; then
            args+=(--dry-run)
        else
            print_cmd "$script" ${args[@]+"${args[@]}"}
            return 0
        fi
    fi
    "$script" ${args[@]+"${args[@]}"}
    log "$name $action complete"
}

action=""
module_name=""
dry_run=0
extra_args=()
while (($#)); do
    case "$1" in
        list|status|install|uninstall)
            [[ -z "$action" ]] || die "Only one command may be given (got '$action' and '$1')"
            action=$1
            ;;
        --dry-run) dry_run=1 ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            # Anything else belongs to the module's own install.sh/uninstall.sh.
            [[ -n "$module_name" ]] || die "Unknown option: $1 (it must follow a module name to be forwarded)"
            extra_args+=("$1")
            ;;
        *)
            [[ -z "$module_name" ]] || die "Only one module may be given (got '$module_name' and '$1')"
            module_name=$1
            ;;
    esac
    shift
done

[[ -n "$action" ]] || { usage >&2; exit 2; }

case "$action" in
    list) cmd_list ;;
    status)
        [[ -n "$module_name" ]] || { usage >&2; exit 2; }
        require_module "$module_name"
        cmd_status "$module_name"
        ;;
    install|uninstall)
        [[ -n "$module_name" ]] || { usage >&2; exit 2; }
        cmd_run "$action" "$module_name" "$dry_run"
        ;;
esac
