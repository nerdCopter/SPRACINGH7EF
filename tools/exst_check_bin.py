#!/usr/bin/env python3
"""Check a raw 1 MiB EXST image (a .bin, or a firmware.bin dumped from the board).
Rule: MD5(image with the last 16 bytes zeroed) == last 16 bytes.
Usage: exst_check_bin.py <file.bin> [more.bin ...]
Exit 0 if all pass, 1 otherwise."""
import hashlib, sys

if len(sys.argv) < 2:
    print(__doc__); sys.exit(2)
rc = 0
for path in sys.argv[1:]:
    img = open(path, "rb").read()
    if len(img) != 0x100000:
        print("FAIL", path, "size", len(img), "!= 1048576"); rc = 1; continue
    ok = hashlib.md5(img[:-16] + b"\0" * 16).digest() == img[-16:]
    print("PASS" if ok else "FAIL", path, "stored hash", img[-16:].hex())
    rc |= 0 if ok else 1
sys.exit(rc)
