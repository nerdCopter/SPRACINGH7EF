# 07 Case study: the broken board, 2026-09-26

[Back to index](../README.md) | Related: [Repair and restore](05-repair-restore.md), [Evidence ledger](10-evidence-ledger.md)

One board would not boot. A second, working board was used as the source for the repair. Tags: [meaning](../README.md#how-to-read-the-tags).

## Timeline

| # | What happened | Tag | Evidence |
|---|---|---|---|
| 1 | On 2026-09-25 a firmware flash to the broken board was run from a configurator program with "Full chip erase" on. Its console log shows `Executing local chip erase (256)` and 256 page-erase commands from 0x90000000 to 0x901FE000, **including 0x900DE000 (system) and 0x900FE000 (config)**. The write finished, then verification failed at 0x901002D0 (expected byte 0x11, read 0x01). | [HW] | [console log](../data/evidence/configurator-failed-flash-console.log) (lines 30, 142, 158, 291-294) |
| 2 | Some time later, before step 3, a valid Betaflight image was written into the board's firmware partition. Who or when is not recorded. | [HW] for the content | [`spracing-broken-before/firmware.bin`](../data/backups/spracing-broken-before/firmware.bin) passes the [hash rule](03-firmware-image-format.md) and contains the text "Betaflight" and "SPRACINGH7EF" |
| 3 | The broken board (serial `1D0033001351303232373236`) was put in DFU mode and backed up: two identical full reads. **System partition: all 0xFF.** Group 0 and config: all 0xFF. | [HW] | [`data/backups/spracing-broken-before`](../data/backups/spracing-broken-before) |
| 4 | A Betaflight 2026.12.0-alpha image for SPRACINGH7EF was written with `dfu-util -a 0 -s 0x90100000 -D image.bin`. It erased, wrote, returned no error, and the read-back was byte-identical. | [HW] | [`data/reference-images`](../data/reference-images) |
| 5 | After a power-cycle the board still did not boot: green and blue LEDs solid, red LED flashing, and the board was back in DFU mode (`0483:df11`). | [HW] (user report; USB ID seen on the computer) | |
| 6 | A factory board (serial `210017001351393531343338`) was plugged in. It first showed as a COM port (`0483:5740`, normal boot). With BIND held it entered DFU mode. Two backups of it (A1, A2) were byte-identical. **System partition: 32,768 bytes of data.** Group 0 and config: all 0xFF. Firmware: a Betaflight image, strings show 4.3.0. | [HW] | [`spracing-factory-A1`](../data/backups/spracing-factory-A1), [A2 checksums](../data/backups/spracing-factory-A2.SHA256SUMS) |
| 7 | Comparing the boards: group 0 and config partitions are byte-identical on both (same SHA-256). Only the system partition and the firmware differ. | [HW] | [checksums](../data/backups/spracing-broken-before/SHA256SUMS) vs [these](../data/backups/spracing-factory-A1/SHA256SUMS) |
| 8 | The factory `system.bin` was written to the broken board: `dfu-util -a 0 -s 0x900DE000 -D system.bin`. A full read-back showed system equal to the factory board; group 0 and config unchanged; firmware partition still equal to the Betaflight 2026.12.0-alpha image from step 4. | [HW] | [`broken-after-system-restore`](../data/backups/broken-after-system-restore) |
| 9 | After power-cycling, the board needed three re-plugs to start. Then Betaflight Configurator connected and showed accelerometer and gyro data. | [HW] (user report) | |

## What this proves and what it does not

**Proven [HW]:**
- The failed board had an empty system partition. The working board does not.
- Writing the working board's system partition to the failed board, with a valid firmware image present, made it boot.
- `dfu-util` can read and write every range on this board, including in one 2 MiB read.

**Inferred [INF], not proven:**
- The full-chip erase in step 1 emptied the system partition. The erase log shows the commands were sent to those pages, and the partition was empty later. But the system partition was never read before the erase, so it could have been empty for another reason. If you can read a working board before and after a full-chip erase, that would settle it (add it to [contributing](12-contributing-findings.md)).
- The bootloader obeys erase commands aimed at the system partition, because the partition was blank afterwards.

**Not known [UNV]:**
- Why verification failed at 0x901002D0 in step 1. The same board later accepted a properly formed 1 MiB image with `dfu-util` and read it back correctly (step 4), so the board's flash write and read paths work for that image.
- Why three re-plugs were needed in step 9.
- Whether the board's system partition holds any per-board data. Restoring another board's copy worked here.

## Lessons

1. Back up a working board before any repair ([backup](04-backup.md)).
2. Never use "Full chip erase" on this board ([safety rules](01-safety-rules.md)).
3. If the board stays in DFU mode with a red error blink, read the whole flash and check the system partition first ([repair](05-repair-restore.md)).
