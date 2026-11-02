#!/usr/bin/env python3
"""Rename a copied Plasma Style: set KPlugin Id and Name in metadata.json. A style that only has
the legacy metadata.desktop (Plasma 6 warns about it on every load) gets a metadata.json instead.
usage: metadata-json.py STYLE_DIR NAME"""
import configparser, json, os, sys

style_dir, name = sys.argv[1], sys.argv[2]
desktop = os.path.join(style_dir, "metadata.desktop")
meta = os.path.join(style_dir, "metadata.json")

if os.path.exists(meta):
    with open(meta, encoding="utf-8") as f:
        data = json.load(f)
    data.setdefault("KPlugin", {}).update(Id=name, Name=name)
    for k in [k for k in data["KPlugin"] if k.startswith("Name[")]:   # translated names
        del data["KPlugin"][k]
    with open(meta, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
        f.write("\n")
    if os.path.exists(desktop):
        os.remove(desktop)
    sys.exit(0)

ini = configparser.ConfigParser(interpolation=None, strict=False)
ini.optionxform = str
ini.read(desktop, encoding="utf-8")
e = ini["Desktop Entry"] if ini.has_section("Desktop Entry") else {}

author = {k: v for k, v in (("Name", e.get("X-KDE-PluginInfo-Author")),
                            ("Email", e.get("X-KDE-PluginInfo-Email"))) if v}
plugin = {
    "Authors": [author] if author else [],
    "Description": e.get("Comment", ""),
    "EnabledByDefault": True,
    "Id": name,
    "License": e.get("X-KDE-PluginInfo-License", ""),
    "Name": name,
    "Version": e.get("X-KDE-PluginInfo-Version", ""),
    "Website": e.get("X-KDE-PluginInfo-Website", ""),
}
data = {"KPlugin": {k: v for k, v in plugin.items() if v not in ("", [])},
        "X-Plasma-API": e.get("X-Plasma-API", "5.0")}
with open(meta, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4, ensure_ascii=False)
    f.write("\n")
os.remove(desktop)
