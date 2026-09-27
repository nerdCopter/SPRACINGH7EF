# 06 Flash firmware

[Back to index](../README.md) | Before this: [Repair and restore](05-repair-restore.md), [Firmware image format](03-firmware-image-format.md)

This is the path that worked on the real board: write the 1 MiB image with `dfu-util`, read it back, compare, then restart.

## Use the right firmware

- The firmware must be built for **SPRACINGH7EF** (Betaflight target name). Firmware for the H7RF is a different board ([differences](08-h7ef-vs-h7rf.md)). The manual warns that flashing the wrong firmware can permanently damage the board. **[SRC]**
- The image must be an [EXST image](03-firmware-image-format.md): one 1 MiB block at 0x90100000 whose hash checks out.
- Example that was flashed and read back on the real board: [`data/reference-images/betaflight-2026.12.0-alpha-SPRACINGH7EF`](../data/reference-images/betaflight-2026.12.0-alpha-SPRACINGH7EF). It is an alpha build, good for testing. For flying, use a current stable release. **[SRC]** (manual p.14 says to install the latest stable firmware)

## Steps

1. Get the image as a `.bin`. If you only have the `.hex`, convert it. The tool checks the image first:
   `python3 tools/exst_hex_to_bin.py path/image.hex path/image.bin`
   It must print `MD5 rule (hash bytes zeroed): PASS`. If it prints FAIL, stop: the image is not valid for this board.
2. Back up the board ([backup guide](04-backup.md)).
3. Enter [DFU mode](02-flash-map-and-bootloader.md#enter-bootloader-dfu-mode). Only one board plugged in.
4. Write the image. Do **not** add `:leave` yet:
   `dfu-util -a 0 -s 0x90100000 -D path/image.bin`
   Success looks like `Download done.` and `File downloaded successfully`. The bootloader erases the needed pages by itself. **[HW]**
5. Read it back and compare:
   `dfu-util -a 0 -s 0x90100000:0x100000 -U readback.bin && cmp readback.bin path/image.bin && echo VERIFY PASS` **[HW]**
6. Check that the other partitions did not change: run a full backup and compare, or `verify` against the backup from step 2.
7. Unplug USB (no BIND), plug in again. Check LEDs, COM port, and Betaflight Configurator ([what to expect](05-repair-restore.md#what-to-expect)).

The manual's own command is the same with `:leave` at the end (`-s 0x90100000:leave`), which restarts the board straight after writing. **[SRC]**

## Result on the real board

Writing the 1 MiB Betaflight image took a few seconds, returned no error, and read back byte-identical. **[HW]** The board did not start until its system partition was also restored ([case study](07-case-study.md)).

## Configurator programs

Flashing with Betaflight Configurator on this board was not tested in this project. **[UNV]** Configurator programs have a "Full chip erase" option that can wipe the system partition ([safety rules](01-safety-rules.md)). If you use one, keep it off.

## If the new firmware does not start

1. Enter DFU mode.
2. Write back the firmware from your backup: `dfu-util -a 0 -s 0x90100000 -D data/backups/<your-backup>/firmware.bin` (then read back as in step 5), or use `./scripts/spracingh7ef-flash-restore.sh <backup-dir>`.
3. Or erase the firmware with bootloader function 7 ([functions](02-flash-map-and-bootloader.md#bootloader-functions)), then flash again.
