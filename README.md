# dotfiles

Mi CachyOS + KDE Plasma 6: liquid glass, sonidos Wii, fish, colores Apple Purple, iconos MacTahoe.

## Instalar en una maquina nueva

1. Instala CachyOS con **KDE Plasma** y **fish** (lo que trae por defecto).
2. Entra a tu sesion y abre una terminal:

```fish
mkdir -p ~/Code && cd ~/Code
git clone <URL-de-este-repo> dotfiles
cd dotfiles
./install.sh
```

3. Cierra sesion y vuelve a entrar. Listo.

> Lo que tenias antes se respalda en `~/.dotfiles-backup/`.

## Que incluye

| Que | Donde |
|---|---|
| Liquid glass | `glass-reactivities.sh` (instala `kwin-effects-glass-git` y aplica el preset). Valores exactos de referencia en `kwin-glass.ini` |
| Sonidos | Tema **Wii** (se descarga de GitHub) |
| Fish | `home/.config/fish/` (config + funciones `cls`, `fixaudio`, `fixmicro`), prompt **pure** |
| Colores | `AppleDarkPurple` / `AppleLightPurple`, Plasma Style `AppleDark-ALL`, GTK `MacTahoe-Dark-purple` |
| Iconos | **MacTahoe-purple-dark** (se descarga de GitHub), cursor `capitaine-cursors` |
| Extra | Decoracion de ventanas MacTahoe, estilo Darkly, fuente SF Pro, paneles y widgets, perfil de Konsole |

## Cambiar entre claro / oscuro

```fish
./glass-reactivities.sh light   # o dark
./glass-reactivities.sh restore # deshacer
```

## Mantener el repo al dia

```fish
./update.sh
git add -A; and git commit -m "update"; and git push
```

> Las fuentes SF Pro (`home/.fonts`) son de Apple: deja el repo **privado**.
