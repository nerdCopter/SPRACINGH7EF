# SPRacingH7EF: backup, repair, restore, flash

Everything known about backing up, repairing, restoring, and flashing the **SP Racing H7EF** flight controller
(STM32H730, firmware runs from external flash). Written from real hardware work on two boards on 2026-09-26.
This repo covers this one board's hardware only: flash layout, bootloader, backups, repair, and Betaflight firmware. It is not about any other firmware or configurator. It grows as we learn more ([how to add findings](docs/12-contributing-findings.md)).

> **Read this first.** The board keeps its own boot software in external flash, in a partition
> called *system*. A full-chip erase from a configurator program can wipe it. The board then stops booting until
> that partition is written back. A backup from a working board fixes it. See [the case study](docs/07-case-study.md).

**New here?** Install the tools first: [Prerequisites](docs/00-prerequisites.md) (needs `dfu-util`).

## The quick fix (one board, stuck in bootloader mode)

If your board shows solid green and blue LEDs with a flashing red LED and never becomes a COM port, its **system partition** is probably blank. This repo holds a good copy.

1. Install `dfu-util` ([prerequisites](docs/00-prerequisites.md)).
2. Put the board in bootloader DFU mode: unplug USB, hold BIND, plug in USB, release BIND when the LED blinks slowly.
3. Run: `./scripts/spracingh7ef-repair.sh` and answer `YES` when it shows its plan.
4. Unplug USB (do not hold BIND) and plug it in again. It may need several re-plugs before it starts.

The script first saves the board's current flash, checks what is wrong, and writes only what is needed. Full explanation and the manual alternatives: [Repair and restore](docs/05-repair-restore.md).
**Status:** the underlying write (`dfu-util` by hand) repaired a real board **[HW]**. The script's diagnosis ran on a real board on 2026-09-27 and correctly found nothing to fix **[HW]**. Its write path is still simulated-only, not yet used to repair a real broken board **[INF]**.

## Which situation are you in?

| Your situation | Go to |
|---|---|
| I want to be safe before touching anything | [Safety rules](docs/01-safety-rules.md) |
| I have a working board and want a backup | [Backup](docs/04-backup.md) |
| My board will not boot (red LED blinking, or no USB port) | [Repair and restore](docs/05-repair-restore.md), then [Troubleshooting](docs/09-troubleshooting.md) |
| I want to put new firmware on the board | [Flash firmware](docs/06-flash-firmware.md) |
| I want to know why it broke | [Case study](docs/07-case-study.md) |
| I have an H7RF, not an H7EF | [H7EF vs H7RF](docs/08-h7ef-vs-h7rf.md) |

## Quick facts (all checked on hardware unless marked)

| Item | Value |
|---|---|
| External flash | 2 MiB, addresses 0x90000000 to 0x901FFFFF |
| System partition | 0x900DE000, 128 KiB, holds boot software (32 KiB used on a factory board) |
| Config partition | 0x900FE000, 8 KiB |
| Firmware partition | 0x90100000, 1 MiB |
| Bootloader USB mode | hold BIND while plugging in USB, release when the LED blinks slowly; shows as USB ID `0483:df11` |
| Normal running board | USB ID `0483:5740` (virtual COM port) |
| Tool | `dfu-util` 0.11 (see [prerequisites](docs/00-prerequisites.md)) |
| Fix a stuck board | [`scripts/spracingh7ef-repair.sh`](scripts/spracingh7ef-repair.sh) |
| Backup command | [`scripts/spracingh7ef-flash-backup.sh`](scripts/spracingh7ef-flash-backup.sh) (read-only) |
| Restore command | [`scripts/spracingh7ef-flash-restore.sh`](scripts/spracingh7ef-flash-restore.sh) (writes) |
| Factory-board backup | [`data/backups/spracing-factory-A1`](data/backups/spracing-factory-A1) |

Full table with sources: [flash map and bootloader](docs/02-flash-map-and-bootloader.md).

## Index of everything

**Guides (do things)**
0. [Prerequisites: what to install](docs/00-prerequisites.md)
1. [Safety rules](docs/01-safety-rules.md)
2. [Backup](docs/04-backup.md)
3. [Repair and restore](docs/05-repair-restore.md)
4. [Flash firmware](docs/06-flash-firmware.md)
5. [Troubleshooting and LED patterns](docs/09-troubleshooting.md)

**Reference (understand things)**
6. [Flash map and bootloader](docs/02-flash-map-and-bootloader.md)
7. [Firmware image format (EXST)](docs/03-firmware-image-format.md)
8. [H7EF vs H7RF](docs/08-h7ef-vs-h7rf.md)
9. [Evidence ledger: what is proven and what is not](docs/10-evidence-ledger.md)
10. [Sources and glossary](docs/11-sources-and-glossary.md)

**History**
11. [Case study: the broken board, 2026-09-26](docs/07-case-study.md)
12. [How to add findings](docs/12-contributing-findings.md)
13. [Changelog](CHANGELOG.md)

**Files**

| Folder | Contents |
|---|---|
| [`scripts/`](scripts) | three scripts, see the table below |
| [`tools/`](tools) | [`exst_hex_to_bin.py`](tools/exst_hex_to_bin.py) (check a hex, make a bin), [`exst_check_bin.py`](tools/exst_check_bin.py) (check a bin or dump), [`exst_hexmap.py`](tools/exst_hexmap.py) (list hex blocks) |
| [`data/backups/`](data/backups) | real flash dumps of a factory board, the broken board before repair, and after repair |
| [`data/reference-images/`](data/reference-images) | Betaflight images used for repair and tests |
| [`data/evidence/`](data/evidence) | raw logs and diffs behind the claims |

## Which script do I use?

| Script | Use it when | Writes to the board? |
|---|---|---|
| [`spracingh7ef-repair.sh`](scripts/spracingh7ef-repair.sh) | You have **one** board and it is stuck in bootloader mode. It uses the factory data stored in this repo. | yes, only what it finds wrong, after saving the current flash and asking `YES` |
| [`spracingh7ef-flash-backup.sh`](scripts/spracingh7ef-flash-backup.sh) | You want a copy of a board's whole flash, to check a stored copy (`check`), or to compare a board with a copy (`verify`). | **no**, read-only |
| [`spracingh7ef-flash-restore.sh`](scripts/spracingh7ef-flash-restore.sh) | You have your own backup of a board and want to write parts of it (or all firmware and system) back. Needs a backup folder made by the backup script. | yes, after checking the backup and asking `YES` |

If unsure, run the backup script first. It cannot change anything.

## How to read the tags

Each claim in the docs has a tag.

| Tag | Meaning |
|---|---|
| **[HW]** | Tested on real hardware in this project |
| **[SRC]** | Read in source code or the SP Racing manual, not tested |
| **[INF]** | Inferred from evidence. Likely, not proven |
| **[UNV]** | Not verified. Do not rely on it |

## Notes and limits

- Nothing here can repair a damaged CPU bootloader. That code is in the CPU's own flash and is not reachable through this method ([details](docs/10-evidence-ledger.md)).
- The backup images contain SP Racing's system software from a factory board. Check redistribution rights before making this repo public. No license has been chosen yet.
- The scripts and steps were run on two real boards. Different board revisions may behave differently.
