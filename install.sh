#!/usr/bin/env bash
# Installs these dotfiles on a fresh CachyOS + KDE Plasma 6 machine.
# Usage: ./install.sh
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
REPO="$PWD"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
source lib/common.sh

say() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }

# ------------------------------------------------------------- packages
say "Packages (pacman)"
sudo pacman -S --needed --noconfirm \
  git python fish fisher fish-pure-prompt fish-autopair cachyos-fish-config \
  capitaine-cursors ttf-jetbrains-mono-nerd bluez-utils paru \
  openlinkhub

say "AUR packages (paru): glass, Darkly, Kurve"
paru -S --needed --noconfirm kwin-effects-glass-git darkly plasma6-applets-kurve-git

say "System tweaks: pacman hooks, OpenLinkHub, btrfs scrub, paccache, uinput, i2c group"
sudo ./system/setup.sh

# ------------------------------------------------------------- icons and sounds (from upstream)
say "MacTahoe purple icons"
clone_pinned "$MACTAHOE_ICONS_URL" "$MACTAHOE_ICONS_REV" "$TMP/icons"
(cd "$TMP/icons" && ./install.sh -t purple)

say "Wii sound theme"
rm -rf "$DATA/sounds/Wii"
clone_pinned "$WII_SOUNDS_URL" "$WII_SOUNDS_REV" "$DATA/sounds/Wii"
rm -rf "$DATA/sounds/Wii/.git"

# ------------------------------------------------------------- files
say "Copying files to \$HOME (existing ones are backed up to ~/.dotfiles-backup)"
BK="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
# plasmashell writes its panel config back on exit: stop it before copying
systemctl --user stop plasma-plasmashell.service 2>/dev/null || kquitapp6 plasmashell 2>/dev/null || true
(cd home && find . -type f -o -type l) | while read -r f; do
  f="${f#./}"
  if [[ -e "$HOME/$f" ]]; then mkdir -p "$BK/$(dirname "$f")"; cp -a "$HOME/$f" "$BK/$f"; fi
  mkdir -p "$HOME/$(dirname "$f")"
  cp -a "home/$f" "$HOME/$f"
done
fc-cache -f >/dev/null

# ------------------------------------------------------------- appearance
say "Theme: colours, icons, cursor, window decoration, sounds"
plasma-apply-colorscheme AppleDarkPurple || true
plasma-apply-cursortheme capitaine-cursors || true
/usr/lib/plasma-changeicons MacTahoe-purple-dark 2>/dev/null || true
kwriteconfig6 --file kdeglobals --group Sounds --key Theme Wii
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Darkly
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae.v2
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__MacTahoe-Dark
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft XIA
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight ""
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key BorderSize Tiny
kwriteconfig6 --file kwinrc --group Plugins --key frozenappEnabled false
# Unused background services: Baloo search folders (Baloo is off) and proxy auto-detection (no proxy)
for m in baloosearchmodule wpad_detector; do
  kwriteconfig6 --file kded6rc --group "Module-$m" --key autoload false
done

# See-through copies of both Plasma Styles, so either Global Theme works from System Settings
build_glass_style "$LIGHT_STYLE"
build_glass_style "$DARK_STYLE"

# Our own Global Theme: colours, icons, cursor, widget style, decoration, Plasma Style, splash
plasma-apply-lookandfeel -a com.github.andrutradx.liquidglass-dark || true
kwriteconfig6 --file ksplashrc --group KSplash --key Theme com.github.andrutradx.liquidglass-dark
WALL="$DATA/wallpapers/MacTahoe"
kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin org.kde.image
kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$WALL"
kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key PreviewImage "file://$WALL"

systemctl --user start plasma-plasmashell.service 2>/dev/null || (setsid -f plasmashell >/dev/null 2>&1)
sleep 3

plasma-apply-wallpaperimage "$WALL" || true

say "Liquid glass"
./theme.sh dark

say "Glass tint follows the Global Theme (light/dark) automatically"
systemctl --user daemon-reload
systemctl --user enable --now liquid-glass-follow.path

say "Login check: notify when the glass effect fails to load (after a KWin upgrade)"
systemctl --user enable glass-check.service

say "Weekly cleanup of the paru build cache"
systemctl --user enable --now paru-cache-clean.timer

say "Bluetooth headphones: report play/pause state so one button toggles correctly"
systemctl --user enable --now mpris-proxy.service

# ------------------------------------------------------------- shell
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != */fish ]]; then
  say "Setting fish as the default shell"
  chsh -s "$(command -v fish)"
fi

say "Health check"
./doctor.sh || true

say "Done. Log out and back in (pick 'Plasma (Wayland)')."
echo "Login screen: System Settings > Login Screen > 'Apply Plasma Settings' to copy this theme there."
if [[ -d "$BK" ]]; then echo "Backup of your previous files: $BK"; fi
