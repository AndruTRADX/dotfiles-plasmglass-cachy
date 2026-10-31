#!/usr/bin/env bash
# Copies this machine's current config back into the repo (to keep it up to date).
# Usage: ./update.sh && git add -A && git commit -m "update"
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
# Only refresh files that are already tracked in the repo
(cd home && find . -type f) | while read -r f; do
  f="${f#./}"
  if [[ -e "$HOME/$f" ]]; then cp -a "$HOME/$f" "home/$f"; fi
done
# Pick up new fish functions
cp -a "$HOME/.config/fish/functions/." home/.config/fish/functions/
# Current glass values, for reference
sed -n '/^\[Effect-blurplus\]/,/^$/p' "$HOME/.config/kwinrc" > kwin-glass.ini
echo "Repo updated. Review with: git status"
