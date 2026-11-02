#!/usr/bin/env python3
"""Turn on OpenLinkHub's RAM RGB support in its config.json.
usage: openlinkhub-memory.py CONFIG SMBUS SKU DDR_TYPE   (e.g. i2c-6 CMH32GX5M2B6400C36 5)
The SKU is set by hand because the BIOS's "SPD Write Disable" stops OpenLinkHub from reading it."""
import json, os, sys, tempfile

path, bus, sku, ddr = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
with open(path, encoding="utf-8") as f:
    cfg = json.load(f)
cfg.update(memory=True, memorySmBus=bus, memorySku=sku, memoryType=ddr)

st = os.stat(path)
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".config-")
with os.fdopen(fd, "w", encoding="utf-8") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
os.chown(tmp, st.st_uid, st.st_gid)
os.chmod(tmp, st.st_mode & 0o7777)
os.replace(tmp, path)
