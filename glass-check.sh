#!/usr/bin/env bash
# Run at login by glass-check.service: if the Glass KWin effect is enabled but did not load
# (kwin-effects-glass-git was built against an older KWin), show a notification with a button
# that runs fixglass in Konsole.
set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"

[[ "$(kreadconfig6 --file kwinrc --group Plugins --key glassEnabled)" == true ]] || exit 0
[[ -n "$QDBUS" ]] || exit 0

# KWin loads effects shortly after the session starts: give it up to 30 s
for _ in $(seq 30); do
  [[ "$("$QDBUS" org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded glass 2>/dev/null)" == true ]] && exit 0
  sleep 1
done

kwin="$(pacman -Q kwin 2>/dev/null | cut -d' ' -f2)"
action="$(notify-send --app-name="Liquid glass" --icon=dialog-warning --urgency=critical \
  --action=fix="Rebuild now" \
  "The glass effect did not load" \
  "kwin-effects-glass needs a rebuild for KWin ${kwin:-?}. Run fixglass, then log out and back in." || true)"
if [[ "$action" == fix ]]; then
  setsid -f konsole -e fish -c 'fixglass; read -P "Press Enter to close "' >/dev/null 2>&1
fi
