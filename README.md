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

> Any files that already existed are backed up to `~/.dotfiles-backup/`.

## What's included

| What | Where |
| --- | --- |
| Liquid glass | `glass-effect.sh` (KWin effect only). Reference values in `kwin-glass.ini` |
| Sounds | **Wii** sound theme (downloaded from GitHub), plus `home/.config/*.notifyrc` so more Plasma actions use it: login/logout, lock/unlock, screenshot/recording saved, network and Bluetooth connect, KDE Connect ping/call/notification, empty trash, admin password prompt, low disk space, critical errors |
| Fish | `home/.config/fish/` (config + PATH + functions `cls`, `fixaudio`, `fixmicro`, `fixglass`), **pure** prompt |
| Colours | `AppleDarkPurple` / `AppleLightPurple`, Plasma Style `AppleDark-ALL`, GTK `MacTahoe-Dark-purple` |
| Icons | **MacTahoe-purple-dark** (downloaded from GitHub), `capitaine-cursors` cursor |
| Global Themes | **Liquid Glass Dark** and **Liquid Glass Light** (System Settings > Global Theme). Applying one, even with "Desktop and window layout" ticked, gives back this exact setup; the glass tint follows automatically (`glass-follow.sh`) |
| Wallpaper & splash | MacTahoe wallpaper (light/dark variants) on desktop + lock screen, MacTahoe boot splash |
| Layout | MacTahoe layout: floating top menu bar (launcher, app menu, tray with trash + disk quota, clock, show desktop, power) and a floating auto-hide dock; desktop widgets: Modern Clock and two Kurve audio visualizers (30 fps, paused behind maximized/fullscreen windows) |
| Extras | MacTahoe window decoration (tiny borders), Darkly widget style, SF Pro font, Konsole profile + `AppleDarkPurple` terminal colours |

## Scripts

| Script | What it does |
| --- | --- |
| `install.sh` | Installs everything on a new machine |
| `theme.sh light\|dark` | Switches colours + Plasma Style + panels, then applies the glass |
| `glass-effect.sh light\|dark` | Liquid glass effect only |
| `backup.sh` / `backup.sh restore` | Saves / restores the desktop config |
| `update.sh` | Copies your current config into the repo |
| `glass-follow.sh` | Run by the `liquid-glass-follow.path` user unit whenever `kdeglobals` changes: switching the Global Theme or colour scheme in System Settings also switches the glass tint |
| `make-global-themes.sh` | Rebuilds the **Liquid Glass Dark/Light** Global Themes from the current desktop (run after changing panels or widgets) |
| `system/setup.sh` | Root tweaks: KWin pacman hook, monthly btrfs scrub, paccache, uinput, i2c group (run by `install.sh`) |

## Keeping the repo up to date

```fish
./update.sh
git add -A; and git commit -m "update"; and git push
```

## After a KWin upgrade

`kwin-effects-glass-git` is built against a specific KWin version, so it stops loading when KWin is upgraded.
A pacman hook (`system/pacman-hooks/`) prints a reminder; then run:

```fish
fixglass   # rebuilds the effect, then log out and back in
```
