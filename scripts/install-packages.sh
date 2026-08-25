#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=scripts/lib/proxy.sh
source "$SCRIPT_DIR/lib/proxy.sh"

require_non_root_user
require_command pacman
setup_proxy || true

skip_aur=0
skip_toolchains=0
while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --skip-aur) skip_aur=1 ;;
        --skip-toolchains) skip_toolchains=1 ;;
        -h|--help)
            cat <<'EOF'
Usage: scripts/install-packages.sh [--dry-run] [--skip-aur] [--skip-toolchains]

Installs the captured pacman/AUR packages, required extras, Rust toolchains,
and Bun global tools. Run as the target desktop user; sudo is requested for pacman.
EOF
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

[[ -r /etc/os-release ]] || die "Cannot identify the operating system"
# shellcheck disable=SC1091
source /etc/os-release
[[ ${ID:-} == cachyos || ${ID_LIKE:-} == *arch* ]] || die "This installer supports CachyOS/Arch only (found ${ID:-unknown})."

log "Synchronizing and upgrading the base system"
run sudo pacman -Syu --noconfirm

mapfile -t requested < <(
    {
        read_list "$REPO_ROOT/packages/pacman-explicit.txt"
        read_list "$REPO_ROOT/packages/required-extra.txt"
    } | LC_ALL=C sort -u
)

repo_packages=()
aur_packages=()
for package in "${requested[@]}"; do
    if pacman -Si -- "$package" >/dev/null 2>&1; then
        repo_packages+=("$package")
    else
        aur_packages+=("$package")
    fi
done
mapfile -t captured_aur < <(read_list "$REPO_ROOT/packages/aur-explicit.txt")
aur_packages+=("${captured_aur[@]}")

if ((${#repo_packages[@]})); then
    log "Installing ${#repo_packages[@]} repository packages"
    run sudo pacman -S --needed --noconfirm "${repo_packages[@]}"
fi

if (( ! skip_aur && ${#aur_packages[@]} )); then
    if command -v paru >/dev/null 2>&1; then
        aur_helper=paru
    elif command -v yay >/dev/null 2>&1; then
        aur_helper=yay
    else
        log "Bootstrapping paru from AUR"
        if (( DRY_RUN )); then
            print_cmd git clone https://aur.archlinux.org/paru.git /tmp/paru
            print_cmd makepkg -si --noconfirm
            aur_helper=paru
        else
            require_command git
            build_dir=$(mktemp -d)
            trap 'rm -rf -- "$build_dir"' EXIT
            git clone https://aur.archlinux.org/paru.git "$build_dir/paru"
            (cd -- "$build_dir/paru" && makepkg -si --noconfirm)
            aur_helper=paru
        fi
    fi
    mapfile -t aur_packages < <(printf '%s\n' "${aur_packages[@]}" | LC_ALL=C sort -u)
    log "Installing ${#aur_packages[@]} AUR packages with $aur_helper"
    run "$aur_helper" -S --needed --noconfirm "${aur_packages[@]}"
elif (( skip_aur )); then
    warn "AUR package installation skipped"
fi

if (( ! skip_toolchains )); then
    if command -v rustup >/dev/null 2>&1; then
        while IFS= read -r toolchain; do
            [[ -n "$toolchain" ]] || continue
            run rustup toolchain install "$toolchain"
        done < <(read_list "$REPO_ROOT/packages/rustup-toolchains.txt")
    fi

    if command -v bun >/dev/null 2>&1; then
        while IFS= read -r package; do
            [[ -n "$package" ]] || continue
            run bun add --global "$package"
        done < <(read_list "$REPO_ROOT/packages/bun-global.txt")
    fi

    # Dual OpenJDK: install the newest release as the default java/javac while
    # keeping the LTS build available for stable projects (see docs/en/jdk.md).
    if command -v archlinux-java >/dev/null 2>&1; then
        if jdk_version=$(pacman -Q jdk-openjdk 2>/dev/null | awk '{print $2}' | cut -d. -f1) && [[ -n "$jdk_version" ]]; then
            jvm_env="java-${jdk_version}-openjdk"
            if ! archlinux-java status | grep -Fq -- "${jvm_env} (default)"; then
                run sudo archlinux-java set "$jvm_env"
            fi
        fi
    fi
fi

if command -v zsh >/dev/null 2>&1; then
    current_shell=$(getent passwd "${USER:?}" | cut -d: -f7)
    desired_shell=$(command -v zsh)
    if [[ "$current_shell" != "$desired_shell" ]]; then
        run sudo chsh -s "$desired_shell" "$USER"
    fi
fi

# koreader-bin ships two desktop defects (startup crash, PDF crash); apply the
# repo's fix automatically when the package is present. Restore with
# scripts/patch-koreader-desktop.sh --restore.
if [[ -f /usr/lib/koreader/frontend/device.lua ]]; then
    if (( DRY_RUN )); then
        print_cmd "$SCRIPT_DIR/patch-koreader-desktop.sh"
    else
        "$SCRIPT_DIR/patch-koreader-desktop.sh" || \
            warn "koreader patch failed; run scripts/patch-koreader-desktop.sh manually"
    fi
fi

log "Package installation complete"
