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

# Make GTK apps follow Plasma: dark/light preference + the current KDE icon theme.
# KDE's own GTK sync can leave these stale after switching Global Themes back and forth.
sync_gtk() {  # $1 = light|dark
  local icons dark=false scheme=prefer-light f
  [[ "$1" == dark ]] && { dark=true; scheme=prefer-dark; }
  icons="$(kreadconfig6 --file kdeglobals --group Icons --key Theme)"
  for f in "$CFG/gtk-3.0/settings.ini" "$CFG/gtk-4.0/settings.ini"; do
    [[ -f "$f" ]] || continue
    sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$dark/" "$f"
    if [[ -n "$icons" ]]; then sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$icons/" "$f"; fi
  done
  if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme "$scheme" || true
    if [[ -n "$icons" ]]; then gsettings set org.gnome.desktop.interface icon-theme "$icons" || true; fi
  fi
}
