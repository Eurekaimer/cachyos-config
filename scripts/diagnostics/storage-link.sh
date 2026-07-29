#!/usr/bin/env bash
set -Eeuo pipefail

device=${1:-/dev/sda}
[[ -b "$device" ]] || { printf 'Not a block device: %s\n' "$device" >&2; exit 2; }

base=$(lsblk -ndo PKNAME "$device")
[[ -n "$base" ]] || base=${device##*/}
[[ -e "/sys/class/block/$base" ]] || { printf 'No sysfs block device for %s\n' "$device" >&2; exit 2; }

sys_path=$(readlink -f "/sys/class/block/$base")
node=$sys_path
usb_device=
usb_interface=
while [[ "$node" != / && "$node" != /sys ]]; do
    [[ -z "$usb_device" && -f "$node/speed" && -f "$node/idVendor" ]] && usb_device=$node
    [[ -z "$usb_interface" && -f "$node/bInterfaceClass" && -L "$node/driver" ]] && usb_interface=$node
    node=${node%/*}
done

printf 'device: %s\n' "$device"
printf 'model: %s\n' "$(<"/sys/class/block/$base/device/model")"
printf 'scheduler: %s\n' "$(<"/sys/class/block/$base/queue/scheduler")"
printf 'queue_depth: %s\n' "$(<"/sys/class/block/$base/device/queue_depth")"

if [[ -z "$usb_device" ]]; then
    printf 'transport: not a USB block device\n'
    exit 0
fi

speed=$(<"$usb_device/speed")
vendor=$(<"$usb_device/idVendor")
product=$(<"$usb_device/idProduct")
driver=unknown
[[ -n "$usb_interface" ]] && driver=$(basename -- "$(readlink -f "$usb_interface/driver")")

printf 'usb_id: %s:%s\n' "$vendor" "$product"
printf 'usb_speed: %s Mbit/s\n' "$speed"
printf 'usb_driver: %s\n' "$driver"

if (( speed <= 480 )); then
    cat >&2 <<'EOF'
FAIL: the drive negotiated USB 2.0 High-Speed (480 Mbit/s).
Use a USB 3.x/10 Gbit/s port and a cable with SuperSpeed data lanes, then rerun.
Expected after reconnect: 5000 or 10000 Mbit/s and normally the uas driver.
EOF
    exit 1
fi

if [[ "$driver" != uas ]]; then
    printf 'WARNING: SuperSpeed is active but the device is using %s rather than uas.\n' "$driver" >&2
    exit 1
fi

printf 'OK: SuperSpeed and UAS are active.\n'
