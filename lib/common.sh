# Shared helpers. Load with: source "$(dirname "$0")/lib/common.sh"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
QDBUS="$(command -v qdbus6 || command -v qdbus-qt6 || command -v qdbus || true)"

reconfigure_kwin() {
  if [[ -z "$QDBUS" ]]; then echo "qdbus not found: log out and back in to apply." >&2; return; fi
  "$QDBUS" org.kde.KWin /KWin reconfigure >/dev/null
  "$QDBUS" org.kde.KWin /Effects org.kde.kwin.Effects.reconfigureEffect glass >/dev/null || true
}

# plasmashell writes its panel config back on exit, so stop it before editing those files
SHELL_UNIT=0
stop_shell() {
  if systemctl --user --quiet is-active plasma-plasmashell.service; then
    systemctl --user stop plasma-plasmashell.service; SHELL_UNIT=1
  else
    kquitapp6 plasmashell >/dev/null 2>&1 || true
  fi
}
start_shell() {
  if (( SHELL_UNIT )); then systemctl --user start plasma-plasmashell.service
  else setsid -f plasmashell >/dev/null 2>&1
  fi
}

# light if the active window background is bright
detect_mode() {
  local bg r g b
  bg="$(kreadconfig6 --file kdeglobals --group Colors:Window --key BackgroundNormal)"
  [[ -n "$bg" ]] || { echo light; return; }   # nothing written yet = Plasma default (light)
  IFS=, read -r r g b _ <<<"$bg"
  if (( (299*r + 587*g + 114*b) / 1000 > 128 )); then echo light; else echo dark; fi
}
