#!/usr/bin/env python3
"""List the contiguous blocks of an Intel HEX file.
For a single 1 MiB block, also apply the EXST hash rule:
MD5(image with the last 16 bytes zeroed) == last 16 bytes.
Usage: exst_hexmap.py <file.hex> [more.hex ...]"""
import hashlib, sys

def parse(path):
    base, blocks, cur = 0, [], None
    for line in open(path):
        line = line.strip()
        if not line.startswith(':'):
            continue
        n, a, t = int(line[1:3], 16), int(line[3:7], 16), int(line[7:9], 16)
        data = bytes.fromhex(line[9:9 + 2 * n])
        if t == 4:
            base = int(line[9:13], 16) << 16
        elif t == 0:
            addr = base + a
            if cur and cur[0] + len(cur[1]) == addr:
                cur[1] += data
            else:
                cur = [addr, bytearray(data)]
                blocks.append(cur)
    return blocks

if len(sys.argv) < 2:
    print(__doc__); sys.exit(2)
for path in sys.argv[1:]:
    print(path)
    blocks = parse(path)
    for addr, data in blocks:
        print("  start 0x%08x  length %d (0x%x)  end 0x%08x  last16 %s" % (addr, len(data), len(data), addr + len(data), bytes(data[-16:]).hex()))
    if len(blocks) == 1 and len(blocks[0][1]) == 0x100000:
        img = bytes(blocks[0][1])
        ok = hashlib.md5(img[:-16] + b"\0" * 16).digest() == img[-16:]
        print("  EXST hash rule:", "PASS" if ok else "FAIL")
