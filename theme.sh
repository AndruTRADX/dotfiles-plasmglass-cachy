#!/usr/bin/env bash
# Light/dark theme: Liquid Glass Global Theme + see-through Plasma Style + translucent panels, then the glass preset.
# Usage: ./theme.sh [auto|light|dark]   (auto = keep the current colour scheme)
#
# Colour schemes live in home/.local/share/color-schemes/ (installed by install.sh).
# Saves a backup first (./backup.sh restore to undo).
set -euo pipefail
DIR="$(dirname "$(readlink -f "$0")")"
source "$DIR/lib/common.sh"

LIGHT_SCHEME="${LIGHT_SCHEME:-AppleLightPurple}"
DARK_SCHEME="${DARK_SCHEME:-AppleDarkPurple}"
# Plasma Style per mode (LIGHT_STYLE / DARK_STYLE in common.sh); PLASMA_STYLE=<name> forces one, keep leaves it alone
PLASMA_STYLE="${PLASMA_STYLE:-auto}"
GLASS_STYLE="${GLASS_STYLE:-true}"            # true = use a see-through copy "<style>-Glass"

MODE="${1:-auto}"
[[ "$MODE" =~ ^(auto|light|dark)$ ]] || { echo "Usage: $0 [auto|light|dark]" >&2; exit 1; }

# Shared with glass-follow.sh: it waits for us, then sees the saved mode and does nothing
take_lock

"$DIR/backup.sh" auto >/dev/null

# ---------------------------------------------------------------- colour scheme
if [[ "$MODE" == auto ]]; then
  MODE="$(detect_mode)"
else
  # Our Global Theme for this mode (colours, icons, decoration, splash). -a never touches the panel layout.
  lnf="com.github.andrutradx.liquidglass-$MODE"
  if [[ "$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage)" != "$lnf" ]]; then
    plasma-apply-lookandfeel -a "$lnf" >/dev/null || echo "Global Theme '$lnf' not found: run install.sh" >&2
  fi
  want="$([[ "$MODE" == light ]] && echo "$LIGHT_SCHEME" || echo "$DARK_SCHEME")"
  if [[ "$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)" != "$want" ]]; then
    plasma-apply-colorscheme "$want"
  fi
  if [[ -n "$(kreadconfig6 --file kdeglobals --group General --key AccentColor)" ]]; then
    echo "Note: your Accent color overrides the scheme's hover/selection colours" \
         "(System Settings > Colors > Accent color: From current color scheme)." >&2
  fi
fi

# ---------------------------------------------------------------- see-through Plasma Style
[[ "$PLASMA_STYLE" != auto ]] || PLASMA_STYLE="$([[ "$MODE" == light ]] && echo "$LIGHT_STYLE" || echo "$DARK_STYLE")"
rebuilt=0
if [[ "$GLASS_STYLE" == true && "$PLASMA_STYLE" != keep ]]; then
  build_glass_style "$PLASMA_STYLE"; PLASMA_STYLE="$GLASS_NAME"; rebuilt=$GLASS_REBUILT
fi

# ---------------------------------------------------------------- apply Plasma Style
restart=0
if [[ "$PLASMA_STYLE" != keep ]]; then
  if [[ "$(kreadconfig6 --file plasmarc --group Theme --key name)" == "$PLASMA_STYLE" ]]; then
    restart=$rebuilt   # already active: plasmashell caches it, restart only if its files changed
  else
    plasma-apply-desktoptheme "$PLASMA_STYLE" >/dev/null \
      || echo "Plasma Style '$PLASMA_STYLE' not found (plasma-apply-desktoptheme --list-themes)" >&2
  fi
fi

# A Plasma Style without a "colors" file follows the system colour scheme
style_dir="$DATA/plasma/desktoptheme/$(kreadconfig6 --file plasmarc --group Theme --key name)"
if [[ "$STYLE_FOLLOWS_SCHEME" == true && -f "$style_dir/colors" ]]; then
  mv -f "$style_dir/colors" "$style_dir/colors.bak"; restart=1
elif [[ "$STYLE_FOLLOWS_SCHEME" != true && -f "$style_dir/colors.bak" && ! -f "$style_dir/colors" ]]; then
  mv "$style_dir/colors.bak" "$style_dir/colors"; restart=1
fi

# ---------------------------------------------------------------- panels: Translucent
# plasmashellrc panelOpacity: 0/missing = Adaptive, 1 = Opaque, 2 = Translucent
# Only real panels (org.kde.panel containments): plasmashellrc keeps entries for removed ones
panel_ids() {
  awk -F= '/^\[Containments\]\[[0-9]+\]$/ { id = $0; gsub(/[^0-9]/, "", id); next }
           /^\[/ { id = "" }
           id != "" && $1 == "plugin" && $2 == "org.kde.panel" { print id }' \
    "$CFG/plasma-org.kde.plasma.desktop-appletsrc" 2>/dev/null | sort -un
}
todo=()
if [[ -f "$CFG/plasmashellrc" ]]; then
  while read -r id; do
    if [[ "$(kreadconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $id" --key panelOpacity)" != 2 ]]; then todo+=("$id"); fi
  done < <(panel_ids)
fi

if (( restart || ${#todo[@]} )); then
  stop_shell
  for id in "${todo[@]}"; do
    kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $id" --key panelOpacity 2
  done
  start_shell
  if (( ${#todo[@]} )); then echo "Panels set to Translucent: ${todo[*]}"; fi
fi

# ---------------------------------------------------------------- glass + GTK apps
"$DIR/glass-effect.sh" "$MODE"
sync_gtk "$MODE"
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/liquid-glass"
echo "$MODE" > "${XDG_STATE_HOME:-$HOME/.local/state}/liquid-glass/mode"   # so glass-follow.sh does not redo it
