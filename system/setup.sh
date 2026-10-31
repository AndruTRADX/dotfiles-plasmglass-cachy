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
