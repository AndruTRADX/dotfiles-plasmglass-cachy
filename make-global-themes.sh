#!/usr/bin/env bash
# Builds the "Liquid Glass Dark" and "Liquid Glass Light" Global Themes from the CURRENT desktop:
# colours, icons, cursor, widget style, Plasma Style, window decoration, splash and the panel/widget layout.
# Re-run it after changing the panels or widgets, then commit.
# Usage: ./make-global-themes.sh
#
# Splash screens and previews are taken from the MacTahoe Global Themes (light one downloaded from upstream).
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
OUT="home/.local/share/plasma/look-and-feel"
SRC_DARK="$HOME/.local/share/plasma/look-and-feel/com.github.vinceliuice.MacTahoe-Dark"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
source lib/common.sh
[[ -n "$QDBUS" ]] || { echo "qdbus not found" >&2; exit 1; }

clone_pinned "$MACTAHOE_KDE_URL" "$MACTAHOE_KDE_REV" "$TMP/mactahoe"
SRC_LIGHT="$TMP/mactahoe/plasma/look-and-feel/com.github.vinceliuice.MacTahoe-Light"
[[ -d "$SRC_DARK" ]] || SRC_DARK="$TMP/mactahoe/plasma/look-and-feel/com.github.vinceliuice.MacTahoe-Dark"

# ---------------------------------------------------------------- layout (same for both)
# dumpCurrentLayoutJS stores desktop widget positions by applet id, but ids change on every load,
# so append a step that rebuilds the position map from the widgets actually created.
"$QDBUS" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.dumpCurrentLayoutJS > "$TMP/layout.js"
# Paths under this home (wallpaper, slideshow folder, launcher icon) must work for any user name:
# userDataPath() is the home folder.
sed -i -e "s|\"file://$HOME/|\"file://\" + userDataPath() + \"/|g" -e "s|\"$HOME/|userDataPath() + \"/|g" "$TMP/layout.js"

# Desktop widget positions (x,y,w,h) by plugin, read from the live desktop: wherever you dragged them
positions="$(python3 - "$CFG/plasma-org.kde.plasma.desktop-appletsrc" <<'PY'
import json, re, sys
groups, cur = {}, None
for line in open(sys.argv[1], encoding="utf-8"):
    line = line.rstrip("\n")
    if line.startswith("["):
        cur = line; groups[cur] = {}
    elif cur and "=" in line:
        k, v = line.split("=", 1); groups[cur][k] = v
pos = {}
for head, keys in groups.items():
    if re.fullmatch(r"\[Containments\]\[\d+\]", head) and keys.get("plugin") == "org.kde.plasma.folder":
        for item in keys.get("ItemGeometriesHorizontal", "").split(";"):
            m = re.fullmatch(r"Applet-(\d+):(-?\d+,-?\d+,\d+,\d+),\d+", item)
            plugin = m and groups.get(f"{head}[Applets][{m.group(1)}]", {}).get("plugin")
            if plugin:
                pos[plugin] = m.group(2)
print(json.dumps(pos))
PY
)"
printf '\nvar POSITIONS = %s;\n' "$positions" >> "$TMP/layout.js"
cat >> "$TMP/layout.js" <<'JS'
desktops().forEach(function (d) {
    var geo = [];
    var r = screenGeometry(d.screen);
    d.widgets().forEach(function (w) {
        if (w.type === "com.jaxparrow07.macoswidgets.weather") {
            // the dump drops the city name (non-ASCII?), but keeps its coordinates
            w.currentConfigGroup = ["General"];
            w.writeConfig("location", "Bogotá");
        }
        if (POSITIONS[w.type]) geo.push("Applet-" + w.id + ":" + POSITIONS[w.type] + ",0");
    });
    d.currentConfigGroup = [];
    d.writeConfig("ItemGeometries-" + Math.round(r.width) + "x" + Math.round(r.height), geo.join(";") + ";");
    d.writeConfig("ItemGeometriesHorizontal", geo.join(";") + ";");
    d.reloadConfig();
});

// The dump leaves out the system tray's own settings: add the extra plasmoids back, drop the laptop
// ones (desktop PC) and the trash (it lives in the dock), and hide the rarely used icons behind the
// arrow, as in macOS. Dropped items stay in knownItems, or the tray re-adds them as new.
panels().forEach(function (p) {
    p.widgets("org.kde.plasma.systemtray").forEach(function (w) {
        var add = ["org.kde.plasma.diskquota"];
        var drop = ["org.kde.plasma.battery", "org.kde.plasma.brightness", "org.kde.plasma.dwellclicker",
                    "org.kde.plasma.trash"];
        w.currentConfigGroup = ["General"];
        w.writeConfig("hiddenItems", ["org.kde.plasma.clipboard", "org.kde.kdeconnect", "org.kde.plasma.weather",
                                      "org.kde.kscreen", "org.kde.plasma.diskquota", "steam", "Cachy-Update"]);
        ["extraItems", "knownItems"].forEach(function (k) {
            var v = w.readConfig(k, []);
            if (typeof v === "string") v = v ? v.split(",") : [];
            add.concat(k === "knownItems" ? drop : []).forEach(function (item) {
                if (v.indexOf(item) < 0) v.push(item);
            });
            if (k === "extraItems") v = v.filter(function (item) { return drop.indexOf(item) < 0; });
            w.writeConfig(k, v);
        });
        w.reloadConfig();
    });
});
JS

# ---------------------------------------------------------------- packages
build() {  # $1 = dark|light
  local mode="$1" Mode id name scheme icons deco style src dir
  if [[ "$mode" == dark ]]; then
    Mode=Dark;  scheme=AppleDarkPurple;  icons=MacTahoe-purple-dark;  deco=MacTahoe-Dark;  style="$DARK_STYLE-Glass";  src="$SRC_DARK"
  else
    Mode=Light; scheme=AppleLightPurple; icons=MacTahoe-purple-light; deco=MacTahoe-Light; style="$LIGHT_STYLE-Glass"; src="$SRC_LIGHT"
  fi
  id="com.github.andrutradx.liquidglass-$mode"; name="Liquid Glass $Mode"; dir="$OUT/$id"
  rm -rf "$dir"; mkdir -p "$dir/contents/layouts"
  cp -a "$src/contents/splash" "$src/contents/previews" "$dir/contents/"
  cp "$TMP/layout.js" "$dir/contents/layouts/org.kde.plasma.desktop-layout.js"

  cat > "$dir/metadata.json" <<EOF
{
    "KPackageStructure": "Plasma/LookAndFeel",
    "KPlugin": {
        "Authors": [ { "Name": "AndruTRADX" } ],
        "Category": "Global Themes (Plasma 6)",
        "Description": "Liquid glass ($mode): Apple Purple colours, MacTahoe icons and decoration, see-through Plasma Style and the AndruTRADX panel layout",
        "EnabledByDefault": true,
        "Id": "$id",
        "License": "GPLv3",
        "Name": "$name"
    },
    "Keywords": "Desktop;Workspace;Appearance;Look and Feel;Logout;Lock;Suspend;Shutdown;Hibernate;",
    "X-KDE-fallbackPackage": "org.kde.breeze.desktop",
    "X-Plasma-APIVersion": "2",
    "X-Plasma-MainScript": "defaults"
}
EOF

  cat > "$dir/contents/defaults" <<EOF
[kcminputrc][Mouse]
cursorTheme=capitaine-cursors

[kdeglobals][General]
ColorScheme=$scheme

[kdeglobals][Icons]
Theme=$icons

[kdeglobals][KDE]
LookAndFeelPackage=$id
widgetStyle=Darkly

[kdeglobals][Sounds]
Theme=Wii

[kwinrc][org.kde.kdecoration2]
BorderSize=Tiny
ButtonsOnLeft=XIA
ButtonsOnRight=
library=org.kde.kwin.aurorae.v2
theme=__aurorae__svg__$deco

[plasmarc][Theme]
name=$style
EOF
  echo "Built $dir"
}

build dark
build light
