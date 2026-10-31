#!/usr/bin/env bash
# Keeps the liquid glass tint in sync with the current Global Theme / colour scheme.
# Run by liquid-glass-follow.path whenever ~/.config/kdeglobals changes; only acts when the
# light/dark mode actually changed, so ordinary settings changes cost nothing.
set -euo pipefail
DIR="$(dirname "$(readlink -f "$0")")"
source "$DIR/lib/common.sh"

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/liquid-glass/mode"
sleep 1   # a Global Theme writes kdeglobals several times: let it finish

mode="$(detect_mode)"
if [[ "$(cat "$STATE" 2>/dev/null)" != "$mode" ]]; then
  "$DIR/glass-effect.sh" "$mode"
  mkdir -p "$(dirname "$STATE")"
  echo "$mode" > "$STATE"
fi
