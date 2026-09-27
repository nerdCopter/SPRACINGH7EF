# 03 Firmware image format (EXST)

[Back to index](../README.md) | Previous: [Flash map](02-flash-map-and-bootloader.md) | Next: [Backup](04-backup.md)

The firmware for this board is an **EXST image**: a fixed 1 MiB block that the bootloader checks with an MD5 hash before it runs it.

## Layout

| Part | Location in the 1 MiB image | Notes |
|---|---|---|
| Firmware code | offset 0 to 0xFFFBF | padded with zeros to fill the block |
| Bootloader block | last 64 bytes, offset 0xFFFC0 to 0xFFFFF (flash address 0x901FFFC0) | contains the MD5 |
| MD5 hash | last 16 bytes of the block, offset 0xFFFF0 | see rule below |

Source: Betaflight's EXST doc **[SRC]** ([link](11-sources-and-glossary.md)) and the images in [`data/reference-images`](../data/reference-images) **[HW]**.

## The hash rule (checked by script)

> MD5 of the whole 1 MiB image, with the last 16 bytes set to zero, equals the last 16 bytes.

Checked with [`tools/exst_hex_to_bin.py`](../tools/exst_hex_to_bin.py) (for hex files) and [`tools/exst_check_bin.py`](../tools/exst_check_bin.py) (for `.bin` files and dumped partitions). All of these pass **[HW]**:

| Image | Result |
|---|---|
| Firmware partition read from the factory board | PASS |
| Firmware partition read from the broken board before repair | PASS |
| Betaflight 2026.12.0-alpha H7EF build (hex and bin) | PASS |
| Official SP Racing H7RF release 4.5.0 (hex and bin) | PASS |

The rule does not apply to the system partition (it has no such hash).

Two wrong guesses that fail: MD5 of the first 1 MiB minus 64 bytes, and MD5 of the image without zeroing the hash bytes.

The Betaflight doc says byte 1 of the 64-byte block selects the hash method. In every real image checked, byte 1 is 0x00 even though the hash is present. Treat the doc as not matching real files on this point. **[HW]**

## Hex file vs bin file

| File | What it is |
|---|---|
| `.hex` | Intel HEX text. A good EXST hex is **one** contiguous block: start 0x90100000, length 0x100000 |
| `.bin` | The same 1 MiB as raw bytes. This is what `dfu-util` writes |

Both build systems (Betaflight and EmuFlight, same Makefile mechanism) normally leave the `.bin` in `obj/` after a build; it is only removed by `make clean`. **Correction 2026-09-27:** an earlier version of this doc said the build always deletes the `.bin`, based on one Betaflight build where it was missing afterward. Rebuilding EmuFlight's `feat/exst-image-packaging` branch fresh on 2026-09-27 left the `.bin` in place, so that is not the normal behaviour. Why that one file was missing is **[UNV]**.
Recover it from the hex, with checks, using the tool:

```
python3 tools/exst_hex_to_bin.py path/to/image.hex path/to/image.bin
```

The tool refuses anything that is not one 1 MiB block at 0x90100000 with a correct hash. It exits with an error and writes nothing. **[HW]**
It accepts the Betaflight hexes in [`data/reference-images`](../data/reference-images) and rejects the three-block hex described below.

## How the Betaflight build makes the image

From the owner's build of Betaflight 2026.12.0-alpha (git `e5071ce4e`), target `STM32H730_SPRACINGH7EF`. Full log: [`data/evidence/betaflight-build-log-spracingh7ef.txt`](../data/evidence/betaflight-build-log-spracingh7ef.txt). **[SRC]** (build output as pasted)

| Step | What the log shows |
|---|---|
| 1. Link | Code goes into region `OCTOSPI1_CODE`, 1,048,512 bytes available; 585,405 used (55.83%). Region `EXST_HASH` is 64 bytes (100% used). |
| 2. Make an unpatched `.bin` from the program | `..._UNPATCHED.bin` |
| 3. Pad it to 1 MiB with zeros | two `dd` steps, 1,048,576 bytes each |
| 4. Compute the MD5 and patch it into the last 16 bytes | last 16 bytes of the final image: `e3ba896d f9c9e838 8a0f829f e178c440` |
| 5. Put the hash block back into the program file and build the `.hex` from the patched `.bin` at address 0x90100000 | log line "VMA Adjust 0x90100000" |

The `.bin` is normally kept in `obj/` after this. It happened to be missing after this particular build; cause **[UNV]**.

Memory layout in the program file: interrupt vector table at 0x90100000 (0x2CC bytes), code from 0x901002D0, hash section at 0x901FFFC0 (0x40 bytes), entry point 0x9016ED01. The firmware runs directly from the external flash (memory-mapped through the OctoSPI peripheral); the chip's internal flash holds only the bootloader. **[SRC]**

## What a bad image looks like

An image is **not** valid for this board if the hex has more than one block, does not start at 0x90100000, is not exactly 1 MiB, or fails the hash rule.
Example seen in this project: a hex with three blocks (716 bytes at 0x90100000, 396,388 bytes at 0x901002D0 after a 4-byte gap, and 64 zero bytes at 0x901FFFC0).
Writing it to the board completed, but verification failed at 0x901002D0 (expected byte 0x11, read 0x01). The cause is **[UNV]**. Always run
[`tools/exst_hex_to_bin.py`](../tools/exst_hex_to_bin.py) on an image first; it rejects this shape. **[HW]** for the rejection.

## Tool: list the blocks in any hex

```
python3 tools/exst_hexmap.py file.hex
```

Prints each contiguous block's start, length, and last 16 bytes. See [`tools/exst_hexmap.py`](../tools/exst_hexmap.py).
