#!/usr/bin/env bash
# Paints every OpenLinkHub device (RAM, fans, AIO) with a colour taken from the wallpaper on screen,
# including the current slide of a slideshow. Runs as wallpaper-rgb.service (see lib/wallpaper-rgbd.py).
#   ./wallpaper-rgb.sh                run the watcher in the foreground
#   ./wallpaper-rgb.sh IMAGE          print the LED colour the watcher would use for IMAGE
set -euo pipefail
LIB="$(dirname "$(readlink -f "$0")")/lib"
if [[ $# -gt 0 ]]; then exec python3 "$LIB/wallpaper-color.py" "$1"; fi
exec python3 "$LIB/wallpaper-rgbd.py"
