#!/usr/bin/env bash
# Woodshed / Reactivities "liquid glass" preset for kwin-effects-glass
# Reproduces the web effect: edge lens + chromatic aberration + 1px white border + frosted body.
# Usage:
#   ./glass-effect.sh [auto|light|dark]   apply the preset (default: auto)
#   ./glass-effect.sh backup [label]      snapshot your current desktop config
#   ./glass-effect.sh restore [label]     restore a snapshot (default: newest)
#   ./glass-effect.sh list                list snapshots
#
#   auto        glass tint follows the colour scheme you already have
#   light/dark  also switches the COLOUR SCHEME only (plasma-apply-colorscheme), never the
#               Global Theme. Uses AppleLightPurple / AppleDarkPurple, bundled.
#
# Every apply first saves an automatic snapshot (last 10 kept), so `restore` undoes it,
# and sets every panel to Translucent (Adaptive turns them solid on maximized windows).
# Snapshots are shared with glass-apple.sh, so `restore` can also go back to that preset.
# Every apply also switches to PLASMA_STYLE (default AppleDark-ALL) so panels can be translucent,
# and (STYLE_FOLLOWS_SCHEME) makes it use your colour scheme so the panels match the menus.
#
# Panels and Plasma popups get an extra dark tint from KWin's Background Contrast effect, so by default
# (CONTRAST_EFFECT=off) it is switched off; CONTRAST_EFFECT=on re-enables it. `restore` brings back kwinrc.
GLASS_STYLE="${GLASS_STYLE:-true}"            # true = use a copy of PLASMA_STYLE ("<name>-Glass") whose panel/popup/tooltip backgrounds are see-through, so only Glass's tint remains
STYLE_BG_KEEP="${STYLE_BG_KEEP:-0}"           # % of the Plasma Style's own background opacity to keep (0 = none)
#
# Plasma Style backgrounds add their own tint under Glass's, so GLASS_STYLE=true (default) applies a
# see-through copy "<PLASMA_STYLE>-Glass" (STYLE_BG_KEEP=% of the original opacity to keep; GLASS_STYLE=false = off).
#
# Note: the effect's plugin id is "glass", but its settings live in
# ~/.config/kwinrc under the group [Effect-blurplus] (inherited from the kcfg).

set -euo pipefail
shopt -s nullglob

# Colour schemes for light/dark -- list yours with: plasma-apply-colorscheme --list-schemes
# AppleLightPurple / AppleDarkPurple are installed from this script if missing
LIGHT_SCHEME="${LIGHT_SCHEME:-AppleLightPurple}"
DARK_SCHEME="${DARK_SCHEME:-AppleDarkPurple}"

# Plasma Style -- must ship a translucent panel background, otherwise Plasma greys out the panel
# Opacity option and draws panels solid (e.g. "darkly"), so Glass has nothing to show through.
# List yours with: plasma-apply-desktoptheme --list-themes   (PLASMA_STYLE=keep leaves it alone)
PLASMA_STYLE="${PLASMA_STYLE:-AppleDark-ALL}"
# true = the Plasma Style ignores its own colours and follows your colour scheme, so panels get the
# same colour as the menus: its "colors" file is renamed to colors.bak (false puts it back).
# Only touches styles installed in your home folder, never system-wide ones.
STYLE_FOLLOWS_SCHEME="${STYLE_FOLLOWS_SCHEME:-true}"

CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/glass-apple/backups"
KEEP_AUTO=10
# What this script touches + everything a Global Theme switch can overwrite
FILES=(
  kwinrc kdeglobals plasmarc kcminputrc ksplashrc kscreenlockerrc
  plasma-org.kde.plasma.desktop-appletsrc plasmashellrc
  auroraerc breezerc klassyrc darklyrc lightlyrc
  Kvantum/kvantum.kvconfig
)
QDBUS="$(command -v qdbus6 || command -v qdbus-qt6 || command -v qdbus || true)"

w() { kwriteconfig6 --file kwinrc --group Effect-blurplus --key "$1" "$2"; }

reconfigure_kwin() {
  if [[ -z "$QDBUS" ]]; then echo "qdbus not found: log out and back in to apply." >&2; return; fi
  "$QDBUS" org.kde.KWin /KWin reconfigure >/dev/null
  "$QDBUS" org.kde.KWin /Effects org.kde.kwin.Effects.reconfigureEffect glass >/dev/null || true
}

# ---------------------------------------------------------------- backups
backup() {  # $1 = optional label
  local label="${1//[^A-Za-z0-9_-]/_}" dest f
  dest="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)${label:+-$label}"
  mkdir -p "$dest"
  for f in "${FILES[@]}"; do
    [[ -f "$CFG/$f" ]] || continue
    mkdir -p "$dest/$(dirname "$f")"
    cp -a "$CFG/$f" "$dest/$f"
  done
  echo "Backup saved: $dest"
}

prune_auto() {
  local auto=("$BACKUP_ROOT"/*-auto/)
  if (( ${#auto[@]} > KEEP_AUTO )); then
    rm -rf -- "${auto[@]:0:${#auto[@]}-KEEP_AUTO}"
  fi
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

restore() {  # $1 = backup name or label (default: newest)
  local matches=("$BACKUP_ROOT"/*"${1:-}"*/) src f
  if (( ${#matches[@]} == 0 )); then echo "No backup matching '${1:-}' in $BACKUP_ROOT" >&2; exit 1; fi
  src="${matches[-1]%/}"

  stop_shell
  for f in "${FILES[@]}"; do
    [[ -f "$src/$f" ]] || continue
    mkdir -p "$CFG/$(dirname "$f")"
    cp -a "$src/$f" "$CFG/$f"
  done
  start_shell
  reconfigure_kwin
  echo "Restored: $src"
  echo "Log out and back in so open apps pick up the restored style, colours and cursor."
}

list_backups() { local b; for b in "$BACKUP_ROOT"/*/; do basename "$b"; done; }

# ---------------------------------------------------------------- light/dark
detect_mode() {  # light if the active window background is bright
  local bg r g b
  bg="$(kreadconfig6 --file kdeglobals --group Colors:Window --key BackgroundNormal)"
  [[ -n "$bg" ]] || { echo light; return; }   # nothing written yet = Plasma default (light)
  IFS=, read -r r g b _ <<<"$bg"
  if (( (299*r + 587*g + 114*b) / 1000 > 128 )); then echo light; else echo dark; fi
}

set_scheme() {
  local want="$DARK_SCHEME"
  [[ "$1" == light ]] && want="$LIGHT_SCHEME"
  case "$want" in AppleDarkPurple|AppleLightPurple) install_scheme "$want" ;; esac
  if [[ "$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)" != "$want" ]]; then
    plasma-apply-colorscheme "$want"
  fi
  # A custom or wallpaper Accent color is stored here and recolours hover/selection
  if [[ -n "$(kreadconfig6 --file kdeglobals --group General --key AccentColor)" ]]; then
    echo "Note: your Accent color overrides the scheme's hover/selection colours. To use the scheme's:" >&2
    echo "      System Settings > Colors & Themes > Colors > Accent color: From current color scheme" >&2
  fi
}

set_plasma_style() {
  [[ "$PLASMA_STYLE" == keep ]] && return 0
  if [[ "$(kreadconfig6 --file plasmarc --group Theme --key name)" != "$PLASMA_STYLE" ]]; then
    plasma-apply-desktoptheme "$PLASMA_STYLE" >/dev/null \
      || echo "Plasma Style '$PLASMA_STYLE' not found -- list yours with: plasma-apply-desktoptheme --list-themes" >&2
  fi
}

# A Plasma Style without a "colors" file follows the system colour scheme
style_follow_scheme() {
  local style dir
  style="$(kreadconfig6 --file plasmarc --group Theme --key name)"
  dir="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/desktoptheme/$style"
  [[ -n "$style" && -d "$dir" ]] || return 0   # default or system-wide style: leave it alone
  if [[ "$STYLE_FOLLOWS_SCHEME" == true && -f "$dir/colors" ]]; then
    mv -f "$dir/colors" "$dir/colors.bak"
    echo "Plasma Style '$style' now follows your colour scheme."
  elif [[ "$STYLE_FOLLOWS_SCHEME" != true && -f "$dir/colors.bak" && ! -f "$dir/colors" ]]; then
    mv "$dir/colors.bak" "$dir/colors"
    echo "Plasma Style '$style' uses its own colours again."
  else
    return 0
  fi
  stop_shell
  start_shell
}

# ---------------------------------------------------------------- see-through Plasma Style
# The Plasma Style paints its own dark background under Glass's tint (the floating dock uses a ~68% grey),
# so panels end up darker than menus. Build "<style>-Glass": a copy with those fills faded out. Mask, margin
# and shadow elements are left alone so KWin still knows each panel's shape. Needs python3.
make_glass_style() {
  [[ "$GLASS_STYLE" == true && "$PLASMA_STYLE" != keep && "$PLASMA_STYLE" != *-Glass ]] || return 0
  command -v python3 >/dev/null || { echo "python3 not found: skipping the see-through Plasma Style." >&2; return 0; }
  local base="$PLASMA_STYLE" new="${PLASMA_STYLE}-Glass" root src="" b f n=0 helper
  root="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/desktoptheme"
  for f in "$root/$base" "/usr/share/plasma/desktoptheme/$base"; do
    [[ -d "$f" ]] && { src="$f"; break; }
  done
  [[ -n "$src" ]] || { echo "Plasma Style '$base' not found: skipping the see-through copy." >&2; return 0; }

  rm -rf -- "${root:?}/$new"
  mkdir -p "$root"
  cp -a "$src" "$root/$new"
  [[ -f "$root/$new/metadata.desktop" ]] && sed -i -e "s/^Name=.*/Name=$new/" -e "s/^X-KDE-PluginInfo-Name=.*/X-KDE-PluginInfo-Name=$new/" "$root/$new/metadata.desktop"
  [[ -f "$root/$new/metadata.json" ]] && sed -i -e "s/\"Id\": *\"[^\"]*\"/\"Id\": \"$new\"/" -e "s/\"Name\": *\"[^\"]*\"/\"Name\": \"$new\"/" "$root/$new/metadata.json"

  helper="$(mktemp)"
  cat > "$helper" <<'PY'
#!/usr/bin/env python3
"""Make the background of a Plasma Style SVG(Z) see-through, keeping margins/shadows/masks.
usage: glassify.py FILE FACTOR   (FACTOR 0..1 = share of the original opacity to keep)
exit 0 = file rewritten, 3 = skipped (nothing to change / no usable mask)"""
import gzip, re, sys
import xml.etree.ElementTree as ET

for p, u in {"": "http://www.w3.org/2000/svg",
             "inkscape": "http://www.inkscape.org/namespaces/inkscape",
             "sodipodi": "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd",
             "xlink": "http://www.w3.org/1999/xlink",
             "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
             "cc": "http://creativecommons.org/ns#",
             "dc": "http://purl.org/dc/elements/1.1/"}.items():
    ET.register_namespace(p, u)

path, factor = sys.argv[1], float(sys.argv[2])
raw = open(path, "rb").read()
gz = raw[:2] == b"\x1f\x8b"
root = ET.fromstring(gzip.decompress(raw) if gz else raw)

TINT = re.compile(r"^(?:[a-z]+-)*(?:center|top|bottom|left|right|topleft|topright|bottomleft|bottomright)$")
SKIP = ("mask", "hint", "shadow")
SHAPES = {"rect", "path", "circle", "ellipse", "polygon"}
local = lambda t: t.rsplit("}", 1)[-1]

def set_opacity(el):
    d = dict(kv.split(":", 1) for kv in el.get("style", "").split(";") if ":" in kv)
    if d.get("fill", "").strip() == "none":
        return False
    old = float(d.get("opacity", "1"))
    d["opacity"] = f"{old * factor:.4f}"
    el.set("style", ";".join(f"{k}:{v}" for k, v in d.items()))
    return True

changed = 0
def walk(el, in_tint, protected):
    global changed
    i = el.get("id", "")
    protected = protected or any(s in i for s in SKIP)
    in_tint = in_tint or bool(TINT.match(i))
    if in_tint and not protected and local(el.tag) in SHAPES and set_opacity(el):
        changed += 1
    for c in el:
        walk(c, in_tint, protected)
walk(root, False, False)

# Plasma looks for masks named "mask-<prefix>center" (e.g. mask-floating-center), not "<prefix>-mask-center".
# Without one it derives the panel shape from the background's alpha, which is empty once faded: PanelView
# then falls back to the whole window and, because an empty mask never "changes", never refreshes it when the
# panel resizes (a fit-content dock stops growing its click/blur area). So give every faded frame an opaque mask.
parent = {c: p for p in root.iter() for c in p}
ids = {e.get("id"): e for e in root.iter() if e.get("id")}
had_mask = any("mask" in i for i in ids) or "floating-center" in ids
CENTER = re.compile(r"^((?:[a-z]+-)*)center$")
for i, e in list(ids.items()):
    m = CENTER.match(i)
    if not m or any(s in i for s in SKIP) or local(e.tag) not in SHAPES:
        continue
    mid = f"mask-{m.group(1)}center"
    if mid in ids:
        continue
    attrs = {k: e.get(k) for k in ("x", "y", "width", "height", "transform") if e.get(k)}
    mk = ET.Element(e.tag, attrs)
    mk.set("id", mid)
    mk.set("style", "fill:#000000;fill-opacity:1;opacity:1;stroke:none")
    parent[e].insert(list(parent[e]).index(e) + 1, mk)
    ids[mid] = mk

if not changed or not had_mask:
    sys.exit(3)
out = ET.tostring(root, encoding="utf-8", xml_declaration=True)
open(path, "wb").write(gzip.compress(out) if gz else out)
print(changed)
PY
  for b in translucent/widgets/panel-background translucent/dialogs/background translucent/widgets/tooltip \
           widgets/panel-background dialogs/background widgets/tooltip; do
    for f in "$root/$new/$b".svg "$root/$new/$b".svgz; do
      [[ -f "$f" ]] || continue
      if python3 "$helper" "$f" "$(awk -v k="$STYLE_BG_KEEP" 'BEGIN{print k/100}')" >/dev/null; then n=$((n+1))
      else echo "Left as is (no mask element to keep its shape): ${f#"$root/$new/"}" >&2; fi
    done
  done
  rm -f "$helper"
  if (( n == 0 )); then rm -rf -- "${root:?}/$new"; echo "Nothing to fade in '$base': keeping it." >&2; return 0; fi

  rm -f "${XDG_CACHE_HOME:-$HOME/.cache}"/plasma-svgelements-"$new"* "${XDG_CACHE_HOME:-$HOME/.cache}"/plasma_theme_"$new"*.kcache
  echo "Built see-through Plasma Style '$new' ($n backgrounds)."
  PLASMA_STYLE="$new"
  # an already-active style is cached by plasmashell: restart it to pick up the new files
  if [[ "$(kreadconfig6 --file plasmarc --group Theme --key name)" == "$new" ]]; then stop_shell; start_shell; fi
}

# ---------------------------------------------------------------- panels
# plasmashellrc [PlasmaViews][Panel N] panelOpacity: 0/missing = Adaptive, 1 = Opaque, 2 = Translucent
panels_translucent() {
  local ids=() todo=() id
  [[ -f "$CFG/plasmashellrc" ]] || return 0
  mapfile -t ids < <(sed -n 's/^\[PlasmaViews\]\[Panel \([0-9]\+\)\].*/\1/p' "$CFG/plasmashellrc" | sort -un)
  for id in "${ids[@]}"; do
    if [[ "$(kreadconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $id" --key panelOpacity)" != 2 ]]; then
      todo+=("$id")
    fi
  done
  (( ${#todo[@]} )) || return 0
  stop_shell
  for id in "${todo[@]}"; do
    kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $id" --key panelOpacity 2
  done
  start_shell
  echo "Panels set to Translucent: ${todo[*]}"
}

# ---------------------------------------------------------------- preset
# Tunables -- override from the shell, e.g.  LENS_BEVEL=9 ./glass-effect.sh dark
LENS_EDGE="${LENS_EDGE:-2}"             # x10 px: width of the refracting band at the edge
LENS_POW="${LENS_POW:-1}"               # /2: falloff steepness (higher = thinner, sharper edge)
LENS_BEVEL="${LENS_BEVEL:-15}"          # /10: edge lens strength (5..15)
LENS_STRENGTH="${LENS_STRENGTH:-12}"    # /20: index of refraction - 1
LENS_CURVE="${LENS_CURVE:-14}"           # /2: bends the lens sideways towards the corners (0..20), like the web map
FRINGING="${FRINGING:-16}"              # /20: chromatic aberration (0..20)
RIM_WIDTH="${RIM_WIDTH:-10}"            # /10 px
RIM_LIGHT="${RIM_LIGHT:-5}"             # /10: white border thickness, light mode
RIM_DARK="${RIM_DARK:-7}"               # /10: white border thickness, dark mode
BLUR_STRENGTH="${BLUR_STRENGTH:-2}"     # 1 = almost none (sigma ~0.8 px, iOS-like), 2 = a hint, 3 = frosted (sigma ~5 px)
BLUR_FINETUNE="${BLUR_FINETUNE:-8}"     # 0..10, fine adjustment within the strength
TINT_LIGHT="${TINT_LIGHT:-#B0FFFFFF}"   # #AARRGGBB
TINT_DARK="${TINT_DARK:-#A018181B}"
TINT_MIN="${TINT_MIN:-60}"              # adaptive tint: % of the tint kept over a similar backdrop
BODY_REFRACTION="${BODY_REFRACTION:-true}"   # true = refract the whole surface, not just the edge (crystal-ball look)
LENS_WINDOWS="${LENS_WINDOWS:-true}"         # true = also bend the backdrop behind normal windows, not just menus/dock/OSD
CONTRAST_EFFECT="${CONTRAST_EFFECT:-off}"   # off = disable KWin's Background Contrast, which darkens/desaturates the backdrop of Plasma panels and popups on top of Glass's tint (on = leave it enabled)

apply_glass() {
  local MODE="$1"

  # ---- make sure only Glass is doing the blurring ----
  kwriteconfig6 --file kwinrc --group Plugins --key glassEnabled true
  kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled false
  kwriteconfig6 --file kwinrc --group Plugins --key translucencyEnabled false
  kwriteconfig6 --file kwinrc --group Plugins --key contrastEnabled "$([[ "$CONTRAST_EFFECT" == off ]] && echo false || echo true)"

  # ---- blur: almost none, like iOS Liquid Glass (clarity comes from the lens + adaptive tint) ----
  # KWin reads strength as (value - 1): 1 = a single half-res pass, sigma ~0.8 px at finetune 3
  w BlurStrength "$BLUR_STRENGTH"
  w BlurFinetune "$BLUR_FINETUNE"
  w DecorationBlurStrength "$BLUR_STRENGTH"
  w DockBlurStrength "$BLUR_STRENGTH"
  w DockBlurFinetune "$BLUR_FINETUNE"
  w NoiseStrength 0
  w DecorationNoiseStrength 0
  w DockNoiseStrength 0
  w BlurSaturationCompensation false

  # ---- color ----
  w OklabSaturation true
  w Contrast 1.0
  if [[ "$MODE" == "light" ]]; then
    w Brightness 1.05
    w Saturation 1.3
    w TintColor "$TINT_LIGHT"
  else
    w Brightness 1.0
    w Saturation 1.3
    w TintColor "$TINT_DARK"
  fi
  # Adaptive tint: frost gets stronger where the backdrop contrasts with it (legibility)
  w AutoTintAlpha true
  w AutoTintAlphaMin "$TINT_MIN"
  w AutoTintAlphaMax 100
  for k in ExcludeDocks ExcludeDecorations ExcludeTooltips ExcludeMenus ExcludeOSD; do w "$k" false; done

  # ---- refraction: thin, strong lens at the edge with visible chromatic aberration ----
  # The "curve" term is what makes straight lines bow near the edges, like looking through bevelled glass.
  w PhysicallyBasedRefraction true
  w RefractionStrength "$LENS_STRENGTH"
  w RefractionEdgeSize "$LENS_EDGE"
  w RefractionNormalPow "$LENS_POW"
  w RefractionBevelIntensity "$LENS_BEVEL"
  w RefractionOffsetStrength "$LENS_CURVE"   # lens also bends sideways toward the corners: lines curve like the web
  w RefractionRGBFringing "$FRINGING"
  w BodyRefraction "$BODY_REFRACTION"
  # Floating surfaces only by default; LENS_WINDOWS=true also bends the backdrop behind windows
  w RefractionExcludeWindows "$([[ "$LENS_WINDOWS" == true ]] && echo false || echo true)"
  w RefractionExcludeTooltips true
  w RefractionExcludeDocks false
  w RefractionExcludeMenus false
  w RefractionExcludeOSD false

  # ---- rim: thin white border, lit top-left / bottom-right (the web's inset highlight) ----
  # Thickness = RIM_WIDTH x RIM_x /100 px. 0.3 px was invisible, 0.84 px was too wide; ~0.4-0.5 px between.
  w RimSpecular true
  w RimWidth "$RIM_WIDTH"
  if [[ "$MODE" == "light" ]]; then
    w RimSpecularScale "$RIM_LIGHT"
  else
    w RimSpecularScale "$RIM_DARK"
  fi
  w RimAdaptToRefraction false
  w RimGlow false
  w GlowColor "#00FFFFFF"             # alpha 0 -> specular stays pure white
  w RimGlowColorMix false
  w EdgeLighting false

  # ---- corners (same as glass-apple.sh) ----
  w UseDeclaredCornerRadius false
  w TopCornerRadius 16
  w BottomCornerRadius 16
  w MenuCornerRadius 12
  w DockCornerRadius 24               # tune to your panel: ~ 1/3 of its thickness
  w RoundCornersOfMaximizedWindows true
  w DynamicCorners false

  # ---- force blur ----
  w BlurDecorations true
  w BlurMatching false
  w BlurNonMatching true

  reconfigure_kwin
  if [[ -n "$QDBUS" ]]; then
    "$QDBUS" org.kde.KWin /Effects org.kde.kwin.Effects.$([[ "$CONTRAST_EFFECT" == off ]] && echo unloadEffect || echo loadEffect) contrast >/dev/null || true
  fi
  echo "Applied Reactivities liquid glass preset ($MODE)."
}

# ---------------------------------------------------------------- Apple colour schemes
# macOS greys + Apple system colours, purple accent:
#   AppleDarkPurple   hover #BF5AF2, selection #8040AA
#   AppleLightPurple  hover #AF52DE, selection #8944AB
# Only written if missing, so later edits to ~/.local/share/color-schemes/<name>.colors are kept.
# For a blue macOS selection, set [Colors:Selection] BackgroundNormal there to
# 0,88,208 (dark) or 0,99,225 (light).
install_scheme() {  # $1 = AppleDarkPurple | AppleLightPurple
  local dest="${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes/$1.colors"
  [[ -f "$dest" ]] && return 0
  mkdir -p "$(dirname "$dest")"
  case "$1" in
    AppleDarkPurple) cat > "$dest" <<'DARK'
[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundAlternate=58,58,60
BackgroundNormal=72,72,74
DecorationFocus=175,82,222
DecorationHover=191,90,242
ForegroundActive=191,90,242
ForegroundInactive=152,152,157
ForegroundLink=65,156,255
ForegroundNegative=255,69,58
ForegroundNeutral=255,159,10
ForegroundNormal=223,223,223
ForegroundPositive=48,209,88
ForegroundVisited=191,90,242

[Colors:Complementary]
BackgroundAlternate=44,44,46
BackgroundNormal=30,30,30
DecorationFocus=175,82,222
DecorationHover=191,90,242
ForegroundActive=191,90,242
ForegroundInactive=152,152,157
ForegroundLink=65,156,255
ForegroundNegative=255,69,58
ForegroundNeutral=255,159,10
ForegroundNormal=223,223,223
ForegroundPositive=48,209,88
ForegroundVisited=191,90,242

[Colors:Header]
BackgroundAlternate=44,44,46
BackgroundNormal=56,56,58
DecorationFocus=175,82,222
DecorationHover=191,90,242
ForegroundActive=191,90,242
ForegroundInactive=152,152,157
ForegroundLink=65,156,255
ForegroundNegative=255,69,58
ForegroundNeutral=255,159,10
ForegroundNormal=223,223,223
ForegroundPositive=48,209,88
ForegroundVisited=191,90,242

[Colors:Header][Inactive]
BackgroundAlternate=38,38,40
BackgroundNormal=44,44,46
DecorationFocus=175,82,222
DecorationHover=191,90,242
ForegroundActive=191,90,242
ForegroundInactive=152,152,157
ForegroundLink=65,156,255
ForegroundNegative=255,69,58
ForegroundNeutral=255,159,10
ForegroundNormal=223,223,223
ForegroundPositive=48,209,88
ForegroundVisited=191,90,242

[Colors:Selection]
BackgroundAlternate=104,52,140
BackgroundNormal=128,64,170
DecorationFocus=175,82,222
DecorationHover=191,90,242
ForegroundActive=255,255,255
ForegroundInactive=225,210,235
ForegroundLink=255,255,255
ForegroundNegative=255,105,97
ForegroundNeutral=255,179,64
ForegroundNormal=255,255,255
ForegroundPositive=102,224,130
ForegroundVisited=230,200,250

[Colors:Tooltip]
BackgroundAlternate=38,38,40
BackgroundNormal=44,44,46
DecorationFocus=175,82,222
DecorationHover=191,90,242
ForegroundActive=191,90,242
ForegroundInactive=152,152,157
ForegroundLink=65,156,255
ForegroundNegative=255,69,58
ForegroundNeutral=255,159,10
ForegroundNormal=223,223,223
ForegroundPositive=48,209,88
ForegroundVisited=191,90,242

[Colors:View]
BackgroundAlternate=41,41,41
BackgroundNormal=30,30,30
DecorationFocus=175,82,222
DecorationHover=191,90,242
ForegroundActive=191,90,242
ForegroundInactive=152,152,157
ForegroundLink=65,156,255
ForegroundNegative=255,69,58
ForegroundNeutral=255,159,10
ForegroundNormal=223,223,223
ForegroundPositive=48,209,88
ForegroundVisited=191,90,242

[Colors:Window]
BackgroundAlternate=50,50,52
BackgroundNormal=44,44,46
DecorationFocus=175,82,222
DecorationHover=191,90,242
ForegroundActive=191,90,242
ForegroundInactive=152,152,157
ForegroundLink=65,156,255
ForegroundNegative=255,69,58
ForegroundNeutral=255,159,10
ForegroundNormal=223,223,223
ForegroundPositive=48,209,88
ForegroundVisited=191,90,242

[General]
ColorScheme=AppleDarkPurple
Name=Apple Dark (Purple)
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground=56,56,58
activeBlend=223,223,223
activeForeground=223,223,223
inactiveBackground=44,44,46
inactiveBlend=152,152,157
inactiveForeground=152,152,157
DARK
      ;;
    AppleLightPurple) cat > "$dest" <<'LIGHT'
[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundAlternate=246,246,246
BackgroundNormal=255,255,255
DecorationFocus=137,68,171
DecorationHover=175,82,222
ForegroundActive=137,68,171
ForegroundInactive=110,110,115
ForegroundLink=0,104,218
ForegroundNegative=215,0,21
ForegroundNeutral=201,52,0
ForegroundNormal=29,29,31
ForegroundPositive=36,138,61
ForegroundVisited=137,68,171

[Colors:Complementary]
BackgroundAlternate=56,56,58
BackgroundNormal=44,44,46
DecorationFocus=175,82,222
DecorationHover=191,90,242
ForegroundActive=191,90,242
ForegroundInactive=152,152,157
ForegroundLink=65,156,255
ForegroundNegative=255,69,58
ForegroundNeutral=255,159,10
ForegroundNormal=223,223,223
ForegroundPositive=48,209,88
ForegroundVisited=191,90,242

[Colors:Header]
BackgroundAlternate=236,236,236
BackgroundNormal=246,246,246
DecorationFocus=137,68,171
DecorationHover=175,82,222
ForegroundActive=137,68,171
ForegroundInactive=110,110,115
ForegroundLink=0,104,218
ForegroundNegative=215,0,21
ForegroundNeutral=201,52,0
ForegroundNormal=29,29,31
ForegroundPositive=36,138,61
ForegroundVisited=137,68,171

[Colors:Header][Inactive]
BackgroundAlternate=230,230,230
BackgroundNormal=236,236,236
DecorationFocus=137,68,171
DecorationHover=175,82,222
ForegroundActive=137,68,171
ForegroundInactive=110,110,115
ForegroundLink=0,104,218
ForegroundNegative=215,0,21
ForegroundNeutral=201,52,0
ForegroundNormal=29,29,31
ForegroundPositive=36,138,61
ForegroundVisited=137,68,171

[Colors:Selection]
BackgroundAlternate=120,58,152
BackgroundNormal=137,68,171
DecorationFocus=137,68,171
DecorationHover=175,82,222
ForegroundActive=255,255,255
ForegroundInactive=230,215,240
ForegroundLink=255,255,255
ForegroundNegative=255,180,175
ForegroundNeutral=255,210,150
ForegroundNormal=255,255,255
ForegroundPositive=170,240,185
ForegroundVisited=240,220,252

[Colors:Tooltip]
BackgroundAlternate=236,236,236
BackgroundNormal=246,246,246
DecorationFocus=137,68,171
DecorationHover=175,82,222
ForegroundActive=137,68,171
ForegroundInactive=110,110,115
ForegroundLink=0,104,218
ForegroundNegative=215,0,21
ForegroundNeutral=201,52,0
ForegroundNormal=29,29,31
ForegroundPositive=36,138,61
ForegroundVisited=137,68,171

[Colors:View]
BackgroundAlternate=244,245,245
BackgroundNormal=255,255,255
DecorationFocus=137,68,171
DecorationHover=175,82,222
ForegroundActive=137,68,171
ForegroundInactive=110,110,115
ForegroundLink=0,104,218
ForegroundNegative=215,0,21
ForegroundNeutral=201,52,0
ForegroundNormal=29,29,31
ForegroundPositive=36,138,61
ForegroundVisited=137,68,171

[Colors:Window]
BackgroundAlternate=230,230,230
BackgroundNormal=236,236,236
DecorationFocus=137,68,171
DecorationHover=175,82,222
ForegroundActive=137,68,171
ForegroundInactive=110,110,115
ForegroundLink=0,104,218
ForegroundNegative=215,0,21
ForegroundNeutral=201,52,0
ForegroundNormal=29,29,31
ForegroundPositive=36,138,61
ForegroundVisited=137,68,171

[General]
ColorScheme=AppleLightPurple
Name=Apple Light (Purple)
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground=246,246,246
activeBlend=29,29,31
activeForeground=29,29,31
inactiveBackground=236,236,236
inactiveBlend=110,110,115
inactiveForeground=110,110,115
LIGHT
      ;;
  esac
  echo "Installed colour scheme: $dest"
}

# ---------------------------------------------------------------- main
CMD="${1:-auto}"
case "$CMD" in
  backup)  backup "${2:-}" ;;
  restore) restore "${2:-}" ;;
  list)    list_backups ;;
  auto|light|dark)
    backup auto >/dev/null
    prune_auto
    if [[ "$CMD" == auto ]]; then MODE="$(detect_mode)"; else MODE="$CMD"; set_scheme "$MODE"; fi
    make_glass_style
    set_plasma_style
    style_follow_scheme
    apply_glass "$MODE"
    panels_translucent
    ;;
  *) awk '/^# Usage:/{f=1} /^# Every apply/{exit} f{sub(/^# ?/,""); print}' "$0"; exit 1 ;;
esac