#!/usr/bin/env python3
"""Set KDE global shortcuts through KGlobalAccel's D-Bus API: they work at once (no logout)
and KDE itself saves them to ~/.config/kglobalshortcutsrc.
usage: shortcuts.py < lines "Component<TAB>Action<TAB>Keys"
       Keys = comma-separated list such as "Meta+Q, Alt+F4", or "none" to unbind.
The list replaces every key the action had, so repeat the defaults you want to keep."""
import json, subprocess, sys

BUS = ["busctl", "--user", "--json=short", "call", "org.kde.kglobalaccel", "/kglobalaccel", "org.kde.KGlobalAccel"]
MODS = {"shift": 0x02000000, "ctrl": 0x04000000, "alt": 0x08000000, "meta": 0x10000000}
NAMED = {"esc": 0x01000000, "tab": 0x01000001, "backspace": 0x01000003, "return": 0x01000004,
         "del": 0x01000007, "print": 0x01000009, "home": 0x01000010, "end": 0x01000011,
         "left": 0x01000012, "up": 0x01000013, "right": 0x01000014, "down": 0x01000015,
         "pgup": 0x01000016, "pgdown": 0x01000017, "space": 0x20}
NAMED.update({f"f{n}": 0x01000030 + n - 1 for n in range(1, 13)})
NAMED.update({"volume down": 0x01000070, "volume mute": 0x01000071, "volume up": 0x01000072,  # multimedia keys
              "media play": 0x01000080, "media previous": 0x01000082, "media next": 0x01000083,
              "screensaver": 0x010000BA, "tools": 0x010000F1, "battery": 0x010000FE})


def key_code(combo):
    """'Meta+Shift+Q' -> the integer Qt uses for that key combination."""
    *mods, key = [part.strip() for part in combo.split("+")] if combo != "+" else ["+"]
    code = NAMED.get(key.lower()) or (ord(key.upper()) if len(key) == 1 else None)
    if code is None or any(m.lower() not in MODS for m in mods):
        sys.exit(f"shortcuts.py: cannot read the key '{combo}'")
    return code | sum(MODS[m.lower()] for m in mods)


def call(method, signature, *args):
    out = subprocess.run(BUS + [method, signature, *map(str, args)], capture_output=True, text=True)
    if out.returncode:
        sys.exit(f"shortcuts.py: {method} failed: {out.stderr.strip()}")
    return json.loads(out.stdout)["data"] if out.stdout.strip() else []


wanted = []  # (action id = [component, action, component name, action name], [key codes], keys as typed)
actions = {}  # component -> {action: action id}
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line.strip() or line.lstrip().startswith("#"):
        continue
    component, action, keys = line.split("\t")
    if component not in actions:
        actions[component] = {a[1]: a for a in call("allActionsForComponent", "as", 1, component)[0]}
    if action not in actions[component]:
        print(f"  skipped (not on this machine): {component} / {action}", file=sys.stderr)
        continue
    codes = [] if keys.strip() == "none" else [key_code(k.strip()) for k in keys.split(",")]
    wanted.append((actions[component][action], codes, keys.strip()))

# Twice: on the second round an action can take a key that another one released on the first.
for _ in range(2):
    for action_id, codes, _keys in wanted:
        sequences = [x for code in codes for x in (4, code, 0, 0, 0)]  # a(ai): one key sequence = 4 ints
        call("setForeignShortcutKeys", "asa(ai)", 4, *action_id, len(codes), *sequences)

failed = 0
for action_id, codes, keys in wanted:
    now = [seq[0][0] for seq in call("shortcutKeys", "as", 4, *action_id)[0] if seq[0][0]]
    if sorted(now) != sorted(codes):
        print(f"  NOT applied (key taken by another action?): {action_id[0]} / {action_id[1]} = {keys}", file=sys.stderr)
        failed += 1
print(f"Shortcuts: {len(wanted) - failed} set, {failed} failed.")
sys.exit(1 if failed else 0)
