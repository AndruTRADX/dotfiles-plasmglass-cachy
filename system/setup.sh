#!/usr/bin/env bash
# System-level tweaks (needs root). Safe to run more than once.
# Usage: sudo ./system/setup.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo: sudo $0" >&2; exit 1; }
cd "$(dirname "$(readlink -f "$0")")"
USER_NAME="${SUDO_USER:?run through sudo so the target user is known}"

say() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }

say "Pacman hooks: warn when KWin is upgraded (glass needs 'fixglass'); re-enable OpenLinkHub after its upgrades"
install -Dm644 pacman-hooks/kwin-glass-rebuild.hook /etc/pacman.d/hooks/kwin-glass-rebuild.hook
install -Dm644 pacman-hooks/openlinkhub-reenable.hook /etc/pacman.d/hooks/openlinkhub-reenable.hook

say "OpenLinkHub (Corsair fans/RGB, web UI at http://127.0.0.1:27003)"
if pacman -Q openlinkhub &>/dev/null; then
  # Its udev rule only applies to devices plugged in after install: re-apply it to the
  # Corsair devices already connected, or the service can't open them until a reboot.
  udevadm control --reload
  udevadm trigger --subsystem-match=usb --attr-match=idVendor=1b1c
  udevadm trigger --subsystem-match=hidraw
  udevadm settle

  # RAM RGB: OpenLinkHub talks to the DIMMs' RGB controllers over the Intel SMBus (i2c-dev).
  # It needs the i2c group, the right bus, and the SKU (the BIOS's SPD Write Disable hides it).
  smbus="$(grep -l '^SMBus I801' /sys/bus/i2c/devices/i2c-*/name 2>/dev/null | head -1 | xargs -r dirname | xargs -r basename)"
  sku="$(udevadm info /sys/devices/virtual/dmi/id 2>/dev/null | sed -n 's/^E: MEMORY_DEVICE_[0-9]*_PART_NUMBER=\(CM[A-Z0-9]*\)$/\1/p' | head -1)"
  ddr="$(udevadm info /sys/devices/virtual/dmi/id 2>/dev/null | sed -n 's/^E: MEMORY_DEVICE_[0-9]*_LOCATOR=DDR\([45]\).*/\1/p' | head -1)"
  if [[ -n "$smbus" && -n "$sku" && -f /var/lib/openlinkhub/config.json ]]; then
    modprobe i2c-dev
    echo i2c-dev > /etc/modules-load.d/i2c-dev.conf
    usermod -aG i2c openlinkhub
    systemctl stop openlinkhub.service
    python3 openlinkhub-memory.py /var/lib/openlinkhub/config.json "$smbus" "$sku" "${ddr:-5}"
    echo "RAM RGB: $sku on $smbus (DDR${ddr:-5})"
  fi
  systemctl enable openlinkhub.service
  systemctl restart openlinkhub.service
fi

say "Motherboard sensors (fans, voltages, temperatures) through it87"
# ITE Super I/O chips (Gigabyte boards) are claimed by ACPI, so it87 needs ignore_resource_conflict.
# Only kept when the driver actually finds a chip.
if modprobe it87 ignore_resource_conflict=1 2>/dev/null && grep -qx 'it8[0-9]*' /sys/class/hwmon/hwmon*/name; then
  echo "options it87 ignore_resource_conflict=1" > /etc/modprobe.d/it87.conf
  echo it87 > /etc/modules-load.d/it87.conf
  echo "it87 loaded: $(grep -hx 'it8[0-9]*' /sys/class/hwmon/hwmon*/name | xargs)"
else
  modprobe -r it87 2>/dev/null || true
  echo "No ITE sensor chip found: skipping."
fi

say "sched-ext scheduler: scx_lavd (lower latency for desktop and games)"
if command -v scx_loader &>/dev/null; then
  install -Dm644 scx_loader.toml /etc/scx_loader.toml
  systemctl enable scx_loader.service
  systemctl restart scx_loader.service
fi

say "Wi-Fi regulatory domain fixed to the country of the timezone (iw-set-regdomain fails if tzdata is mid-upgrade)"
if [[ ! -s /etc/iw-regdomain ]]; then
  zone="$(timedatectl show -P Timezone 2>/dev/null || true)"
  country="${COUNTRY:-$(awk -v z="$zone" '$3 == z { print $1; exit }' /usr/share/zoneinfo/zone.tab 2>/dev/null)}"
  if [[ -n "$country" ]]; then
    echo "COUNTRY=$country" > /etc/iw-regdomain
    systemctl reset-failed cachyos-iw-set-regdomain.service 2>/dev/null || true
  else
    echo "Could not tell the country from timezone '$zone': run with COUNTRY=XX to set it." >&2
  fi
fi

say "Monthly btrfs scrub of / (detects silent data corruption)"
systemctl enable --now btrfs-scrub@-.timer

say "Weekly pacman cache cleanup (keeps the last 3 versions of each package)"
pacman -S --needed --noconfirm pacman-contrib
systemctl enable --now paccache.timer

say "Load uinput at boot (Bluetooth headphone media buttons / AVRCP)"
echo uinput > /etc/modules-load.d/uinput.conf
modprobe uinput

say "Let bluetoothd open /dev/uinput (OpenLinkHub changes its owner)"
install -Dm644 bluetooth-uinput.conf /etc/systemd/system/bluetooth.service.d/uinput.conf
systemctl daemon-reload
systemctl restart bluetooth

say "Add $USER_NAME to the i2c group (monitor brightness over DDC/CI)"
usermod -aG i2c "$USER_NAME"

echo
echo "Done. Log out and back in for the i2c group to take effect."
