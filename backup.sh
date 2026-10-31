#!/usr/bin/env bash
# Snapshots of the desktop config that theme.sh / glass-effect.sh touch.
# Usage:
#   ./backup.sh [label]          save a snapshot ("auto" snapshots: last 10 kept)
#   ./backup.sh restore [label]  restore a snapshot (default: newest)
#   ./backup.sh list             list snapshots
set -euo pipefail
shopt -s nullglob
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"

BACKUP_ROOT="$DATA/glass-apple/backups"
KEEP_AUTO=10
FILES=(
  kwinrc kdeglobals plasmarc kcminputrc ksplashrc kscreenlockerrc
  plasma-org.kde.plasma.desktop-appletsrc plasmashellrc
  auroraerc breezerc klassyrc darklyrc lightlyrc
  Kvantum/kvantum.kvconfig
)

case "${1:-}" in
  list)
    for b in "$BACKUP_ROOT"/*/; do basename "$b"; done ;;
  restore)
    matches=("$BACKUP_ROOT"/*"${2:-}"*/)
    (( ${#matches[@]} )) || { echo "No backup matching '${2:-}' in $BACKUP_ROOT" >&2; exit 1; }
    src="${matches[-1]%/}"
    stop_shell
    for f in "${FILES[@]}"; do
      [[ -f "$src/$f" ]] || continue
      mkdir -p "$CFG/$(dirname "$f")"; cp -a "$src/$f" "$CFG/$f"
    done
    start_shell
    reconfigure_kwin
    echo "Restored: $src (log out and back in so open apps pick it up)" ;;
  *)
    label="${1//[^A-Za-z0-9_-]/_}"
    dest="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)${label:+-$label}"
    mkdir -p "$dest"
    for f in "${FILES[@]}"; do
      [[ -f "$CFG/$f" ]] || continue
      mkdir -p "$dest/$(dirname "$f")"; cp -a "$CFG/$f" "$dest/$f"
    done
    auto=("$BACKUP_ROOT"/*-auto/)
    if (( ${#auto[@]} > KEEP_AUTO )); then rm -rf -- "${auto[@]:0:${#auto[@]}-KEEP_AUTO}"; fi
    echo "Backup saved: $dest" ;;
esac
