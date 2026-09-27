# 10 Evidence ledger

[Back to index](../README.md) | Tags: [meaning](../README.md#how-to-read-the-tags)

One row per important claim, with how we know. When you learn something new, add a row and change the tag if it moves from **[INF]** or **[UNV]** to **[HW]** ([contributing](12-contributing-findings.md)).

| # | Claim | Tag | Evidence |
|---|---|---|---|
| 1 | External flash is 2 MiB at 0x90000000 with groups `111*8K, 16*8K, 1*8K, 128*8K` | [HW] | `dfu-list.txt` in [factory backup](../data/backups/spracing-factory-A1/dfu-list.txt); identical on the broken board |
| 2 | The whole flash can be read in one `dfu-util -U` call (2 MiB). The full backup script took 9.3 s for about 6 MiB of reads | [HW] | [backup script](../scripts/spracingh7ef-flash-backup.sh) PASS on two boards; two identical reads each |
| 3 | Reads are stable: two full backups of the factory board are byte-identical | [HW] | [A2 checksums](../data/backups/spracing-factory-A2.SHA256SUMS) equal A1's `full.bin` checksum |
| 4 | Factory board system partition holds 32,768 bytes of data | [HW] | [`system.bin`](../data/backups/spracing-factory-A1/system.bin), last non-0xFF byte at offset 0x7FFF |
| 5 | Broken board's system partition was all 0xFF | [HW] | [`spracing-broken-before/system.bin`](../data/backups/spracing-broken-before/system.bin) |
| 6 | Group 0 and config are blank and identical on both boards | [HW] | equal SHA-256 in both `SHA256SUMS` files |
| 7 | Writing the factory system partition to the broken board made it boot; Configurator saw gyro/accel | [HW] | [after-repair dump](../data/backups/broken-after-system-restore/full.bin) plus user report |
| 8 | The system partition is the only structural difference between the boards | [HW] | comparison in the [case study](07-case-study.md), step 7 |
| 9 | Writing a 1 MiB EXST image with `dfu-util -a 0 -s 0x90100000 -D` works and reads back identically | [HW] | [case study](07-case-study.md), step 4 |
| 10 | The EXST hash rule (MD5 with hash bytes zeroed) holds for real images | [HW] | [`tools/exst_check_bin.py`](../tools/exst_check_bin.py) on 4 firmware images |
| 11 | A full-chip erase from a configurator sent erase commands for every page, including system and config | [HW] | [console log](../data/evidence/configurator-failed-flash-console.log) lines 30, 142, 158 |
| 12 | That erase emptied the system partition | [INF] | no read of the partition before the erase exists |
| 13 | Betaflight Configurator has the same full-chip erase logic (default off) | [SRC] | its `src/js/protocols/usbdfu.js` on master, read 2026-09-26; not tested on hardware |
| 14 | Bootloader functions 1-8, 15-17 do what the manual says | [SRC] | manual p.15. None were run. |
| 15 | Error-pattern table (2 to 8 slow flashes) | [SRC] | manual p.15. Not decoded on real hardware. |
| 16 | H7EF and H7RF share bootloader, flash map and image format; pins, gyros, receiver, SD, config storage differ | [SRC] for pins etc., [HW] for the shared parts | [config diff](../data/evidence/bf-config-diff-H7EF-vs-H7RF.txt), DFU descriptor, hash checks |
| 17 | The CPU's internal flash (bootloader) cannot be read by these commands | [INF] | it is not in the DFU map; function 4 (ROM DFU) was not tried |
| 18 | Why the repaired board needed three re-plugs | [UNV] | user report only |
| 19 | Why the old three-block image failed verification at 0x901002D0 | [UNV] | log only ([lines 291-294](../data/evidence/configurator-failed-flash-console.log)) |
| 20 | Whether the bootloader rejects an image with a zero hash | [UNV] | never tested |
| 21 | Whether the system partition contains per-board data | [UNV] | it worked when copied from another board |
| 22 | Works on macOS and Windows | [UNV] | not tried |
| 23 | No public source exists for this H730 bootloader | [INF] | the `spracing` GitHub organisation lists `spracing/ssbl`, which targets the H750; nothing else found |
| 24 | `spracingh7ef-repair.sh` diagnoses and writes correctly | [HW] for diagnosis (real board, 2026-09-27, correctly reported "Nothing to fix" on a known-good board); [INF] for the write path (still simulated-only; not yet run on a broken board) | 9 simulated scenarios plus one real dry-run |
| 29 | Whether a normal build leaves `.bin` in `obj/` | [HW], but inconsistent: 7 builds on 2026-09-27 (EmuFlight `feat/exst-image-packaging`, `SPRACINGH7EF`, `-j1`/`-j8`) left it once, lost it 6 times. Not GNU Make's own intermediate-file cleanup (`--debug=a`: no "Removing" message) and no delete command in the recipe. Cause **[UNV]**. Practical rule: never depend on it, check `obj/` after your own build, regenerate from `.hex` if missing |
| 25 | The system-partition write that the repair script performs repaired a real board | [HW] | [case study](07-case-study.md), step 8 (same `dfu-util` command) |
| 26 | DFU: one alt setting, transfer size 1024, DFU version 0x011A, bootloader erases during download | [HW] | `dfu-util` output on both boards ([flash map doc](02-flash-map-and-bootloader.md#dfu-interface-details)) |
| 27 | The Betaflight image is built as: link, unpatched bin, pad to 1 MiB, patch MD5, hex from bin, bin removed | [SRC] | [build log](../data/evidence/betaflight-build-log-spracingh7ef.txt) |
| 28 | Firmware write time | [UNV] | not measured |

## Open questions worth testing next

1. Read a working board, do a full-chip erase, read again. Does the system partition go blank? (settles #12; only do this on a spare board with a backup)
2. Count the slow red flashes on a board with a blank system partition. (settles #15 for this case)
3. Does the CPU ROM DFU (function 4) allow reading the internal flash? (would settle #17)
4. Why did the first repaired boot take three re-plugs? (#18)
5. What deletes `.bin` from `obj/` most of the time after a build? (#29). Checked 2026-09-27: no GNU Make flag or explicit-target invocation (`make binary_hex TARGET=...`, which names `.bin` directly as a goal) prevented it — still lost 6/7 times regardless. `inotify-tools` (not installed) would let this be watched live.
6. Run the real repair (writing) on a genuinely broken board. (extends #24 to the write path; the diagnosis path is now confirmed on real hardware, 2026-09-27)
