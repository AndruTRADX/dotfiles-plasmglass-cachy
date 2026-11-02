#!/usr/bin/env python3
"""Set many keys of a KDE config file in one read + one atomic write (instead of one
kwriteconfig6 process per key). Keys and lines outside the ones given are left as they are.
usage: kconf.py FILE < lines "Group<TAB>Key<TAB>Value"   (top-level groups only)"""
import os, re, sys, tempfile

path = sys.argv[1]
wanted = {}  # group -> {key: value}, in input order
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line:
        continue
    group, key, value = line.split("\t", 2)
    wanted.setdefault(group, {})[key] = value

try:
    lines = open(path, encoding="utf-8").read().splitlines()
except FileNotFoundError:
    lines = []

out, group, pending = [], None, {}

def flush():
    """Append keys of the current group that were not already in the file."""
    if pending:
        while out and out[-1] == "":   # keep new keys inside the group, before its blank line
            out.pop()
        out.extend(f"{k}={v}" for k, v in pending.items())
        out.append("")

for line in lines:
    m = re.fullmatch(r"\[([^\]]*)\](.*)", line)
    if m:
        flush()
        group = m.group(1) if not m.group(2) else None   # nested groups are never ours
        pending = dict(wanted.pop(group, {})) if group else {}
        out.append(line)
        continue
    key = line.split("=", 1)[0].strip() if "=" in line else None
    if key is not None and key in pending:
        out.append(f"{key}={pending.pop(key)}")
    else:
        out.append(line)
flush()

for group, keys in wanted.items():   # groups not in the file yet
    if out and out[-1] != "":
        out.append("")
    out.append(f"[{group}]")
    out.extend(f"{k}={v}" for k, v in keys.items())
    out.append("")

while out and out[-1] == "":
    out.pop()
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(os.path.abspath(path)), prefix=".kconf-")
with os.fdopen(fd, "w", encoding="utf-8") as f:
    f.write("\n".join(out) + "\n")
if os.path.exists(path):
    os.chmod(tmp, os.stat(path).st_mode & 0o7777)
os.replace(tmp, path)
