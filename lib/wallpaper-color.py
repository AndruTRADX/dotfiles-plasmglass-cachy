#!/usr/bin/env python3
"""Desktop wallpaper helpers for wallpaper-rgb: which wallpaper is configured, and an LED colour from it.
usage: wallpaper-color.py IMAGE   ->  "#rrggbb"

The colour is the most vivid of the image's main colours (count x saturation^2 x brightness),
pushed to full brightness and at least 80% saturation: LEDs make pastel shades look washed out."""
import colorsys, os, re, subprocess, sys
from urllib.parse import unquote, urlparse

DEFAULT = "/usr/share/wallpapers/Next"
IMAGE_EXT = (".png", ".jpg", ".jpeg", ".webp", ".avif", ".jxl", ".bmp", ".tif", ".tiff")


def read_groups(path):
    groups, cur = {}, None
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if line.startswith("["):
                cur = line
                groups.setdefault(cur, {})
            elif "=" in line and cur:
                k, v = line.split("=", 1)
                groups[cur][k] = v
    return groups


def desktop_wallpaper(appletsrc):
    """("image", path) or ("slideshow", [folders]) for the desktop on the first screen, or None."""
    groups = read_groups(appletsrc)
    best = None
    for name, keys in groups.items():
        if not re.fullmatch(r"\[Containments\]\[\d+\]", name):
            continue
        if keys.get("plugin") not in ("org.kde.plasma.folder", "org.kde.desktopcontainment"):
            continue   # panels carry a wallpaperplugin key too
        screen = int(keys.get("lastScreen", "99") or 99)
        if best is None or screen < best[0]:
            best = (screen, name, keys.get("wallpaperplugin", "org.kde.image"))
    if best is None:
        return None
    _, name, plugin = best
    if plugin == "org.kde.slideshow":
        paths = groups.get(f"{name}[Wallpaper][org.kde.slideshow][General]", {}).get("SlidePaths", "")
        folders = [os.path.expanduser(p) for p in paths.split(",") if p.strip()]
        return ("slideshow", folders or [os.path.expanduser("~/Pictures")])
    if plugin == "org.kde.image":
        image = groups.get(f"{name}[Wallpaper][org.kde.image][General]", {}).get("Image", "") or DEFAULT
        return ("image", unquote(urlparse(image).path) if image.startswith("file:") else image)
    return None


def resolve(path, mode):
    """A wallpaper package is a folder with contents/images[_dark]: pick its biggest image."""
    if os.path.isfile(path):
        return path
    for sub in (["images_dark", "images"] if mode == "dark" else ["images"]):
        d = os.path.join(path, "contents", sub)
        if os.path.isdir(d):
            files = [os.path.join(d, f) for f in os.listdir(d)]
            files = [f for f in files if os.path.isfile(f)]
            if files:
                return max(files, key=os.path.getsize)
    return None


def led_colour(image):
    out = subprocess.run(["magick", image + "[0]", "-resize", "96x96!", "-colors", "10",
                          "-format", "%c", "histogram:info:-"],
                         capture_output=True, text=True, check=True).stdout
    best = None
    for line in out.splitlines():
        m = re.match(r"\s*(\d+):\s*\(\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)", line)
        if not m:
            continue
        n = int(m[1])
        h, s, v = colorsys.rgb_to_hsv(*(min(float(x), 255.0) / 255 for x in m.groups()[1:4]))
        score = n * s * s * (0.3 + v)
        if best is None or score > best[0]:
            best = (score, h, s)
    if best is None or best[2] < 0.15:   # grey/black/white picture: nothing to take, use white
        return "#ffffff"
    _, h, s = best
    r, g, b = colorsys.hsv_to_rgb(h, max(s, 0.8), 1.0)
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))


if __name__ == "__main__":
    print(led_colour(sys.argv[1]))
