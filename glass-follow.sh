#!/usr/bin/env bash
# Keeps the liquid glass tint (and GTK apps' light/dark + icons) in sync with the current
# Global Theme / colour scheme.
# Run by liquid-glass-follow.path whenever ~/.config/kdeglobals changes; only acts when the
# light/dark mode actually changed, so ordinary settings changes cost nothing.
set -euo pipefail
DIR="$(dirname "$(readlink -f "$0")")"
source "$DIR/lib/common.sh"

sleep 1   # a Global Theme writes kdeglobals several times: let it finish
take_lock # if theme.sh is running, wait for it (its glass-effect.sh run saves the mode)

# A Global Theme may point at a "<style>-Glass" copy this machine has not built yet
style="$(kreadconfig6 --file plasmarc --group Theme --key name)"
if [[ "$style" == *-Glass && ! -d "$DATA/plasma/desktoptheme/$style" ]]; then
  build_glass_style "$style"
  if (( GLASS_REBUILT )); then stop_shell; start_shell; fi
fi

mode="$(detect_mode)"
if [[ "$(cat "$GLASS_STATE" 2>/dev/null)" != "$mode" ]]; then
  "$DIR/glass-effect.sh" "$mode"
  sync_gtk "$mode"
fi
