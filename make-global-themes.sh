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
# Paths under this home (e.g. the wallpaper) must work for any user name: userDataPath() is the home folder.
sed -i "s|\"file://$HOME/|\"file://\" + userDataPath() + \"/|g" "$TMP/layout.js"
cat >> "$TMP/layout.js" <<'JS'

// Desktop widget positions (x,y,width,height) inside the area left free by the panels,
// computed from the screen size so the layout also fits resolutions other than 1920x1080.
var PANELS_HEIGHT = 136;   // top bar + dock: screen height minus the free desktop area
desktops().forEach(function (d) {
    var geo = [];
    var r = screenGeometry(d.screen);
    var W = Math.round(r.width), H = Math.round(r.height) - PANELS_HEIGHT;
    d.widgets().forEach(function (w) {
        var g = null;
        if (w.type === "com.github.prayag2.modernclock") {
            g = (Math.round(W / 2) - 304) + "," + (H - 208) + ",640,160";
        } else if (w.type === "luisbocanegra.audio.visualizer") {
            w.currentConfigGroup = ["General"];
            g = ((w.readConfig("orientation", "2") == "3") ? (W - 160) : 0) + ",0,160," + H;
        }
        if (g) geo.push("Applet-" + w.id + ":" + g + ",0");
    });
    d.currentConfigGroup = [];
    d.writeConfig("ItemGeometries-" + Math.round(r.width) + "x" + Math.round(r.height), geo.join(";") + ";");
    d.writeConfig("ItemGeometriesHorizontal", geo.join(";") + ";");
    d.reloadConfig();
});

// The dump leaves out which plasmoids the system tray shows: add the extra ones back, and drop
// the laptop ones (desktop PC). Dropped items stay in knownItems, or the tray re-adds them as new.
panels().forEach(function (p) {
    p.widgets("org.kde.plasma.systemtray").forEach(function (w) {
        var add = ["org.kde.plasma.trash", "org.kde.plasma.diskquota"];
        var drop = ["org.kde.plasma.battery", "org.kde.plasma.brightness", "org.kde.plasma.dwellclicker"];
        w.currentConfigGroup = ["General"];
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
