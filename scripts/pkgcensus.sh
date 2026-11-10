#!/usr/bin/env bash
# pkgcensus — 直接安装软件统计（软件级口径）+ 精简候选清单
set -uo pipefail
export LC_ALL=C

hdr() { printf '\n%s\n%s\n' "$1" "----------------------------------------------------------------------"; }

work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT

total=$(pacman -Qq | wc -l)
explicit=$(pacman -Qeq | wc -l)
deps=$(( total - explicit ))
f_direct=$(comm -12 <(pacman -Qeq | sort) <(pacman -Qmq | sort) | wc -l)
f_all=$(pacman -Qmq | wc -l)
strict=$(pacman -Qeqt | wc -l)

pacman -Qeq | sort > "$work/explicit"
pacman -Qmq | sort > "$work/foreign"
pacman -Qkq 2>/dev/null | cut -d' ' -f1 | sort -u > "$work/broken"

# 列: name  sizeMiB  leaf  date  desc  explicit
pacman -Qi | awk '
BEGIN { RS=""; FS="\n"
        split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", m, " ")
        for (i=1; i<=12; i++) mon[m[i]]=i }
{
  name=""; size=0; req=""; date="?"; desc=""
  for (i=1; i<=NF; i++) {
    l=$i
    if (l ~ /^Name +:/)            { sub(/^Name +: /,"",l); name=l }
    else if (l ~ /^Description +:/) { sub(/^Description +: /,"",l); desc=l }
    else if (l ~ /^Installed Size/) {
      sub(/^Installed Size +: /,"",l)
      split(l,a,/[ ]+/); v=a[1]+0; u=a[2]
      if (u=="KiB") v/=1024
      else if (u=="GiB") v*=1024
      else if (u=="B") v/=1048576
      size=v
    }
    else if (l ~ /^Install Date/) {
      sub(/^Install Date +: /,"",l)
      split(l,d,/[ ]+/)
      date=sprintf("%s-%02d-%02d", d[5], mon[d[2]], d[3])
    }
    else if (l ~ /^Required By/) { sub(/^Required By +: /,"",l); req=l }
  }
  if (name != "") {
    leaf = (req=="" || req=="None") ? 1 : 0
    gsub(/\t/," ",desc)
    printf "%s\t%.1f\t%d\t%s\t%s\n", name, size, leaf, date, desc
  }
}' > "$work/rows1"

awk -F'\t' 'NR==FNR { e[$1]=1; next } { print $0 "\t" (e[$1] ? 1 : 0) }' \
  "$work/explicit" "$work/rows1" > "$work/rows"

declare -A SZ LEAF DATE IS_AUR EXPL
while IFS=$'\t' read -r n s l y d e; do SZ[$n]=$s; LEAF[$n]=$l; DATE[$n]=$y; EXPL[$n]=$e; done < "$work/rows"
while read -r n; do IS_AUR[$n]=1; done < "$work/foreign"

explicit_mib=$(awk -F'\t' '$6==1 {s+=$2} END {printf "%.0f", s}' "$work/rows")
leaf_n=$(awk -F'\t' '$3==1 && $6==1' "$work/rows" | wc -l)
leaf_mib=$(awk -F'\t' '$3==1 && $6==1 {s+=$2} END {printf "%.0f", s}' "$work/rows")

# ---------------- 归并表：显式包 -> 一个软件 ----------------
# 格式 key|类别|成员包...   类别 A=应用 T=工具/运行时 S=系统/桌面组件
declare -A SWNAME SWCAT
while IFS='|' read -r name cat pkgs; do
  case $name in ''|'#'*) continue ;; esac
  for p in $pkgs; do SWNAME[$p]="$name"; SWCAT[$p]="$cat"; done
done <<'EOF'
wechat|A|wechat-bin
feishu|A|feishu-bin
qq|A|linuxqq
zoom|A|zoom
baidunetdisk|A|baidunetdisk
firefox|A|firefox
chrome|A|google-chrome
clash-verge|A|clash-verge-rev-bin
github-desktop|A|github-desktop-bin
picgo|A|picgo-appimage
peazip|A|peazip-qt-bin
obsidian|A|obsidian
zed|A|zed
kate|A|kate
readest|A|readest
koreader|A|koreader-bin
foliate|A|foliate
sioyek|A|sioyek-git
zotero|A|zotero
intellij|A|intellij-idea-oss
steam|A|steam
lutris|A|lutris
dosbox|A|dosbox
musicfox|A|go-musicfox
obs-studio|A|obs-studio
qbittorrent|A|qbittorrent
pinta|A|pinta
gthumb|A|gthumb
imv|A|imv
mpv|A|mpv
pdfarranger|A|pdfarranger
meld|A|meld
thunar|A|thunar
wine|A|wine
mangohud+gamemode|A|mangohud lib32-mangohud gamemode lib32-gamemode
protonplus|A|protonplus
protontricks|A|protontricks
virtio-win|A|virtio-win
git|T|git
github-cli|T|github-cli
docker|T|docker docker-compose
paru|T|paru
yay|T|yay-bin
pacman-contrib|T|pacman-contrib
reflector|T|reflector
rebuild-detector|T|rebuild-detector
pkgfile|T|pkgfile
shelly|T|shelly
go|T|go
gopls|T|gopls
delve|T|delve
rust|T|rustup
python|T|python python-defusedxml python-mutagen python-packaging
uv|T|uv
pyright|T|pyright
jupyterlab|T|jupyterlab
bun|T|bun
npm|T|npm
pnpm|T|pnpm
jdk|T|jdk-openjdk jdk21-openjdk
maven|T|maven
perl|T|perl
llama.cpp|T|llama-cpp
neovim|T|neovim
vim|T|vim
micro|T|micro
nano|T|nano nano-syntax-highlighting
kitty|T|kitty
tmux|T|tmux
yazi|T|yazi
bat|T|bat
eza|T|eza
ripgrep|T|ripgrep
lazygit|T|lazygit
btop|T|btop
glances|T|glances
fastfetch|T|fastfetch
duf|T|duf
ncdu|T|ncdu
tealdeer|T|tealdeer
shellcheck|T|shellcheck
plocate|T|plocate
aria2|T|aria2
wget|T|wget
rsync|T|rsync
yt-dlp|T|yt-dlp
unzip|T|unzip
unrar|T|unrar
pv|T|pv
s-nail|T|s-nail
timew|T|timew
starship|T|starship
wlsunset|T|wlsunset
grim|T|grim
ethtool|T|ethtool
hdparm|T|hdparm
smartmontools|T|smartmontools
hwinfo|T|hwinfo
ddcutil|T|ddcutil
lsscsi|T|lsscsi
sg3_utils|T|sg3_utils
usbutils|T|usbutils
dmidecode|T|dmidecode
bind|T|bind
texlive|T|texlive-basic texlive-binextra texlive-fontsrecommended texlive-langchinese texlive-latexrecommended texlive-xetex
texinfo|T|texinfo
typst|T|typst
tinymist|T|tinymist
openssh|T|openssh
base-system|S|base base-devel diffutils less man-db man-pages which sudo logrotate lsb-release xdg-user-dirs inetutils sysfsutils realtime-privileges bash-completion
cachyos-tools|S|cachyos-hello cachyos-hooks cachyos-kernel-manager cachyos-keyring cachyos-micro-settings cachyos-mirrorlist cachyos-niri-noctalia cachyos-packageinstaller cachyos-plymouth-bootanimation cachyos-plymouth-theme cachyos-rate-mirrors cachyos-settings cachyos-snapper-support cachyos-v3-mirrorlist cachyos-v4-mirrorlist cachyos-wallpapers cachyos-zsh-config
kernel-cachyos|S|linux-cachyos linux-cachyos-headers linux-cachyos-nvidia-open
kernel-cachyos-lts|S|linux-cachyos-lts linux-cachyos-lts-headers linux-cachyos-lts-nvidia-open
firmware|S|linux-firmware alsa-firmware sof-firmware intel-ucode
nvidia|S|nvidia-utils lib32-nvidia-utils opencl-nvidia lib32-opencl-nvidia nvidia-settings libva-nvidia-driver egl-wayland
vulkan-gl|S|vulkan-icd-loader lib32-vulkan-icd-loader mesa-utils
bluetooth|S|bluez bluez-hid2hci bluez-libs bluez-obex bluez-utils
audio|S|pipewire-alsa pipewire-pulse wireplumber pavucontrol alsa-plugins alsa-utils
gstreamer|S|gst-libav gst-plugin-pipewire gst-plugins-bad gst-plugins-ugly vlc-plugins-all libdvdcss
qt-runtime|S|qt5-wayland qt6-3d qt6-5compat qt6-speech
gtk-libs|S|gtk4-layer-shell gtkmm
media-libs|S|ffmpegthumbnailer libgsf libopenraw libmupdf poppler-glib
network|S|networkmanager networkmanager-openvpn iwd wpa_supplicant modemmanager usb_modeswitch nss-mdns dnsmasq netctl xl2tpd
firewall|S|ufw ufw-extras
accountsservice|S|accountsservice
sddm|S|sddm
storage-fs|S|btrfs-progs btrfs-assistant e2fsprogs dosfstools exfatprogs f2fs-tools jfsutils nilfs-utils xfsprogs ntfs-3g ntfsprogs mtools cryptsetup device-mapper lvm2 mdadm dmraid nfs-utils fsarchiver lzip
snapper|S|snapper
boot|S|limine limine-mkinitcpio-hook limine-snapper-sync efibootmgr efitools plymouth mkinitcpio os-prober
hwdetect|S|hwdetect chwd
power|S|cpupower power-profiles-daemon intel-lpmd
fcitx5|S|fcitx5 fcitx5-chinese-addons fcitx5-configtool fcitx5-gtk fcitx5-mozc fcitx5-pinyin-zhwiki fcitx5-qt
fonts|S|awesome-terminal-fonts cantarell-fonts noto-fonts noto-fonts-emoji otf-monaspace ttf-bitstream-vera ttf-dejavu ttf-fantasque-nerd ttf-liberation ttf-lxgw-wenkai ttf-lxgw-wenkai-mono-nerd ttf-meslo-nerd ttf-opensans
kvm-qemu|S|libvirt qemu-desktop virt-manager virt-viewer edk2-ovmf swtpm
EOF

unmapped=0
: > "$work/unmapped"
while read -r p; do
  [ -n "${SWNAME[$p]:-}" ] && continue
  printf '%s\n' "$p" >> "$work/unmapped"; unmapped=$(( unmapped + 1 ))
done < "$work/explicit"

declare -A U_SZ U_NP U_LIST U_PKGS U_LEAFN U_AUR U_CAT
for p in "${!SWNAME[@]}"; do
  u=${SWNAME[$p]}
  U_CAT[$u]=${SWCAT[$p]}
  U_SZ[$u]=$(awk -v a="${U_SZ[$u]:-0}" -v b="${SZ[$p]:-0}" 'BEGIN{printf "%.1f", a+b}')
  U_NP[$u]=$(( ${U_NP[$u]:-0} + 1 ))
  U_LIST[$u]="${U_LIST[$u]:-}${U_LIST[$u]:+, }$p (${SZ[$p]:-?})"
  U_PKGS[$u]="${U_PKGS[$u]:-} $p"
  [ -n "${IS_AUR[$p]:-}" ] && U_AUR[$u]=AUR
  if [ "${LEAF[$p]:-0}" = 1 ] && [ "${EXPL[$p]:-1}" = 1 ]; then
    U_LEAFN[$u]=$(( ${U_LEAFN[$u]:-0} + 1 ))
  fi
done

cat_a=0; cat_t=0; cat_s=0
for u in "${!U_CAT[@]}"; do
  case ${U_CAT[$u]} in A) cat_a=$((cat_a+1));; T) cat_t=$((cat_t+1));; S) cat_s=$((cat_s+1));; esac
done
sw_total=$(( cat_a + cat_t + cat_s ))

rm_n=0; rm_mib=0
for u in "${!U_CAT[@]}"; do
  case ${U_CAT[$u]} in A|T) ;; *) continue ;; esac
  [ "${U_LEAFN[$u]:-0}" = "${U_NP[$u]}" ] || continue
  rm_n=$(( rm_n + 1 ))
  rm_mib=$(awk -v a="$rm_mib" -v b="${U_SZ[$u]}" 'BEGIN{printf "%.0f", a+b}')
done

print_units() { # $1 = 类别
  local cat=$1 sz u np aur all list cmd
  for u in "${!U_CAT[@]}"; do
    [ "${U_CAT[$u]}" = "$cat" ] || continue
    all=no
    [ "${U_LEAFN[$u]:-0}" = "${U_NP[$u]}" ] && all=yes
    cmd=-
    [ "$all" = yes ] && [ "$cat" != S ] && cmd="sudo pacman -Rns${U_PKGS[$u]}"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${U_SZ[$u]}" "$u" "${U_NP[$u]}" "${U_AUR[$u]:--}" "$cmd" "${U_LIST[$u]}"
  done | sort -t$'\t' -k1 -nr | while IFS=$'\t' read -r sz u np aur cmd list; do
    printf '%-22s %8s MiB %3s包 %-4s %s\n' "$u" "$sz" "$np" "$aur" "$cmd"
    [ "$np" -gt 1 ] && printf '%28s└ %s\n' '' "$list"
  done
}

# ---------------- 非 pacman 管理器 ----------------
NP=()
add_np() { NP+=("$1|$2|$3"); }

if command -v npm >/dev/null 2>&1; then
  prefix=$(npm config get prefix 2>/dev/null)
  while IFS= read -r d; do
    [ -n "$d" ] && [ -e "$d" ] || continue
    pacman -Qo "$d" >/dev/null 2>&1 && continue
    b=$(basename "$d")
    add_np npm "$b" "sudo npm rm -g $b"
  done < <(find "$prefix/lib/node_modules" -mindepth 1 -maxdepth 2 -name package.json -printf '%h\n' 2>/dev/null | sort -u)
fi

if [ -d "$HOME/.cargo/bin" ]; then
  for b in "$HOME"/.cargo/bin/*; do
    [ -e "$b" ] || continue
    pacman -Qo "$b" >/dev/null 2>&1 && continue
    add_np cargo "$(basename "$b")" "cargo uninstall $(basename "$b")"
  done
fi

if [ -d "$HOME/go/bin" ]; then
  for b in "$HOME"/go/bin/*; do
    [ -e "$b" ] || continue
    pacman -Qo "$b" >/dev/null 2>&1 && continue
    add_np go "$(basename "$b")" "rm $b"
  done
fi

if command -v uv >/dev/null 2>&1; then
  while read -r name _; do
    [ -n "$name" ] || continue
    case $name in -*) continue ;; esac
    pacman -Qo "$HOME/.local/share/uv/tools/$name" >/dev/null 2>&1 && continue
    add_np uv "$name" "uv tool uninstall $name"
  done < <(uv tool list 2>/dev/null)
fi

if command -v gem >/dev/null 2>&1; then
  IFS=: read -ra gdirs <<< "$(gem env gempath 2>/dev/null)"
  for gd in "${gdirs[@]}"; do
    [ -d "$gd/specifications" ] || continue
    for spec in "$gd"/specifications/*.gemspec; do
      [ -e "$spec" ] || continue
      pacman -Qo "$spec" >/dev/null 2>&1 && continue
      gn=$(basename "$spec" .gemspec); gn=${gn%%-[0-9]*}
      add_np gem "$gn" "gem uninstall $gn"
    done
  done
fi

if command -v python >/dev/null 2>&1 && python -m pip --version >/dev/null 2>&1; then
  while IFS='==' read -r name _; do
    [ -n "$name" ] || continue
    add_np pip "$name" "python -m pip uninstall $name"
  done < <(python -m pip list --user --format=freeze 2>/dev/null)
fi

if command -v flatpak >/dev/null 2>&1; then
  while read -r app; do
    [ -n "$app" ] || continue
    add_np flatpak "$app" "flatpak uninstall $app"
  done < <(flatpak list --app --columns=application 2>/dev/null)
fi

if command -v snap >/dev/null 2>&1; then
  while read -r name _; do
    [ -n "$name" ] || continue
    add_np snap "$name" "sudo snap remove $name"
  done < <(snap list 2>/dev/null | tail -n +2)
fi

np_count=${#NP[@]}
grand=$(( sw_total + np_count ))

# ---------------- 输出 ----------------
printf '========== 直接安装软件统计 ==========\n'
printf '%-34s %s\n' 'pacman 已安装总数' "$total"
printf '%-34s %s\n' '  直接安装的包 (pacman -Qe)' "$explicit"
printf '%-34s %s\n' '    其中 AUR/本地构建' "$f_direct"
printf '%-34s %s\n' '  依赖包 (不计入)' "$deps"
printf '%-34s %s\n' 'AUR 包总数 (含 asdeps)' "$f_all"
printf '%-34s %s\n' '直接安装 = 软件个数' "$sw_total"
printf '%-34s %s\n' '  应用 (A)' "$cat_a"
printf '%-34s %s\n' '  工具/运行时 (T)' "$cat_t"
printf '%-34s %s\n' '  系统/桌面组件 (S)' "$cat_s"
printf '%-34s %s\n' '非 pacman 管理器直接安装' "$np_count"
printf '%-34s %s\n' '合计软件' "$grand"
printf '%-34s %s\n' '可整组卸载（无反向依赖）' "$rm_n 个软件 / ${rm_mib} MiB"
printf '%-34s %s\n' '包级无反向依赖' "$leaf_n 个 / ${leaf_mib} MiB"
printf '%-34s %s\n' '严格无反向依赖 (-Qet)' "$strict"
printf '%-34s %s\n' '直接安装占用空间' "${explicit_mib} MiB"
printf '%-34s %s\n' '说明' 'paru/yay 共用 pacman 库；A/T/S 为按软件归并的口径'

hdr "A. 应用软件：${cat_a} 个（体积降序，MiB = 成员包之和）"
printf '%-22s %11s %5s %-4s %s\n' '软件' '体积' '包数' 'AUR' '整组无反向依赖时的移除命令'
print_units A

hdr "B. 工具与运行时：${cat_t} 个"
print_units T

hdr "C. 系统/桌面组件：${cat_s} 组（安装器与驱动基线，勿轻易删除）"
print_units S

hdr 'D. 同类多装（每组 >=2，仅提示）'
CATS=(
  '内核::^linux-(cachyos|lts|zen|mainline)(-lts)?(-headers|-nvidia-open)?$'
  'JDK/Java::^(jdk[0-9]*-openjdk|jre[0-9]*-openjdk|maven|intellij-idea-oss)$'
  '浏览器::^(firefox|google-chrome|chromium|brave-bin|vivaldi|qutebrowser)$'
  '编辑器/IDE::^(zed|kate|neovim|vim|micro|emacs|code|code-oss|obsidian)$'
  '电子书::^(readest|koreader-bin|foliate|sioyek-git|zotero|libmupdf|calibre)$'
  '通讯/网盘::^(feishu-bin|wechat-bin|linuxqq|zoom|baidunetdisk|telegram-desktop|discord)$'
  'TeX/排版::^texlive-|^texinfo$|^typst$|^tinymist$'
  '字体::^ttf-|^otf-|^noto-fonts|^awesome-terminal-fonts$|^cantarell-fonts$'
  '虚拟化/Wine::^(wine|virtio-win|libvirt|qemu-desktop|virt-manager|virt-viewer|edk2-ovmf|swtpm|lib32-wine)$'
  '游戏::^(steam|lutris|mangohud|lib32-mangohud|gamemode|lib32-gamemode|dosbox|protontricks|protonplus)$'
  '终端::^(kitty|alacritty|ghostty|wezterm|foot|konsole|tmux|zellij)$'
  'JS 运行时::^(nodejs|npm|pnpm|bun|deno)$'
  'Python::^(python|uv|jupyterlab|pyright|conda)$'
  'Rust/Go::^(rustup|go|gopls|delve)$'
)
for entry in "${CATS[@]}"; do
  label=${entry%%::*}; re=${entry##*::}
  members=(); gsum=0
  while IFS= read -r n; do
    [[ $n =~ $re ]] || continue
    members+=("$n")
    gsum=$(awk -v a="$gsum" -v b="${SZ[$n]:-0}" 'BEGIN{printf "%.1f", a+b}')
  done < "$work/explicit"
  [ "${#members[@]}" -ge 2 ] || continue
  printf '\n[%s] %s 个，共 %s MiB\n' "$label" "${#members[@]}" "$gsum"
  for n in "${members[@]}"; do
    printf '    %-28s %8s MiB  %s\n' "$n" "${SZ[$n]:-?}" "${DATE[$n]:-?}"
  done
done

hdr 'E. AUR / 本地构建包'
while read -r n; do
  reason=$([ "${EXPL[$n]:-0}" = 1 ] && echo '直接' || echo '依赖(asdeps)')
  printf '  %-28s %8s MiB  %-14s %s  sudo pacman -Rns %s\n' \
    "$n" "${SZ[$n]:-?}" "$reason" "${DATE[$n]:-?}" "$n"
done < "$work/foreign"

hdr 'F. 缺文件的包（重装或移除）'
if [ -s "$work/broken" ]; then sed 's/^/  /' "$work/broken"; else echo '  (无)'; fi

hdr 'G. 非 pacman 管理器清单'
if [ "$np_count" -eq 0 ]; then
  echo '  (无用户安装)'
else
  for it in "${NP[@]}"; do
    IFS='|' read -r mgr name cmd <<< "$it"
    printf '  [%-7s] %-24s %s\n' "$mgr" "$name" "$cmd"
  done
fi

if command -v docker >/dev/null 2>&1 && timeout 10 docker info >/dev/null 2>&1; then
  hdr 'H. Docker 镜像（不计入软件总数）'
  docker images --format '{{.Repository}}:{{.Tag}}|{{.Size}}' | sort |
  while IFS='|' read -r img s; do printf '  %-50s %s\n' "$img" "$s"; done
fi

hdr 'I. 大块缓存（可选清理，非软件）'
for d in "$HOME/.cargo/registry" "$HOME/.local/share/uv" "$HOME/go"; do
  [ -d "$d" ] && printf '  %-40s %s\n' "$d" "$(du -sh "$d" 2>/dev/null | cut -f1)"
done

if [ "$unmapped" -gt 0 ]; then
  hdr '! 未归并的显式包（需补充归并表）'
  sed 's/^/  /' "$work/unmapped"
fi
