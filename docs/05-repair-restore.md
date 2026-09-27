# 05 Repair and restore

[Back to index](../README.md) | Before this: [Backup](04-backup.md) | Next: [Flash firmware](06-flash-firmware.md)

Use this when a board will not start its firmware. Everything here was done on the real broken board on 2026-09-26; the story is in the [case study](07-case-study.md).

## Symptoms this fixes

| Symptom | Seen on the broken board |
|---|---|
| Green and blue LEDs solid, red LED blinking an error pattern | yes |
| The board stays in USB bootloader mode (`0483:df11`) after a normal power-up, never becomes a COM port | yes |
| A full read shows the **system partition all 0xFF** while a working board has data there | yes |

If your board matches, the system partition is the likely cause. **[HW]** (restoring it fixed the board). Why it was blank is **[INF]** ([case study](07-case-study.md)).
If the board does not show up in `dfu-util -l` even with BIND held, this guide cannot help ([troubleshooting](09-troubleshooting.md)).

## Steps

1. **Install the tools** ([prerequisites](00-prerequisites.md)) and read the [safety rules](01-safety-rules.md).
2. **Back up the broken board first.** Enter [DFU mode](02-flash-map-and-bootloader.md#enter-bootloader-dfu-mode) and run
   `./scripts/spracingh7ef-flash-backup.sh backup data/backups/broken-1`. This keeps its current state. Look at the non-0xFF counts: is `system` 0?
3. **Get a good system partition.** Use [`data/backups/spracing-factory-A1`](../data/backups/spracing-factory-A1) (from a working factory board), or make your own backup from a working H7EF ([backup guide](04-backup.md)).
4. **Check that backup:** `./scripts/spracingh7ef-flash-backup.sh check data/backups/spracing-factory-A1` must print `PASS: backup intact`.
5. **Preview the write (nothing is written):**
   `./scripts/spracingh7ef-flash-restore.sh data/backups/spracing-factory-A1 --system-only --dry-run`
6. **Write the system partition.** Put the broken board in DFU mode, only that board plugged in, then:
   `./scripts/spracingh7ef-flash-restore.sh data/backups/spracing-factory-A1 --system-only`
   and type `YES`. This writes only 0x900DE000 (128 KiB) and does not touch firmware. It is the same command as by hand:
   `dfu-util -a 0 -s 0x900DE000 -D data/backups/spracing-factory-A1/system.bin` **[HW]**
7. **Read back** (still in DFU mode):
   `./scripts/spracingh7ef-flash-backup.sh backup data/backups/broken-2`, then
   `cmp data/backups/broken-2/system.bin data/backups/spracing-factory-A1/system.bin && echo SAME`. **[HW]**
8. **Make sure valid firmware is in the firmware partition.** The broken board already held a valid Betaflight image. If yours has none, follow [flash firmware](06-flash-firmware.md).
9. **Power-cycle:** unplug USB **without** holding BIND, then plug it in.
10. **Check:** the LEDs, then a COM port (`ls /dev/ttyACM*` on Linux), then Betaflight Configurator. See [what to expect](#what-to-expect).

## What to expect

On the repaired board: it needed **three re-plugs** before it started properly. What the user reported: three solid LEDs (red, blue, green), then a fourth LED, red, started flashing slowly. Betaflight Configurator then connected and showed gyro and accelerometer data. The exact meaning of each LED on this board is **[UNV]** (the manual says green and blue must always be on, and red and orange are software-controlled).
Why it needed three re-plugs is **[UNV]** (first-boot setup or USB timing are guesses). If your board does not start on the first try, unplug and plug again a few times before doing anything else. Details: [troubleshooting](09-troubleshooting.md).

## Restore script options

| Option | Effect |
|---|---|
| (none) | writes system, then firmware from the backup (with `:leave`, so the board restarts) |
| `--system-only` | writes only system; firmware untouched; board stays in DFU |
| `--with-group0` | also writes group 0 (blank on both boards read; only if the source backup has data there) |
| `--with-config` | also writes config (per-board settings; blank on both boards read) |
| `--dry-run` | prints the commands and writes nothing |

The script checks the backup's checksums and partition slices before it writes anything, and stops if they do not match. It also stops if it does not see exactly one DFU device, and asks you to type `YES`. The script was tested against a simulated board only. On the real board the equivalent raw `dfu-util` command from step 6 was used. **[HW]** for that command, **[INF]** for the script on real hardware.

## Limits

- The system partition of another board may hold board-specific data. It is 32 KiB of binary data whose first values look like program addresses. Restoring it worked on the broken board, but that it is identical across boards is **[INF]**, not proven.
- If the CPU's own bootloader is damaged, none of this works ([map doc](02-flash-map-and-bootloader.md#not-covered)).
- The restored firmware is whatever the backup or the partition already holds. Update it later ([flash firmware](06-flash-firmware.md)).
