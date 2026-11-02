#!/usr/bin/env bash
# Checks that the rice is healthy: glass effect, Plasma Styles, theme state, services, system tweaks.
# Read-only. Usage: ./doctor.sh   (exit code = number of failed checks)
set -uo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"

fails=0 warns=0
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$*"; fails=$((fails+1)); }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; warns=$((warns+1)); }
check() {  # check <description> <hint if it fails> <command...>
  local desc="$1" hint="$2"; shift 2
  if "$@" >/dev/null 2>&1; then ok "$desc"; else bad "$desc  ->  $hint"; fi
}
section() { printf '\n\033[1;35m%s\033[0m\n' "$*"; }
kread() { kreadconfig6 --file "$1" --group "$2" --key "$3"; }

section "Liquid glass"
check "kwin-effects-glass-git installed" "./install.sh" pacman -Q kwin-effects-glass-git
check "Glass enabled, KWin blur off" "./glass-effect.sh" \
  test "$(kread kwinrc Plugins glassEnabled)/$(kread kwinrc Plugins blurEnabled)" = "true/false"
if [[ -n "$QDBUS" ]]; then
  check "Glass effect loaded in KWin" "fixglass, then log out and back in" \
    test "$("$QDBUS" org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded glass)" = true
else
  warn "qdbus6 not found: cannot ask KWin whether Glass is loaded"
fi
mode="$(detect_mode)"
check "Glass tint matches the colour scheme ($mode)" "./glass-effect.sh" \
  test "$(cat "$GLASS_STATE" 2>/dev/null)" = "$mode"

section "Plasma Style"
for s in "$LIGHT_STYLE" "$DARK_STYLE"; do
  check "Style $s-Glass built" "./theme.sh $([[ $s == "$LIGHT_STYLE" ]] && echo light || echo dark)" \
    test -f "$DATA/plasma/desktoptheme/$s-Glass/.glass-stamp"
  check "$s-Glass uses metadata.json" "rm -rf $DATA/plasma/desktoptheme/$s-Glass; ./theme.sh" \
    test ! -e "$DATA/plasma/desktoptheme/$s-Glass/metadata.desktop"
done
want="$([[ "$mode" == light ]] && echo "$LIGHT_STYLE" || echo "$DARK_STYLE")-Glass"
cur="$(kread plasmarc Theme name)"
if [[ "$cur" == "$want" ]]; then ok "Active style is $cur"
else warn "Active style is '$cur', expected '$want' for $mode mode  ->  ./theme.sh $mode"; fi

section "User services"
check "liquid-glass-follow.path active" "systemctl --user enable --now liquid-glass-follow.path" \
  systemctl --user is-active liquid-glass-follow.path
check "glass-check.service enabled" "systemctl --user enable glass-check.service" \
  systemctl --user is-enabled glass-check.service
check "paru-cache-clean.timer active" "systemctl --user enable --now paru-cache-clean.timer" \
  systemctl --user is-active paru-cache-clean.timer
check "mpris-proxy.service active" "systemctl --user enable --now mpris-proxy.service" \
  systemctl --user is-active mpris-proxy.service
failed_user="$(systemctl --user --failed --no-legend --plain | awk '{print $1}' | xargs)"
if [[ -z "$failed_user" ]]; then ok "No failed user units"; else bad "Failed user units: $failed_user"; fi

section "System"
check "Pacman hooks installed" "sudo ./system/setup.sh" \
  test -f /etc/pacman.d/hooks/kwin-glass-rebuild.hook -a -f /etc/pacman.d/hooks/openlinkhub-reenable.hook
check "scx_loader running" "sudo ./system/setup.sh" systemctl is-active scx_loader.service
check "btrfs scrub timer active" "sudo systemctl enable --now btrfs-scrub@-.timer" \
  systemctl is-active btrfs-scrub@-.timer
check "paccache.timer active" "sudo systemctl enable --now paccache.timer" systemctl is-active paccache.timer
check "Wi-Fi regulatory domain pinned (/etc/iw-regdomain)" "sudo ./system/setup.sh" \
  grep -q '^COUNTRY=..' /etc/iw-regdomain
check "uinput module loaded" "sudo modprobe uinput" test -e /dev/uinput
check "$USER in the i2c group" "sudo ./system/setup.sh, then log out and back in" \
  bash -c 'id -nG | tr " " "\n" | grep -qx i2c'
if grep -qx 'it8[0-9]*' /sys/class/hwmon/hwmon*/name 2>/dev/null; then ok "Motherboard sensors (it87): fans and voltages visible"
else warn "No motherboard sensors (it87)  ->  sudo ./system/setup.sh"; fi
olh=/var/lib/openlinkhub/config.json
if [[ -r "$olh" ]]; then
  bus="$(python3 -c 'import json,sys; c=json.load(open(sys.argv[1])); print(c["memorySmBus"] if c.get("memory") else "")' "$olh" 2>/dev/null)"
  if [[ -z "$bus" ]]; then warn "OpenLinkHub RAM RGB off  ->  sudo ./system/setup.sh"
  elif grep -q '^SMBus I801' "/sys/bus/i2c/devices/$bus/name" 2>/dev/null; then ok "OpenLinkHub RAM RGB on $bus"
  else bad "OpenLinkHub RAM RGB points at $bus, which is not the SMBus any more  ->  sudo ./system/setup.sh"; fi
fi
failed_sys="$(systemctl --failed --no-legend --plain | awk '{print $1}' | xargs)"
if [[ -z "$failed_sys" ]]; then ok "No failed system units"; else bad "Failed system units: $failed_sys"; fi

section "Display"
if command -v kscreen-doctor >/dev/null; then
  while read -r out vrr; do
    if [[ "$vrr" == Never ]]; then warn "$out: VRR off  ->  kscreen-doctor output.$out.vrrpolicy.automatic"
    else ok "$out: VRR $vrr"; fi
  done < <(kscreen-doctor -o 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' |
           awk '/^Output:/ { out = $3 } /Vrr:/ { print out, $2 }')
fi

printf '\n%s failed, %s warnings\n' "$fails" "$warns"
exit "$fails"
