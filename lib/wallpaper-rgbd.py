#!/usr/bin/env python3
"""wallpaper-rgb daemon: paints every OpenLinkHub device with a colour from the wallpaper on screen.

- Image wallpaper: follows ~/.config/plasma-org.kde.plasma.desktop-appletsrc (wallpaper changes)
  and kdeglobals (light/dark, for wallpaper packages with a dark variant).
- Slideshow: Plasma does not record which slide is shown, but plasmashell opens the new picture
  twice in a row when it switches; a folder rescan opens each file only once. So the picture
  opened twice in a row (inotify IN_OPEN) is the one on screen.

Keeps the brightness set in OpenLinkHub, and only sends a colour when the picture changes, so a
colour picked by hand in OpenLinkHub stays until the next wallpaper change.
Started by wallpaper-rgb.service before plasmashell, so it also sees the first slide at login."""
import ctypes, json, os, select, socket, struct, subprocess, sys, time, urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
wc = __import__("wallpaper-color")

API = os.environ.get("OPENLINKHUB_API", "http://127.0.0.1:27003/api")
CFG = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
APPLETSRC = os.path.join(CFG, "plasma-org.kde.plasma.desktop-appletsrc")
STATE = os.path.join(os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state")),
                     "liquid-glass", "wallpaper-rgb")
SETTLE = 1.0   # seconds of quiet before acting on a burst of events

IN_OPEN, IN_CLOSE_WRITE, IN_MOVED_TO, IN_CREATE, IN_ISDIR = 0x20, 0x08, 0x80, 0x100, 0x40000000
libc = ctypes.CDLL("libc.so.6", use_errno=True)
fd = libc.inotify_init1(os.O_CLOEXEC)
watches = {}   # wd -> folder


def log(*a):
    print(*a, flush=True)


def watch(path, mask):
    wd = libc.inotify_add_watch(fd, os.fsencode(path), mask)
    if wd >= 0:
        watches[wd] = path


def mode():
    """light|dark from the window background colour, like lib/common.sh detect_mode."""
    try:
        bg = wc.read_groups(os.path.join(CFG, "kdeglobals")).get("[Colors:Window]", {}).get("BackgroundNormal", "")
        r, g, b = (int(x) for x in bg.split(",")[:3])
        return "light" if (299 * r + 587 * g + 114 * b) / 1000 > 128 else "dark"
    except Exception:
        return "light"


def api(path, body=None, tries=4):
    """OpenLinkHub drops connections while it is busy writing to the devices: retry a few times."""
    for n in range(tries):
        req = urllib.request.Request(API + path, data=json.dumps(body).encode() if body else None,
                                     method="POST" if body else "GET")
        try:
            with urllib.request.urlopen(req, timeout=5) as r:
                return json.load(r)
        except OSError:
            if n == tries - 1:
                raise
            time.sleep(1 + n)


def apply(image):
    try:
        colour = wc.led_colour(image)
    except (subprocess.CalledProcessError, OSError) as e:
        log("cannot read", image, e)
        return
    key = f"{image} {os.stat(image).st_mtime:.0f} {colour}"
    try:
        with open(STATE) as f:
            if f.read().strip() == key:
                return
    except OSError:
        pass
    try:
        data = api("/color/").get("data") or {}
        brightness = next((v["profiles"]["static"]["start"]["brightness"] for v in data.values()
                           if v.get("profiles", {}).get("static", {}).get("start", {}).get("brightness")), 1)
        r, g, b = (int(colour[i:i + 2], 16) for i in (1, 3, 5))
        api("/color/all", {"color": {"red": r, "green": g, "blue": b, "brightness": brightness}})
    except OSError as e:   # OpenLinkHub not running: try again on the next change
        log("OpenLinkHub unreachable:", e)
        return
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    with open(STATE, "w") as f:
        f.write(key + "\n")
    log(f"RGB {colour} (brightness {brightness}) from {image}")


def setup():
    """(Re)read the wallpaper config and watch what matters for it."""
    for wd in list(watches):
        libc.inotify_rm_watch(fd, wd)
    watches.clear()
    watch(CFG, IN_CLOSE_WRITE | IN_MOVED_TO)   # appletsrc / kdeglobals are replaced atomically
    try:
        wall = wc.desktop_wallpaper(APPLETSRC)
    except OSError:
        wall = None
    if wall and wall[0] == "slideshow":
        for top in wall[1]:
            for d, _, _ in os.walk(top):
                watch(d, IN_OPEN | IN_CREATE)
        log("slideshow:", ", ".join(wall[1]))
    elif wall and wall[0] == "image":
        image = wc.resolve(wall[1], mode())
        if image:
            apply(image)
    return wall


def notify_ready():
    addr = os.environ.get("NOTIFY_SOCKET")
    if addr:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        s.connect("\0" + addr[1:] if addr.startswith("@") else addr)
        s.sendall(b"READY=1")
        s.close()


wall = setup()
notify_ready()
last_open, pending_cfg, slide = None, False, None
while True:
    ready, _, _ = select.select([fd], [], [], SETTLE)
    if not ready:   # quiet: act on what the burst left
        if pending_cfg:
            pending_cfg, last_open = False, None
            wall = setup()
        if slide:
            apply(slide)
            slide = None
        continue
    buf = os.read(fd, 65536)
    i = 0
    while i < len(buf):
        wd, mask, _, ln = struct.unpack_from("iIII", buf, i)
        name = os.fsdecode(buf[i + 16:i + 16 + ln].rstrip(b"\0"))
        i += 16 + ln
        folder = watches.get(wd)
        if folder is None:
            continue
        if folder == CFG:
            if name in ("plasma-org.kde.plasma.desktop-appletsrc", "kdeglobals"):
                pending_cfg = True
        elif mask & IN_CREATE and mask & IN_ISDIR:
            watch(os.path.join(folder, name), IN_OPEN | IN_CREATE)
        elif mask & IN_OPEN and not mask & IN_ISDIR and name.lower().endswith(wc.IMAGE_EXT):
            path = os.path.join(folder, name)
            if path == last_open:
                slide = path   # opened twice in a row: the new slide
            last_open = path
