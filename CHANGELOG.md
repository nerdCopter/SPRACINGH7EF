# Changelog

[Back to index](README.md)

## 2026-09-26

- Repo created from the first hardware session on two SPRacingH7EF boards.
- Added: prerequisites, safety rules, flash map and bootloader reference, EXST image format, backup, repair and restore, firmware flashing, case study, H7EF vs H7RF comparison, troubleshooting, evidence ledger, sources and glossary.
- Added scripts: `spracingh7ef-flash-backup.sh` (backup, check, verify) and `spracingh7ef-flash-restore.sh` (with `--system-only`, `--dry-run`). Both check for `dfu-util` and other tools.
- Added tools: `exst_hex_to_bin.py`, `exst_check_bin.py`, `exst_hexmap.py`.
- Added data: factory board backup (A1; A2 as checksums), broken board before and after repair, reference Betaflight images, evidence logs.
- Added `spracingh7ef-repair.sh`, the one-command fix for a single board (simulated-tested; see evidence ledger #24).
- Added DFU interface details, system-partition contents, OctoSPI boot pins, Betaflight build steps and build log.
- Corrected timing claims (9.3 s is the whole backup script, not one read).
- Result recorded: a broken board was repaired by restoring the system partition from a factory board.

## 2026-09-27

- Real-hardware dry-run of `spracingh7ef-repair.sh` on the factory board: correctly reported "Nothing to fix". First real-hardware test of this script (previously simulated only).
- Corrected an error: the firmware build does **not** delete `.bin` from `obj/`. It is only removed by `make clean`. The earlier claim was based on one build where the file happened to be missing for an unconfirmed reason.

## 2026-09-27 (later)

- Corrected the `.bin`-in-`obj/` claim a second time: retested 7 times, present once, absent 6 times, cause unconfirmed. The prior "it normally persists" text was itself an overcorrection from a single sample. Rule now: never depend on it, always check.
