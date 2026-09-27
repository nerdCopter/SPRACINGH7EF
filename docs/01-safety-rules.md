# 01 Safety rules

[Back to index](../README.md)

Follow these before every session. Each rule says why.

1. **Read before you write.** Run a [backup](04-backup.md) first. It only reads and cannot change the board. **[HW]**
2. **Back up a working board of the same model before you repair a broken one.** The repair source is that backup ([repair guide](05-repair-restore.md)). **[HW]**
3. **One DFU device at a time.** Both scripts stop if they see more than one. Two boards in bootloader mode make it easy to write to the wrong one.
4. **Never use bootloader functions 8, 15, 16 or 17.** The manual marks them as destructive ([functions](02-flash-map-and-bootloader.md#bootloader-functions)). Function 15 erases the CPU bootloader for good; the board then needs factory repair. **[SRC]**
5. **Do not use "Full chip erase" on this board.** A configurator's full-chip erase sends an erase command for every page of the external flash, including the system partition. On the broken board the erase covered all 256 pages, and afterwards the system partition was blank and the board no longer booted ([case study](07-case-study.md)). The link between the erase and the blank partition is **[INF]**; that restoring the partition fixed the board is **[HW]**.
6. **Betaflight Configurator has the same kind of erase.** Its source (master, `src/js/protocols/usbdfu.js`) erases all pages when "Full chip erase" is on. Its default is off. Keep it off for this board. **[SRC]** (not tested on hardware)
7. **Flash without `:leave` first, read back, then let the board restart.** You can compare the flash with the file before the board runs it. **[HW]**
8. **Keep backups read-only and check them.** The backup script sets files read-only and writes `SHA256SUMS`. Run `spracingh7ef-flash-backup.sh check <dir>` before you trust a backup. **[HW]**
9. **Do not write config or group 0 from another board** unless you must. Config is per-board settings. Group 0 was blank on both boards read ([map](02-flash-map-and-bootloader.md)). **[HW]**

## What can go wrong and what to do

| Problem | What it means | Do this |
|---|---|---|
| Board does not appear in `dfu-util -l` even with BIND held | CPU bootloader may be damaged | Stop. See [troubleshooting](09-troubleshooting.md). This repo cannot fix it. |
| `dfu-util` prints an error during a write | Write may be incomplete | Read the partition back, compare, write again. Do not power off mid-write. |
| Restore script says the backup failed its checksum test | Backup file is damaged | Use another copy of the backup. Never restore from a damaged file. |
