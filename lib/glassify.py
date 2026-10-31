#!/usr/bin/env python3
"""Make the background of a Plasma Style SVG(Z) see-through, keeping margins/shadows/masks.
usage: glassify.py FILE FACTOR   (FACTOR 0..1 = share of the original opacity to keep)
exit 0 = file rewritten, 3 = skipped (nothing to change / no usable mask)"""
import gzip, re, sys
import xml.etree.ElementTree as ET

for p, u in {"": "http://www.w3.org/2000/svg",
             "inkscape": "http://www.inkscape.org/namespaces/inkscape",
             "sodipodi": "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd",
             "xlink": "http://www.w3.org/1999/xlink",
             "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
             "cc": "http://creativecommons.org/ns#",
             "dc": "http://purl.org/dc/elements/1.1/"}.items():
    ET.register_namespace(p, u)

path, factor = sys.argv[1], float(sys.argv[2])
raw = open(path, "rb").read()
gz = raw[:2] == b"\x1f\x8b"
root = ET.fromstring(gzip.decompress(raw) if gz else raw)

TINT = re.compile(r"^(?:[a-z]+-)*(?:center|top|bottom|left|right|topleft|topright|bottomleft|bottomright)$")
SKIP = ("mask", "hint", "shadow")
SHAPES = {"rect", "path", "circle", "ellipse", "polygon"}
local = lambda t: t.rsplit("}", 1)[-1]

def set_opacity(el):
    d = dict(kv.split(":", 1) for kv in el.get("style", "").split(";") if ":" in kv)
    if d.get("fill", "").strip() == "none":
        return False
    old = float(d.get("opacity", "1"))
    d["opacity"] = f"{old * factor:.4f}"
    el.set("style", ";".join(f"{k}:{v}" for k, v in d.items()))
    return True

changed = 0
def walk(el, in_tint, protected):
    global changed
    i = el.get("id", "")
    protected = protected or any(s in i for s in SKIP)
    in_tint = in_tint or bool(TINT.match(i))
    if in_tint and not protected and local(el.tag) in SHAPES and set_opacity(el):
        changed += 1
    for c in el:
        walk(c, in_tint, protected)
walk(root, False, False)

# Plasma looks for masks named "mask-<prefix>center" (e.g. mask-floating-center), not "<prefix>-mask-center".
# Without one it derives the panel shape from the background's alpha, which is empty once faded: PanelView
# then falls back to the whole window and, because an empty mask never "changes", never refreshes it when the
# panel resizes (a fit-content dock stops growing its click/blur area). So give every faded frame an opaque mask.
parent = {c: p for p in root.iter() for c in p}
ids = {e.get("id"): e for e in root.iter() if e.get("id")}
had_mask = any("mask" in i for i in ids) or "floating-center" in ids
CENTER = re.compile(r"^((?:[a-z]+-)*)center$")
for i, e in list(ids.items()):
    m = CENTER.match(i)
    if not m or any(s in i for s in SKIP) or local(e.tag) not in SHAPES:
        continue
    mid = f"mask-{m.group(1)}center"
    if mid in ids:
        continue
    attrs = {k: e.get(k) for k in ("x", "y", "width", "height", "transform") if e.get(k)}
    mk = ET.Element(e.tag, attrs)
    mk.set("id", mid)
    mk.set("style", "fill:#000000;fill-opacity:1;opacity:1;stroke:none")
    parent[e].insert(list(parent[e]).index(e) + 1, mk)
    ids[mid] = mk

if not changed or not had_mask:
    sys.exit(3)
out = ET.tostring(root, encoding="utf-8", xml_declaration=True)
open(path, "wb").write(gzip.compress(out) if gz else out)
print(changed)
