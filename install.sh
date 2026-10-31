#!/usr/bin/env bash
# Instala mis dotfiles en una maquina CachyOS + KDE Plasma 6 nueva.
# Uso: ./install.sh
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
REPO="$PWD"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

say() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }

# ------------------------------------------------------------- paquetes
say "Paquetes (pacman)"
sudo pacman -S --needed --noconfirm \
  git python fish fisher fish-pure-prompt fish-autopair cachyos-fish-config \
  capitaine-cursors ttf-jetbrains-mono-nerd

say "Paquetes AUR (paru): glass, Darkly, Kurve"
paru -S --needed --noconfirm kwin-effects-glass-git darkly plasma6-applets-kurve-git

# ------------------------------------------------------------- iconos y sonidos (desde upstream)
say "Iconos MacTahoe purple"
git clone --depth 1 https://github.com/vinceliuice/MacTahoe-icon-theme.git "$TMP/icons"
(cd "$TMP/icons" && ./install.sh -t purple)

say "Sonidos Wii"
rm -rf "$DATA/sounds/Wii"
git clone --depth 1 https://github.com/TheBearOfJare/Wii-System-Sounds-for-KDE-Plasma.git "$DATA/sounds/Wii"
rm -rf "$DATA/sounds/Wii/.git"

# ------------------------------------------------------------- archivos
say "Copiando archivos a \$HOME (respaldo de lo que exista en ~/.dotfiles-backup)"
BK="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
# plasmashell reescribe su config de paneles al salir: detenerlo antes de copiar
systemctl --user stop plasma-plasmashell.service 2>/dev/null || kquitapp6 plasmashell 2>/dev/null || true
(cd home && find . -type f -o -type l) | while read -r f; do
  f="${f#./}"
  if [[ -e "$HOME/$f" ]]; then mkdir -p "$BK/$(dirname "$f")"; cp -a "$HOME/$f" "$BK/$f"; fi
  mkdir -p "$HOME/$(dirname "$f")"
  cp -a "home/$f" "$HOME/$f"
done
fc-cache -f >/dev/null

# ------------------------------------------------------------- apariencia
say "Tema: colores, iconos, cursor, decoracion, sonidos"
plasma-apply-colorscheme AppleDarkPurple || true
plasma-apply-cursortheme capitaine-cursors || true
/usr/lib/plasma-changeicons MacTahoe-purple-dark 2>/dev/null || true
kwriteconfig6 --file kdeglobals --group Sounds --key Theme Wii
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Darkly
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae.v2
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__MacTahoe-Dark
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft XIA
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight ""

systemctl --user start plasma-plasmashell.service 2>/dev/null || (setsid -f plasmashell >/dev/null 2>&1)
sleep 3

say "Liquid glass"
./theme.sh dark

# ------------------------------------------------------------- shell
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != */fish ]]; then
  say "Fish como shell por defecto"
  chsh -s "$(command -v fish)"
fi

say "Listo. Cierra sesion y vuelve a entrar (elige 'Plasma (Wayland)')."
if [[ -d "$BK" ]]; then echo "Respaldo de tus archivos anteriores: $BK"; fi
