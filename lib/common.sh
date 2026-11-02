# Shared helpers. Load with: source "$(dirname "$0")/lib/common.sh"
LIB="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/liquid-glass"
GLASS_STATE="$STATE_DIR/mode"   # light|dark tint last written to kwinrc by glass-effect.sh
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

# Serialise theme.sh / glass-follow.sh: both write kwinrc and the GTK settings.ini files.
# The lock is held on fd 9 until the script exits.
take_lock() {
  mkdir -p "$STATE_DIR"
  exec 9>"$STATE_DIR/lock"
  flock -w 120 9 || { echo "Another theme change is still running; giving up." >&2; exit 1; }
}

# Plasma Style for each mode, and how build_glass_style fades it
LIGHT_STYLE="${LIGHT_STYLE:-MacTahoe-Light}"
DARK_STYLE="${DARK_STYLE:-AppleDark-ALL}"
STYLE_BG_KEEP="${STYLE_BG_KEEP:-0}"                   # % of the style's own background opacity to keep
STYLE_FOLLOWS_SCHEME="${STYLE_FOLLOWS_SCHEME:-true}"  # true = drop the style's "colors" so it uses your scheme

# Builds "<style>-Glass": a copy of a Plasma Style with its own backgrounds faded out, so Glass's tint shows.
# Rebuilt only when the source, glassify.py or the settings above changed (stamp file).
# Sets GLASS_NAME (style to apply) and GLASS_REBUILT (1 = files changed, plasmashell must restart).
build_glass_style() {  # $1 = source style name
  local style="${1%-Glass}" root="$DATA/plasma/desktoptheme" src="" new f b n=0 stamp
  new="$style-Glass"; GLASS_NAME="$new"; GLASS_REBUILT=0
  for f in "$root/$style" "/usr/share/plasma/desktoptheme/$style"; do
    if [[ -d "$f" ]]; then src="$f"; break; fi
  done
  if [[ -z "$src" ]]; then
    echo "Plasma Style '$style' not found: skipping the see-through copy." >&2; GLASS_NAME="$style"; return
  fi
  stamp="$( { printf '%s\n' "$src" "$STYLE_BG_KEEP" "$STYLE_FOLLOWS_SCHEME"; cat "$LIB/glassify.py" "$LIB/metadata-json.py"
              find "$src" -type f -printf '%T@ %s %P\n' | sort; } | sha1sum | cut -d' ' -f1)"
  [[ -f "$root/$new/.glass-stamp" && "$(<"$root/$new/.glass-stamp")" == "$stamp" ]] && return

  rm -rf -- "${root:?}/$new"; mkdir -p "$root"; cp -a "$src" "$root/$new"
  python3 "$LIB/metadata-json.py" "$root/$new" "$new"   # Id/Name; metadata.desktop -> metadata.json
  if [[ "$STYLE_FOLLOWS_SCHEME" == true && -f "$root/$new/colors" ]]; then mv -f "$root/$new/colors" "$root/$new/colors.bak"; fi
  for b in translucent/widgets/panel-background translucent/dialogs/background translucent/widgets/tooltip \
           widgets/panel-background dialogs/background widgets/tooltip; do
    for f in "$root/$new/$b".svg "$root/$new/$b".svgz; do
      [[ -f "$f" ]] || continue
      if python3 "$LIB/glassify.py" "$f" "$(awk -v k="$STYLE_BG_KEEP" 'BEGIN{print k/100}')" >/dev/null; then n=$((n+1)); fi
    done
  done
  if (( n == 0 )); then
    rm -rf -- "${root:?}/$new"; echo "Nothing to fade in '$style': keeping it." >&2; GLASS_NAME="$style"; return
  fi
  rm -f "${XDG_CACHE_HOME:-$HOME/.cache}"/plasma-svgelements-"$new"* "${XDG_CACHE_HOME:-$HOME/.cache}"/plasma_theme_"$new"*.kcache
  echo "$stamp" > "$root/$new/.glass-stamp"
  echo "Built see-through Plasma Style '$new' ($n backgrounds)." >&2
  GLASS_REBUILT=1
}
