#!/usr/bin/env bash
# Vuelve a copiar la config actual de esta maquina al repo (para mantenerlo al dia).
# Uso: ./update.sh && git add -A && git commit -m "update"
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
# Solo actualiza lo que ya esta en el repo
(cd home && find . -type f) | while read -r f; do
  f="${f#./}"
  if [[ -e "$HOME/$f" ]]; then cp -a "$HOME/$f" "home/$f"; fi
done
# Funciones de fish nuevas
cp -a "$HOME/.config/fish/functions/." home/.config/fish/functions/
# Valores actuales del glass, como referencia
sed -n '/^\[Effect-blurplus\]/,/^$/p' "$HOME/.config/kwinrc" > kwin-glass.ini
echo "Repo actualizado. Revisa con: git status"
