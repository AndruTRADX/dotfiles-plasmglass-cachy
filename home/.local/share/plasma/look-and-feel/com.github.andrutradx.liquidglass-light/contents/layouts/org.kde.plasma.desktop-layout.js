var plasma = getApiVersion(1);

var layout = {
    "desktops": [
        {
            "applets": [
                {
                    "config": {
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        },
                        "/General": {
                            "appearance": "2",
                            "blurAlgorithm": "1",
                            "blurRadiusPx": "4",
                            "chromaStrengthPct": "16",
                            "cornerRadius": "73",
                            "realtimeRefraction": "false",
                            "refractIORx100": "180",
                            "refractScale": "",
                            "refractThickness": "35",
                            "specStrengthPct": "70",
                            "styleMode": "0",
                            "tintAlphaPct": "18"
                        }
                    },
                    "geometry.height": 0,
                    "geometry.width": 0,
                    "geometry.x": 0,
                    "geometry.y": 0,
                    "plugin": "com.jaxparrow07.macoswidgets.clock-square",
                    "title": "macOS Clock Digital"
                },
                {
                    "config": {
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        },
                        "/General": {
                            "appearance": "2",
                            "blurAlgorithm": "1",
                            "blurRadiusPx": "4",
                            "chromaStrengthPct": "16",
                            "cornerRadius": "73",
                            "realtimeRefraction": "false",
                            "refractIORx100": "180",
                            "refractScale": "",
                            "refractThickness": "35",
                            "specStrengthPct": "70",
                            "styleMode": "0",
                            "tintAlphaPct": "18"
                        }
                    },
                    "geometry.height": 0,
                    "geometry.width": 0,
                    "geometry.x": 0,
                    "geometry.y": 0,
                    "plugin": "com.jaxparrow07.macoswidgets.calendar",
                    "title": "macOS Calendar"
                },
                {
                    "config": {
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        },
                        "/General": {
                            "appearance": "2",
                            "blurAlgorithm": "1",
                            "blurRadiusPx": "4",
                            "chromaStrengthPct": "16",
                            "cornerRadius": "73",
                            "latitude": "4.711",
                            "longitude": "-74.0721",
                            "realtimeRefraction": "false",
                            "refractIORx100": "180",
                            "refractScale": "",
                            "refractThickness": "35",
                            "specStrengthPct": "70",
                            "styleMode": "0",
                            "temperatureUnit": "0",
                            "tintAlphaPct": "18"
                        }
                    },
                    "geometry.height": 0,
                    "geometry.width": 0,
                    "geometry.x": 0,
                    "geometry.y": 0,
                    "plugin": "com.jaxparrow07.macoswidgets.weather",
                    "title": "macOS Weather"
                },
                {
                    "config": {
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        },
                        "/General": {
                            "appearance": "2",
                            "blurAlgorithm": "1",
                            "blurRadiusPx": "4",
                            "chromaStrengthPct": "16",
                            "cornerRadius": "73",
                            "realtimeRefraction": "false",
                            "refractIORx100": "180",
                            "styleMode": "0",
                            "tintAlphaPct": "18"
                        }
                    },
                    "geometry.height": 0,
                    "geometry.width": 0,
                    "geometry.x": 0,
                    "geometry.y": 0,
                    "plugin": "com.jaxparrow07.macoswidgets.music",
                    "title": "macOS Music"
                }
            ],
            "config": {
                "/": {
                    "ItemGeometries-1920x1080": "Applet-662:32,48,176,176,0;Applet-663:224,48,176,176,0;Applet-664:32,240,368,176,0;Applet-665:32,432,368,176,0;",
                    "ItemGeometries-640x480": "Applet-628:0,0,160,352,0;Applet-629:480,0,160,192,0;",
                    "ItemGeometriesHorizontal": "Applet-662:32,48,176,176,0;Applet-663:224,48,176,176,0;Applet-664:32,240,368,176,0;Applet-665:32,432,368,176,0;",
                    "formfactor": "0",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.slideshow"
                },
                "/ConfigDialog": {
                    "DialogHeight": "630",
                    "DialogWidth": "810"
                },
                "/Wallpaper/org.kde.image/General": {
                    "Image": userDataPath() + "/Pictures/wallpapers/anime-girl-with-multicolored-eye.png"
                },
                "/Wallpaper/org.kde.slideshow/General": {
                    "Image": "file://" + userDataPath() + "/Pictures/wallpapers/hatsune-miku-6.png",
                    "SlidePaths": userDataPath() + "/Pictures/wallpapers/"
                }
            },
            "wallpaperPlugin": "org.kde.slideshow"
        }
    ],
    "panels": [
        {
            "alignment": "center",
            "applets": [
                {
                    "config": {
                        "/": {
                            "popupHeight": "499",
                            "popupWidth": "639"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        },
                        "/General": {
                            "favoritesPortedToKAstats": "true",
                            "icon": userDataPath() + "/.local/share/icons/menu-ghost.svg"
                        },
                        "/Shortcuts": {
                            "global": "Alt+F1"
                        }
                    },
                    "plugin": "org.kde.plasma.kickoff"
                },
                {
                    "config": {
                        "/Appearance": {
                            "widgetElements": "windowTitle",
                            "windowTitleFontBold": "true",
                            "windowTitleFontSize": "10",
                            "windowTitleFontSizeMode": "0",
                            "windowTitleHideEmpty": "true",
                            "windowTitleMarginsLeft": "6",
                            "windowTitleMarginsRight": "2",
                            "windowTitleSource": "0",
                            "windowTitleUndefined": ""
                        },
                        "/Behavior": {
                            "widgetMouseAreaLeftDoubleClickAction": "None",
                            "widgetMouseAreaMiddleClickAction": "None",
                            "widgetMouseAreaWheelEnabled": "false"
                        }
                    },
                    "plugin": "com.github.antroids.application-title-bar"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.appmenu"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.panelspacer"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "137",
                            "popupWidth": "216"
                        }
                    },
                    "plugin": "org.kde.plasma.shutdownorswitch"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.marginsseparator"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.systemtray"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.marginsseparator"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "451",
                            "popupWidth": "525"
                        },
                        "/Appearance": {
                            "autoFontAndSize": "false",
                            "customDateFormat": "ddd d MMM",
                            "dateDisplayFormat": "BesideTime",
                            "dateFormat": "custom",
                            "fontFamily": "SF Pro Text",
                            "fontSize": "10",
                            "fontWeight": "500",
                            "showDate": "true"
                        }
                    },
                    "plugin": "org.kde.plasma.digitalclock"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.showdesktop"
                }
            ],
            "config": {
                "/": {
                    "formfactor": "2",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                }
            },
            "floating": true,
            "floatingApplets": false,
            "height": 2.375,
            "hiding": "normal",
            "lengthMode": "fill",
            "location": "top",
            "maximumLength": 120,
            "minimumLength": 120,
            "offset": 0,
            "opacity": "translucent"
        },
        {
            "alignment": "center",
            "applets": [
                {
                    "config": {
                        "/General": {
                            "launchers": "applications:com.microsoft.VSCode.desktop,applications:jetbrains-clion.desktop,applications:org.kde.konsole.desktop,applications:brave-browser.desktop,applications:firefox.desktop,preferred://filemanager,applications:systemsettings.desktop"
                        }
                    },
                    "plugin": "org.kde.plasma.icontasks"
                }
            ],
            "config": {
                "/": {
                    "formfactor": "2",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                }
            },
            "floating": true,
            "floatingApplets": false,
            "height": 4,
            "hiding": "dodgewindows",
            "lengthMode": "fit",
            "location": "bottom",
            "maximumLength": 120,
            "minimumLength": 120,
            "offset": 0,
            "opacity": "translucent"
        }
    ],
    "serializationFormatVersion": "1"
}
;

plasma.loadSerializedLayout(layout);


var POSITIONS = {"com.jaxparrow07.macoswidgets.clock-square": "32,48,176,176", "com.jaxparrow07.macoswidgets.calendar": "224,48,176,176", "com.jaxparrow07.macoswidgets.weather": "32,240,368,176", "com.jaxparrow07.macoswidgets.music": "32,432,368,176"};
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
