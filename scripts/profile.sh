#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=scripts/lib/profile.sh
source "$SCRIPT_DIR/lib/profile.sh"

# Single entry point for package profiles. A profile is one install input:
# packages/profiles/<NAME>.txt. `use` remembers a choice that
# scripts/install-packages.sh picks up when neither --profile nor
# PACKAGE_PROFILE is given.

profiles_root="$REPO_ROOT/packages/profiles"

usage() {
    cat <<'EOF'
Usage: scripts/profile.sh <list|show|diff|use> [NAME...]

Package profiles decide WHICH packages a machine installs. They are the only
install input besides packages/required-extra.txt.

Commands:
  list            List every profile with its package count
  show NAME       Print a profile in full (comments and groups included)
  diff A B        Package sets: only in A, only in B, and the shared count
  use NAME        Remember NAME as this machine's default profile

Installed by scripts/install-packages.sh. Resolution order for the default:
  --profile NAME > PACKAGE_PROFILE > `profile.sh use` > full

Options:
  -h, --help      Show this help
EOF
}

# Package names only: comments, group headers and blanks removed.
profile_packages() {
    local file=$1
    sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$file" | LC_ALL=C sort -u
}

profile_path() {
    local name=$1
    local file="$profiles_root/$name.txt"
    [[ -r "$file" ]] || die "Unknown package profile '$name' (expected $file)"
    printf '%s\n' "$file"
}

cmd_list() {
    local file name count
    shopt -s nullglob
    local files=("$profiles_root"/*.txt)
    shopt -u nullglob
    ((${#files[@]})) || die "No profiles found under $profiles_root"
    for file in "${files[@]}"; do
        name=$(basename -- "$file" .txt)
        count=$(profile_packages "$file" | wc -l)
        printf '%-12s %3d packages\n' "$name" "$count"
    done
}

cmd_show() {
    local name=$1
    local file
    file=$(profile_path "$name")
    cat -- "$file"
}

cmd_diff() {
    local a=$1
    local b=$2
    local only_a
    local only_b
    local shared
    local file_a file_b
    file_a=$(profile_path "$a")
    file_b=$(profile_path "$b")
    only_a=$(mktemp); only_b=$(mktemp)
    profile_packages "$file_a" >"$only_a"
    profile_packages "$file_b" >"$only_b"
    # comm must collate exactly like the LC_ALL=C sort in profile_packages.
    shared=$(LC_ALL=C comm -12 "$only_a" "$only_b" | wc -l)
    log "Only in $a (not installed by $b): $(LC_ALL=C comm -23 "$only_a" "$only_b" | wc -l)"
    LC_ALL=C comm -23 "$only_a" "$only_b" | sed 's/^/  - /'
    log "Only in $b (not installed by $a): $(LC_ALL=C comm -13 "$only_a" "$only_b" | wc -l)"
    LC_ALL=C comm -13 "$only_a" "$only_b" | sed 's/^/  + /'
    log "Shared by both: $shared"
    rm -f -- "$only_a" "$only_b"
}

cmd_use() {
    local name=$1 state_file
    profile_path "$name" >/dev/null
    state_file=$(profile_state_file)
    mkdir -p -- "$(dirname -- "$state_file")"
    printf '%s\n' "$name" >"$state_file"
    log "Default profile set to '$name' ($state_file)"
}

action=""
names=()
while (($#)); do
    case "$1" in
        list|show|diff|use)
            [[ -z "$action" ]] || die "Only one command may be given (got '$action' and '$1')"
            action=$1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*) die "Unknown option: $1" ;;
        *) names+=("$1") ;;
    esac
    shift
done

[[ -n "$action" ]] || { usage >&2; exit 2; }

case "$action" in
    list) cmd_list ;;
    show)
        ((${#names[@]} == 1)) || { usage >&2; exit 2; }
        cmd_show "${names[0]}"
        ;;
    diff)
        ((${#names[@]} == 2)) || { usage >&2; exit 2; }
        cmd_diff "${names[0]}" "${names[1]}"
        ;;
    use)
        ((${#names[@]} == 1)) || { usage >&2; exit 2; }
        cmd_use "${names[0]}"
        ;;
esac
