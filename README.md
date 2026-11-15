# dotfiles

My CachyOS + KDE Plasma 6 setup: liquid glass, Wii sounds, fish, Apple Purple colours, MacTahoe icons.

## Install on a new machine

1. Install CachyOS with **KDE Plasma** and **fish** (the defaults).
2. Log in and open a terminal:

```fish
mkdir -p ~/Code && cd ~/Code
git clone <repo-url> dotfiles
cd dotfiles
./install.sh
```

3. Log out and back in.
4. Optional: System Settings > Login Screen > **Apply Plasma Settings** so the login screen uses the same theme.

> Files that already exist in your home are overwritten (no backups: git history is the backup).

## What's included

| What | Where |
| --- | --- |
| Liquid glass | `glass-effect.sh` (KWin effect only). Reference values in `kwin-glass.ini` |
| Window corners | All four corners rounded (24 px circles, the same as the MacTahoe title bar corners: a squircle or any other radius leaves a double edge at the top corners), no extra outlines. The glass behind windows uses the same 24 px, or a see-through sliver shows at each corner. **KDE Rounded Corners** (`kwin-effect-rounded-corners-git` from the AUR, built against your KWin like the glass), set by `glass-effect.sh` |
| Sounds | **Wii** sound theme (downloaded from GitHub), plus `home/.config/*.notifyrc` so more Plasma actions use it: login/logout, lock/unlock, screenshot/recording saved, network and Bluetooth connect, KDE Connect ping/call/notification, empty trash, admin password prompt, low disk space, critical errors |
| Shortcuts | `shortcuts.sh`: a layout for a 60% keyboard, everything on letters and digits with **I J K L** as arrows (see [Keyboard shortcuts](#keyboard-shortcuts)) |
| Fish | `home/.config/fish/` (config + PATH + functions `cls`, `fixaudio`, `fixmicro`, `fixglass`, `shortcuts`), **pure** prompt |
| Colours | `AppleDarkPurple` / `AppleLightPurple`, Plasma Style `MacTahoe-Light` / `AppleDark-ALL` (see-through `-Glass` copies built by the scripts), GTK `MacTahoe-Dark-purple` |
| Icons | **MacTahoe-purple-dark** (downloaded from GitHub), `capitaine-cursors` cursor |
| Global Themes | **Liquid Glass Dark** and **Liquid Glass Light** (System Settings > Global Theme). Applying one, even with "Desktop and window layout" ticked, gives back this exact setup; the glass tint follows automatically (`glass-follow.sh`) |
| Wallpaper & splash | MacTahoe wallpaper (light/dark variants) on desktop + lock screen, MacTahoe boot splash |
| Layout | MacTahoe layout: floating top menu bar (launcher, the active app's name in bold as in macOS (**Application Title Bar** widget), app menu, power, tray, clock, show desktop) and a floating auto-hide dock (the trash is in Dolphin's sidebar). The tray shows only volume, network, Bluetooth, keyboard layout, notifications and media while playing; clipboard, KDE Connect, weather, displays, disk quota, Steam and Cachy-Update sit behind the arrow (no battery/brightness/dwell-clicker items: desktop PC) |
| Desktop widgets | **Liquid Glass** widgets (Tahoe style) at the top left: clock, calendar, weather (Bogotá, from open-meteo.com: change the city in the widget's settings) and now playing with synced lyrics (fetched from lrclib.net). Glass style set by hand in each widget's Appearance page (now: Gaussian blur 4 px, 18 % tint, 35 px edge, refraction index 1.8 at the default strength, 16 % colour fringing, follow light/dark). With a 2 px blur, a refraction strength above about 30 makes the lens fold near the edge and smear detailed wallpapers into streaks. The music widget tints its glass with the album art's colour, by design. |
| Bluetooth media buttons | `system/setup.sh` lets bluetoothd create the AVRCP input device; `install.sh` enables the `mpris-proxy` user service (bluez-utils) so headphones know whether something is playing and send Play or Pause correctly |
| Performance | `scx_lavd` scheduler (`system/scx_loader.toml`), 12 GB NVIDIA shader cache (`home/.config/environment.d/`), hardware video decoding in Brave (`home/.config/brave-flags.conf`), weekly paru cache cleanup (`paru-cache-clean.timer`), proxy auto-detection (`wpad_detector`) off |
| File search | Baloo indexing on (file names + contents of your home, hidden folders skipped): search files from KRunner, the launcher and Dolphin |
| Hardware | Motherboard fans/voltages via `it87` (ITE chips on Gigabyte boards), Corsair RAM RGB in OpenLinkHub (SMBus and SKU detected by `system/setup.sh`) |
| Extras | MacTahoe window decoration (tiny borders, with its 1 px edge lines removed: the black one outside and the faint white one inside; the original is in git history), Darkly widget style (see-through menus and Dolphin sidebar), SF Pro font, macOS-style clock (`sáb 14 nov 1:07 p. m.`), genie minimize animation, Konsole profile + `AppleDarkPurple` terminal colours with a see-through background |

## Scripts

| Script | What it does |
| --- | --- |
| `install.sh` | Installs everything on a new machine |
| `theme.sh light\|dark` | Switches colours + Plasma Style + panels, then applies the glass |
| `glass-effect.sh light\|dark` | Liquid glass effect and rounded window corners (all kwinrc keys written in one go by `lib/kconf.py`) |
| `shortcuts.sh` | Applies the global shortcuts live through D-Bus (`lib/shortcuts.py`); the table inside the script is the layout |
| `update.sh` | Copies your current config into the repo |
| `glass-follow.sh` | Run by the `liquid-glass-follow.path` user unit whenever `kdeglobals` changes: switching the Global Theme or colour scheme in System Settings also switches the glass tint |
| `doctor.sh` | Read-only health check: glass loaded, tint and Plasma Style match the mode, user/system services, Wi-Fi regdomain, VRR. Prints a fix for each failure |
| `glass-check.sh` | Run at login by `glass-check.service`: if Glass did not load (KWin upgraded), shows a notification with a **Rebuild now** button that runs `fixglass` |
| `make-global-themes.sh` | Rebuilds the **Liquid Glass Dark/Light** Global Themes from the current desktop (run after changing panels or widgets) |
| `system/setup.sh` | Root tweaks: KWin pacman hook, scx_lavd scheduler, intel_lpmd off, Wi-Fi regulatory domain (`/etc/iw-regdomain`, from the timezone or `sudo COUNTRY=XX`), it87 sensors, OpenLinkHub RAM RGB, monthly btrfs scrub, paccache, uinput, i2c group (run by `install.sh`) |

## Keyboard shortcuts

Run `shortcuts` in fish to list everything that is bound right now, straight from KDE's own file; add words to filter (`shortcuts tile`, `shortcuts meta+ctrl`).

Made for a 60% keyboard (no arrows, F row, PgUp/PgDn or Print key). **I J K L** are the arrows, as on the keyboard's Fn layer; the modifier picks what moves:

| Keys | I (up) | K (down) | J (left) | L (right) |
| --- | --- | --- | --- | --- |
| `Meta` | volume up | volume down | previous track | next track |
| `Meta+Shift` | | | desktop to the left | desktop to the right |
| `Meta+Alt` | focus window above | focus window below | focus window on the left | focus window on the right |
| `Meta+Ctrl` | maximize / restore | minimize | tile to the left half | tile to the right half |
| `Meta+Ctrl+Shift` | | | move window one desktop left | move window one desktop right |

| Keys | Action |
| --- | --- |
| `Meta+U` / `Meta+M` | play-pause / mute |
| `Meta+1`…`9` | focus or launch the app at that position in the dock |
| `Meta+Ctrl+1`…`3` | go to desktop 1…3 |
| `Meta+Q` / `Meta+F` | close window / fullscreen |
| `Alt+Tab` / `Alt+Esc` | switch windows / switch windows of the same app |
| `Meta+A` | jump to the window asking for attention |
| `Meta+Return` / `Meta+E` / `Meta+C` | Konsole / Dolphin / calculator |
| `Alt+Space` | KRunner: apps, files, calculator, commands |
| `Meta+W` / `Meta+G` | overview (type to filter windows) / desktop grid |
| `Meta+V` | clipboard history |
| `Meta+S` / `Meta+Ctrl+S` / `Meta+Alt+S` | screenshot of a region / the active window / the whole screen |
| `Meta+Shift+R` / `Meta+Ctrl+R` / `Meta+Alt+R` | record a region / a window / the screen |
| `Meta+Space` | switch keyboard layout (us / es) |
| `Meta+B` / `Meta+Shift+Q` | lock / log out, restart or shut down |

## Keeping the repo up to date

```fish
./update.sh
git add -A; and git commit -m "update"; and git push
```

## After a KWin upgrade

`kwin-effects-glass-git` and `kwin-effect-rounded-corners-git` are built against a specific KWin version, so they stop loading when KWin is upgraded.
A pacman hook (`system/pacman-hooks/`) prints a reminder, and at the next login `glass-check.service` shows a notification with a **Rebuild now** button. Or run it yourself:

```fish
fixglass   # rebuilds both effects, then log out and back in
```

## Games (Steam)

Steam has no global launch options, so set this per game (right click > Properties > Launch Options):

```
game-performance %command%
```

It switches the power profile to *performance* while the game runs and back to *balanced* when it closes (`game-performance` ships with CachyOS).
