#!/usr/bin/env python3
"""Convert an EXST Intel-HEX (one 1 MiB block at 0x90100000) to a .bin and check it.
Usage: exst_hex_to_bin.py <in.hex> <out.bin>
Checks: single contiguous block, start 0x90100000, length 0x100000,
MD5(image with the 16 hash bytes zeroed) == stored hash (last 16 bytes).
Exit 0 on success, 1 on any failed check."""
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

def main():
    if len(sys.argv) != 3:
        print(__doc__); return 2
    blocks = parse(sys.argv[1])
    ok = True
    print("blocks:", [(hex(a), len(d)) for a, d in blocks])
    if len(blocks) != 1 or blocks[0][0] != 0x90100000 or len(blocks[0][1]) != 0x100000:
        print("FAIL: need exactly one 0x100000-byte block at 0x90100000"); return 1
    img = bytes(blocks[0][1])
    md5_ok = hashlib.md5(img[:-16] + b"\0" * 16).digest() == img[-16:]
    print("MD5 rule (hash bytes zeroed):", "PASS" if md5_ok else "FAIL")
    if not md5_ok:
        return 1
    open(sys.argv[2], "wb").write(img)
    print("wrote", sys.argv[2], len(img), "bytes; sha256", hashlib.sha256(img).hexdigest())
    return 0

sys.exit(main())
