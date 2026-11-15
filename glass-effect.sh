#!/usr/bin/env bash
# "Liquid glass" preset for kwin-effects-glass, set from what is known of Apple's material on macOS 26:
# a lens only at the edge (a ~20 px band that pulls the image in from further inside, no distortion
# in the body), hardly any blur, two 1 px white highlights (top-left and bottom-right), no chromatic
# aberration, and a grey wash that lifts blacks and dims whites so text stays readable without blur.
# Also rounds all four window corners like macOS (KDE Rounded Corners effect), matching the MacTahoe title bar.
# Usage: ./glass-effect.sh [auto|light|dark]   (auto = follow the current colour scheme)
#
# Only touches KWin (~/.config/kwinrc). Colours / Plasma Style / panels live in theme.sh.
# Note: the plugin id is "glass", but its settings live in [Effect-blurplus].
#
# Tunables -- override from the shell, e.g.  LENS_BEVEL=9 ./glass-effect.sh dark
set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"

LENS_EDGE="${LENS_EDGE:-2}"             # x10 px: width of the refracting band at the edge
LENS_POW="${LENS_POW:-4}"               # /2: falloff steepness (higher = thinner, sharper edge); 4 is closest to Apple's quarter-circle profile
LENS_BEVEL="${LENS_BEVEL:-13}"          # /10: edge lens strength (5..15). Reach of the lens = band x bevel x (1 + strength) = 40 px
LENS_STRENGTH="${LENS_STRENGTH:-11}"    # /20: index of refraction - 1
LENS_CURVE="${LENS_CURVE:-0}"           # /2: bends the lens sideways towards the corners (0..20); Apple's only follows the edge
FRINGING="${FRINGING:-0}"               # /20: chromatic aberration (0..20); none on macOS, and 0 saves two texture reads per pixel
RIM_WIDTH="${RIM_WIDTH:-10}"            # /10 px
RIM_LIGHT="${RIM_LIGHT:-5}"             # /10: white border thickness, light mode
RIM_DARK="${RIM_DARK:-6}"               # /10: white border thickness, dark mode
BLUR_STRENGTH="${BLUR_STRENGTH:-1}"     # 1 and 2 = one half-size pass (about 2 px, as Apple's bars), 3-4 = two passes, 5+ = frosted
BLUR_FINETUNE="${BLUR_FINETUNE:-5}"     # 0..10, fine adjustment within the strength
NOISE="${NOISE:-2}"                     # film grain over the glass (0 = none)
TINT_LIGHT="${TINT_LIGHT:-#B8FFFFFF}"   # #AARRGGBB: the alpha is the tint over a backdrop that contrasts with it
TINT_DARK="${TINT_DARK:-#D92A2A2E}"
TINT_MIN="${TINT_MIN:-60}"              # adaptive tint: % of the tint kept over a similar backdrop (low = clear glass there)
SATURATION="${SATURATION:-1.8}"         # the wash greys the backdrop out: this gives its colour back
BODY_REFRACTION="${BODY_REFRACTION:-false}" # true = also bend the image further inside; Apple's lens stops at the edge band
LENS_WINDOWS="${LENS_WINDOWS:-false}"       # true = also bend the backdrop behind normal windows (costs GPU on every repaint)
CONTRAST_EFFECT="${CONTRAST_EFFECT:-off}"   # off = disable KWin's Background Contrast (extra dark tint)
CORNER_RADIUS="${CORNER_RADIUS:-24}"    # px: window corners, for Rounded Corners and the glass behind windows. The MacTahoe
                                        # title bar corners are 24 px circles: any other radius or a squircle leaves a double
                                        # edge, and a smaller glass radius leaves a see-through sliver at each corner
DOCK_RADIUS="${DOCK_RADIUS:-24}"        # px: panel (top bar and dock) corners, ~ 1/3 of the panel thickness. Plasma
                                        # popups count as windows for Glass, so they keep CORNER_RADIUS whatever this is

MODE="${1:-auto}"
if [[ "$MODE" == auto ]]; then MODE="$(detect_mode)"; fi
[[ "$MODE" == light || "$MODE" == dark ]] || { echo "Usage: $0 [auto|light|dark]" >&2; exit 1; }

# All keys are collected, then written to kwinrc in one go by lib/kconf.py (one process, one atomic write)
BATCH=()
set_key() { BATCH+=("$1"$'\t'"$2"$'\t'"$3"); }   # set_key <group> <key> <value>
w() { set_key Effect-blurplus "$1" "$2"; }
plugin() { set_key Plugins "$1" "$2"; }
pick() { [[ "$MODE" == light ]] && echo "$1" || echo "$2"; }   # pick <light> <dark>

# ---- make sure only Glass is doing the blurring ----
plugin glassEnabled true
plugin blurEnabled false
plugin translucencyEnabled false
plugin contrastEnabled "$([[ "$CONTRAST_EFFECT" == off ]] && echo false || echo true)"

# ---- blur: almost none, like iOS (clarity comes from the lens + adaptive tint), with a little grain ----
w BlurStrength "$BLUR_STRENGTH";          w BlurFinetune "$BLUR_FINETUNE"
w DecorationBlurStrength "$BLUR_STRENGTH"
w DockBlurStrength "$BLUR_STRENGTH";      w DockBlurFinetune "$BLUR_FINETUNE"
w NoiseStrength "$NOISE"; w DecorationNoiseStrength "$NOISE"; w DockNoiseStrength "$NOISE"
w BlurSaturationCompensation false

# ---- color ----
w OklabSaturation true
w Contrast 1.0
w Brightness "$(pick 1.05 1.0)"
w Saturation "$SATURATION"
w TintColor "$(pick "$TINT_LIGHT" "$TINT_DARK")"
w AutoTintAlpha true            # like Apple's: clear over a similar backdrop, stronger where text would be hard to read
w AutoTintAlphaMin "$TINT_MIN"
w AutoTintAlphaMax 100
for k in ExcludeDocks ExcludeDecorations ExcludeTooltips ExcludeMenus ExcludeOSD; do w "$k" false; done

# ---- refraction: thin, strong lens at the edge with chromatic aberration ----
w PhysicallyBasedRefraction true
w RefractionStrength "$LENS_STRENGTH"
w RefractionEdgeSize "$LENS_EDGE"
w RefractionNormalPow "$LENS_POW"
w RefractionBevelIntensity "$LENS_BEVEL"
w RefractionOffsetStrength "$LENS_CURVE"
w RefractionRGBFringing "$FRINGING"
w BodyRefraction "$BODY_REFRACTION"
w RefractionExcludeWindows "$([[ "$LENS_WINDOWS" == true ]] && echo false || echo true)"
w RefractionExcludeTooltips true
w RefractionExcludeDocks false
w RefractionExcludeMenus false
w RefractionExcludeOSD false

# ---- rim: thin white border (thickness = RIM_WIDTH x RIM_x / 100 px) ----
w RimSpecular true
w RimWidth "$RIM_WIDTH"
w RimSpecularScale "$(pick "$RIM_LIGHT" "$RIM_DARK")"
w RimAdaptToRefraction false
# light comes from the top-left, like Apple's: the rim catches it there and on the opposite corner
w RimSpecularTopLeft true;   w RimSpecularBottomRight true
w RimSpecularTopRight false; w RimSpecularBottomLeft false
w RimGlow false
w GlowColor "#00FFFFFF"         # alpha 0 -> specular stays pure white
w RimGlowColorMix false
w EdgeLighting false

# ---- corners ----
w UseDeclaredCornerRadius false
w TopCornerRadius "$CORNER_RADIUS"     # windows only: menus and panels have their own radius below
w BottomCornerRadius "$CORNER_RADIUS"
w MenuCornerRadius 12
w DockCornerRadius "$DOCK_RADIUS"
w RoundCornersOfMaximizedWindows true
w DynamicCorners false

# ---- force blur ----
w BlurDecorations true
w BlurMatchingDecorations false   # the other half of the same radio button in the settings dialog
# Plasma popups (launcher, notifications, OSD) already ask for blur themselves: forcing a frame on top makes
# the effect run its whole blur chain twice for them
w DecorWindowClasses plasmashell
w BlurMatching false
w BlurNonMatching true

# ---- window corners (kwin-effect-rounded-corners): all four rounded, like macOS ----
# Same circle as the MacTahoe title bar, so the bottom corners match the top ones. No outlines: the decoration
# draws its own edge (extra dark/light lines looked bad). Maximized, tiled and fullscreen windows stay square.
r() { set_key Round-Corners "$1" "$2"; }
plugin kwin4_effect_shapecornersEnabled true
r Size "$CORNER_RADIUS";              r InactiveCornerRadius "$CORNER_RADIUS"
r UseSquircleShape false
r UseNativeDecorationShadows true     # keep the window decoration's own shadow
r OuterOutlineThickness 0;            r InactiveOuterOutlineThickness 0
r OutlineThickness 0;                 r InactiveOutlineThickness 0
r SecondOutlineThickness 0;           r InactiveSecondOutlineThickness 0

printf '%s\n' "${BATCH[@]}" | python3 "$LIB/kconf.py" "$CFG/kwinrc"
reconfigure_kwin
if [[ -n "$QDBUS" ]]; then
  fx=(org.kde.KWin /Effects org.kde.kwin.Effects)
  if [[ "$("$QDBUS" "${fx[@]}.isEffectLoaded" kwin4_effect_shapecorners 2>/dev/null)" == true ]]; then
    "$QDBUS" "${fx[@]}.reconfigureEffect" kwin4_effect_shapecorners >/dev/null || true
  elif [[ "$("$QDBUS" "${fx[@]}.loadEffect" kwin4_effect_shapecorners 2>/dev/null)" != true ]]; then
    echo "Rounded Corners did not load: install kwin-effect-rounded-corners-git, or run fixglass after a KWin upgrade" >&2
  fi
fi
if [[ -n "$QDBUS" ]]; then
  "$QDBUS" org.kde.KWin /Effects org.kde.kwin.Effects.$([[ "$CONTRAST_EFFECT" == off ]] && echo unloadEffect || echo loadEffect) contrast >/dev/null || true
fi
# The tint now in kwinrc: glass-follow.sh compares against this, so it is saved by whoever applies it
mkdir -p "$(dirname "$GLASS_STATE")"; echo "$MODE" > "$GLASS_STATE"
echo "Applied liquid glass preset ($MODE)."
