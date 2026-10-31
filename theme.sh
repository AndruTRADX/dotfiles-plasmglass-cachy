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
# Must ship a translucent panel background (PLASMA_STYLE=keep leaves it alone)
PLASMA_STYLE="${PLASMA_STYLE:-AppleDark-ALL}"
GLASS_STYLE="${GLASS_STYLE:-true}"            # true = use a see-through copy "<style>-Glass"
STYLE_BG_KEEP="${STYLE_BG_KEEP:-0}"           # % of the style's own background opacity to keep
STYLE_FOLLOWS_SCHEME="${STYLE_FOLLOWS_SCHEME:-true}"  # true = style uses your colour scheme

MODE="${1:-auto}"
[[ "$MODE" =~ ^(auto|light|dark)$ ]] || { echo "Usage: $0 [auto|light|dark]" >&2; exit 1; }

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
# The style paints its own dark background under Glass's tint; build "<style>-Glass" with it faded out.
if [[ "$GLASS_STYLE" == true && "$PLASMA_STYLE" != keep && "$PLASMA_STYLE" != *-Glass ]]; then
  root="$DATA/plasma/desktoptheme"; new="$PLASMA_STYLE-Glass"; src=""
  for f in "$root/$PLASMA_STYLE" "/usr/share/plasma/desktoptheme/$PLASMA_STYLE"; do
    if [[ -d "$f" ]]; then src="$f"; break; fi
  done
  if [[ -z "$src" ]]; then
    echo "Plasma Style '$PLASMA_STYLE' not found: skipping the see-through copy." >&2
  else
    rm -rf -- "${root:?}/$new"; mkdir -p "$root"; cp -a "$src" "$root/$new"
    [[ -f "$root/$new/metadata.desktop" ]] && sed -i -e "s/^Name=.*/Name=$new/" -e "s/^X-KDE-PluginInfo-Name=.*/X-KDE-PluginInfo-Name=$new/" "$root/$new/metadata.desktop"
    [[ -f "$root/$new/metadata.json" ]] && sed -i -e "s/\"Id\": *\"[^\"]*\"/\"Id\": \"$new\"/" -e "s/\"Name\": *\"[^\"]*\"/\"Name\": \"$new\"/" "$root/$new/metadata.json"
    n=0
    for b in translucent/widgets/panel-background translucent/dialogs/background translucent/widgets/tooltip \
             widgets/panel-background dialogs/background widgets/tooltip; do
      for f in "$root/$new/$b".svg "$root/$new/$b".svgz; do
        [[ -f "$f" ]] || continue
        if python3 "$DIR/lib/glassify.py" "$f" "$(awk -v k="$STYLE_BG_KEEP" 'BEGIN{print k/100}')" >/dev/null; then n=$((n+1)); fi
      done
    done
    if (( n == 0 )); then
      rm -rf -- "${root:?}/$new"; echo "Nothing to fade in '$PLASMA_STYLE': keeping it." >&2
    else
      rm -f "${XDG_CACHE_HOME:-$HOME/.cache}"/plasma-svgelements-"$new"* "${XDG_CACHE_HOME:-$HOME/.cache}"/plasma_theme_"$new"*.kcache
      echo "Built see-through Plasma Style '$new' ($n backgrounds)."
      PLASMA_STYLE="$new"
    fi
  fi
fi

# ---------------------------------------------------------------- apply Plasma Style
restart=0
if [[ "$PLASMA_STYLE" != keep ]]; then
  if [[ "$(kreadconfig6 --file plasmarc --group Theme --key name)" == "$PLASMA_STYLE" ]]; then
    restart=1   # already active: plasmashell caches it, restart to pick up the new files
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
todo=()
if [[ -f "$CFG/plasmashellrc" ]]; then
  while read -r id; do
    if [[ "$(kreadconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $id" --key panelOpacity)" != 2 ]]; then todo+=("$id"); fi
  done < <(sed -n 's/^\[PlasmaViews\]\[Panel \([0-9]\+\)\].*/\1/p' "$CFG/plasmashellrc" | sort -un)
fi

if (( restart || ${#todo[@]} )); then
  stop_shell
  for id in "${todo[@]}"; do
    kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $id" --key panelOpacity 2
  done
  start_shell
  if (( ${#todo[@]} )); then echo "Panels set to Translucent: ${todo[*]}"; fi
fi

# ---------------------------------------------------------------- glass
"$DIR/glass-effect.sh" "$MODE"
