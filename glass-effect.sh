#!/usr/bin/env bash
# "Liquid glass" preset for kwin-effects-glass: edge lens + chromatic aberration +
# thin white border + frosted body.
# Usage: ./glass-effect.sh [auto|light|dark]   (auto = follow the current colour scheme)
#
# Only touches KWin (~/.config/kwinrc). Colours / Plasma Style / panels live in theme.sh.
# Note: the plugin id is "glass", but its settings live in [Effect-blurplus].
#
# Tunables -- override from the shell, e.g.  LENS_BEVEL=9 ./glass-effect.sh dark
set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"

LENS_EDGE="${LENS_EDGE:-2}"             # x10 px: width of the refracting band at the edge
LENS_POW="${LENS_POW:-1}"               # /2: falloff steepness (higher = thinner, sharper edge)
LENS_BEVEL="${LENS_BEVEL:-15}"          # /10: edge lens strength (5..15)
LENS_STRENGTH="${LENS_STRENGTH:-12}"    # /20: index of refraction - 1
LENS_CURVE="${LENS_CURVE:-14}"          # /2: bends the lens sideways towards the corners (0..20)
FRINGING="${FRINGING:-16}"              # /20: chromatic aberration (0..20)
RIM_WIDTH="${RIM_WIDTH:-10}"            # /10 px
RIM_LIGHT="${RIM_LIGHT:-5}"             # /10: white border thickness, light mode
RIM_DARK="${RIM_DARK:-7}"               # /10: white border thickness, dark mode
BLUR_STRENGTH="${BLUR_STRENGTH:-2}"     # 1 = almost none, 2 = a hint, 3 = frosted
BLUR_FINETUNE="${BLUR_FINETUNE:-8}"     # 0..10, fine adjustment within the strength
TINT_LIGHT="${TINT_LIGHT:-#B0FFFFFF}"   # #AARRGGBB
TINT_DARK="${TINT_DARK:-#A018181B}"
TINT_MIN="${TINT_MIN:-60}"              # adaptive tint: % of the tint kept over a similar backdrop
BODY_REFRACTION="${BODY_REFRACTION:-true}"  # true = refract the whole surface, not just the edge
LENS_WINDOWS="${LENS_WINDOWS:-false}"       # true = also bend the backdrop behind normal windows (costs GPU on every repaint)
CONTRAST_EFFECT="${CONTRAST_EFFECT:-off}"   # off = disable KWin's Background Contrast (extra dark tint)

MODE="${1:-auto}"
if [[ "$MODE" == auto ]]; then MODE="$(detect_mode)"; fi
[[ "$MODE" == light || "$MODE" == dark ]] || { echo "Usage: $0 [auto|light|dark]" >&2; exit 1; }

w() { kwriteconfig6 --file kwinrc --group Effect-blurplus --key "$1" "$2"; }
pick() { [[ "$MODE" == light ]] && echo "$1" || echo "$2"; }   # pick <light> <dark>

# ---- make sure only Glass is doing the blurring ----
kwriteconfig6 --file kwinrc --group Plugins --key glassEnabled true
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled false
kwriteconfig6 --file kwinrc --group Plugins --key translucencyEnabled false
kwriteconfig6 --file kwinrc --group Plugins --key contrastEnabled "$([[ "$CONTRAST_EFFECT" == off ]] && echo false || echo true)"

# ---- blur: almost none, like iOS (clarity comes from the lens + adaptive tint) ----
w BlurStrength "$BLUR_STRENGTH";          w BlurFinetune "$BLUR_FINETUNE"
w DecorationBlurStrength "$BLUR_STRENGTH"
w DockBlurStrength "$BLUR_STRENGTH";      w DockBlurFinetune "$BLUR_FINETUNE"
w NoiseStrength 0; w DecorationNoiseStrength 0; w DockNoiseStrength 0
w BlurSaturationCompensation false

# ---- color ----
w OklabSaturation true
w Contrast 1.0
w Brightness "$(pick 1.05 1.0)"
w Saturation 1.3
w TintColor "$(pick "$TINT_LIGHT" "$TINT_DARK")"
w AutoTintAlpha true            # frost gets stronger where the backdrop contrasts with it
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
w RimGlow false
w GlowColor "#00FFFFFF"         # alpha 0 -> specular stays pure white
w RimGlowColorMix false
w EdgeLighting false

# ---- corners ----
w UseDeclaredCornerRadius false
w TopCornerRadius 16
w BottomCornerRadius 16
w MenuCornerRadius 12
w DockCornerRadius 24           # ~ 1/3 of the panel thickness
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
echo "Applied liquid glass preset ($MODE)."
