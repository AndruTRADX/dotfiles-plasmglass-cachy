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

3. Log out and back in. Done.

> Any files that already existed are backed up to `~/.dotfiles-backup/`.

## What's included

| What | Where |
|---|---|
| Liquid glass | `glass-effect.sh` (KWin effect only). Reference values in `kwin-glass.ini` |
| Sounds | **Wii** sound theme (downloaded from GitHub) |
| Fish | `home/.config/fish/` (config + functions `cls`, `fixaudio`, `fixmicro`), **pure** prompt |
| Colours | `AppleDarkPurple` / `AppleLightPurple`, Plasma Style `AppleDark-ALL`, GTK `MacTahoe-Dark-purple` |
| Icons | **MacTahoe-purple-dark** (downloaded from GitHub), `capitaine-cursors` cursor |
| Extras | MacTahoe window decoration, Darkly widget style, SF Pro font, panels and widgets, Konsole profile |

## Scripts

| Script | What it does |
|---|---|
| `install.sh` | Installs everything on a new machine |
| `theme.sh light\|dark` | Switches colours + Plasma Style + panels, then applies the glass |
| `glass-effect.sh light\|dark` | Liquid glass effect only |
| `backup.sh` / `backup.sh restore` | Saves / restores the desktop config |
| `update.sh` | Copies your current config into the repo |

## Keeping the repo up to date

```fish
./update.sh
git add -A; and git commit -m "update"; and git push
```

> The SF Pro fonts (`home/.fonts`) belong to Apple: keep this repo **private**.
