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

# Upstream repos are pinned to a known-good commit so a fresh install looks the same as this one.
# Bump the hash (git ls-remote <url> HEAD) after checking a newer version works.
MACTAHOE_ICONS_URL=https://github.com/vinceliuice/MacTahoe-icon-theme.git
MACTAHOE_ICONS_REV=839848b9a8a38a92a6936e30c4abe35cc6f2546d
WII_SOUNDS_URL=https://github.com/TheBearOfJare/Wii-System-Sounds-for-KDE-Plasma.git
WII_SOUNDS_REV=23a840e29784257a70735f788e731a6194f5fc06
MACTAHOE_KDE_URL=https://github.com/vinceliuice/MacTahoe-kde.git
MACTAHOE_KDE_REV=cbf6a1f71b591d143184855d62f6272ce533e7c3

clone_pinned() {  # $1 = url, $2 = commit, $3 = destination
  git init -q "$3"
  git -C "$3" fetch -q --depth 1 "$1" "$2"
  git -C "$3" checkout -q FETCH_HEAD
}
