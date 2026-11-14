#!/usr/bin/env bash
# Global shortcuts for a 60% keyboard (no arrows, no F row, no PgUp/PgDn, no Print key).
# Everything lives on letters and digits. I J K L are the arrows, as on the keyboard's own Fn layer:
#
#   Meta             + I/K  volume      + J/L  previous/next track   (U play/pause, M mute)
#   Meta+Shift       + J/L  desktop to the left/right
#   Meta+Alt         + IJKL focus the window on that side
#   Meta+Ctrl        + J/L  window to the left/right half   + I maximize   + K minimize
#   Meta+Ctrl+Shift  + J/L  move the window to the desktop on the left/right
#
# Applied live through D-Bus (lib/shortcuts.py); KDE saves them itself. Safe to run again.
# Usage: ./shortcuts.sh
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

# Component <TAB> Action <TAB> Keys ("none" = unbind). The list replaces all keys of the action.
python3 lib/shortcuts.py <<'EOF'
# ---- free keys that did nothing useful here (one activity, two keyboard layouts, CLion is Meta+2)
plasmashell	manage activities	none
plasmashell	next activity	none
plasmashell	previous activity	none
KDE Keyboard Layout Switcher	Switch to Last-Used Keyboard Layout	none
KDE Keyboard Layout Switcher	Switch to Next Keyboard Layout	Meta+Space
jetbrains-clion.desktop	_launch	none
plasmashell	activate task manager entry 7	Meta+7
# ---- KDE defaults that sit on keys used below: Meta+B (power profile), Meta+I (settings), Meta+D (peek at desktop)
org_kde_powerdevil	powerProfile	Battery
systemsettings.desktop	_launch	Tools
kwin	Show Desktop	none
org.kde.spectacle.desktop	_launch	Print

# ---- media and desktops (I J K L = arrows)
kmix	increase_volume	Volume Up, Meta+I
kmix	decrease_volume	Volume Down, Meta+K
kmix	mute	Volume Mute, Meta+M
mediacontrol	previousmedia	Media Previous, Meta+J
mediacontrol	nextmedia	Media Next, Meta+L
mediacontrol	playpausemedia	Media Play, Meta+U
kwin	Switch to Previous Desktop	Meta+Shift+J
kwin	Switch to Next Desktop	Meta+Shift+L
kwin	Switch to Desktop 1	Meta+Ctrl+1, Meta+F1, Ctrl+F1
kwin	Switch to Desktop 2	Meta+Ctrl+2, Meta+F2, Ctrl+F2
kwin	Switch to Desktop 3	Meta+Ctrl+3, Meta+F3, Ctrl+F3

# ---- windows
kwin	Switch Window Left	Meta+Alt+J, Meta+Alt+Left
kwin	Switch Window Right	Meta+Alt+L, Meta+Alt+Right
kwin	Switch Window Up	Meta+Alt+I, Meta+Alt+Up
kwin	Switch Window Down	Meta+Alt+K, Meta+Alt+Down
kwin	Window Quick Tile Left	Meta+Ctrl+J, Meta+Left
kwin	Window Quick Tile Right	Meta+Ctrl+L, Meta+Right
kwin	Window Maximize	Meta+Ctrl+I, Meta+PgUp
kwin	Window Minimize	Meta+Ctrl+K, Meta+PgDown
kwin	Window One Desktop to the Left	Meta+Ctrl+Shift+J, Meta+Ctrl+Shift+Left
kwin	Window One Desktop to the Right	Meta+Ctrl+Shift+L, Meta+Ctrl+Shift+Right
kwin	Window Close	Meta+Q, Alt+F4
kwin	Window Fullscreen	Meta+F
kwin	Activate Window Demanding Attention	Meta+A, Meta+Ctrl+A
# Esc sits where the ` key would be: Alt+Esc cycles the windows of the current app, like Alt+`
kwin	Walk Through Windows of Current Application	Alt+Esc, Alt+`, Meta+`

# ---- apps and session
org.kde.konsole.desktop	_launch	Meta+Return, Ctrl+Alt+T
org.kde.dolphin.desktop	_launch	Meta+E, Meta+D
org.kde.kcalc.desktop	_launch	Meta+C
org.kde.spectacle.desktop	RectangularRegionScreenShot	Meta+S, Meta+Shift+S
org.kde.spectacle.desktop	ActiveWindowScreenShot	Meta+Ctrl+S, Meta+Print
org.kde.spectacle.desktop	FullScreenScreenShot	Meta+Alt+S, Shift+Print
ksmserver	Lock Session	Meta+B, Screensaver
ksmserver	Log Out	Meta+Shift+Q, Ctrl+Alt+Del
EOF
