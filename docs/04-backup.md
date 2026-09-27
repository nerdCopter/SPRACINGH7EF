# 04 Backup

[Back to index](../README.md) | Before this: [Prerequisites](00-prerequisites.md), [Safety rules](01-safety-rules.md) | Next: [Repair and restore](05-repair-restore.md)

A backup is a complete copy of the board's external flash, all 2 MiB. The backup script **only reads**. It has no write command. **[HW]**

## Do it

1. Put the board in [bootloader DFU mode](02-flash-map-and-bootloader.md#enter-bootloader-dfu-mode). Only one board plugged in.
2. From the repo folder run:

```
./scripts/spracingh7ef-flash-backup.sh backup data/backups/my-board-1
```

Use a **new** folder name. The script refuses to write into a folder that already holds a backup.

3. Wait about 10 seconds. The last line must be:

```
PASS: backup complete (2 identical full reads, 4 identical direct reads, self-check OK)
```

4. Check it again, without the board attached, any time:

```
./scripts/spracingh7ef-flash-backup.sh check data/backups/my-board-1
```

Expected: `PASS: backup intact`.

## What the script does

| Step | Why |
|---|---|
| Runs `dfu-util -l` and stops unless exactly one DFU device is present | avoids reading the wrong board |
| Reads the whole flash 2 times (`dfu-util -a 0 -s 0x90000000:0x200000 -U`) | the two reads must be byte-identical |
| Cuts the full read into 4 partition files | group0, system, config, firmware ([map](02-flash-map-and-bootloader.md#external-flash-map)) |
| Reads each of the 4 partitions again on its own, in the same form the manual uses | each must equal the matching slice of the full read |
| Writes `manifest.txt` and `SHA256SUMS`, then makes files read-only | you can prove later that a backup was not changed |
| Runs its own `check` | the backup must pass before the script says PASS |

## What is in a backup folder

| File | Content |
|---|---|
| `full.bin` | 2,097,152 bytes, the whole flash |
| `group0.bin` | 909,312 bytes (888 KiB), 0x90000000 |
| `system.bin` | 131,072 bytes (128 KiB), 0x900DE000 |
| `config.bin` | 8,192 bytes, 0x900FE000 |
| `firmware.bin` | 1,048,576 bytes, 0x90100000 |
| `dfu-list.txt` | output of `dfu-util -l` including the board's serial number |
| `manifest.txt` | date, computer, dfu-util version, address ranges |
| `SHA256SUMS` | checksums of the five `.bin` files |

The script prints how many bytes in each partition are not 0xFF (blank flash reads as 0xFF). Values from the real boards:

| Partition | Factory board | Broken board (before repair) |
|---|---|---|
| group0 | 0 | 0 |
| system | 32,642 | **0** |
| config | 0 | 0 |
| firmware | 1,043,923 | 1,043,564 |

**[HW]**. The system partition holds 32,768 bytes of data on the factory board (last used byte at offset 0x7FFF) and the count above counts only the bytes that are not 0xFF inside it.

## Prove the backup is repeatable

Do this on a good board before you write anything to any board:

1. Make backup A1. Unplug USB. Enter DFU mode again. Make backup A2.
2. `cmp data/backups/A1/full.bin data/backups/A2/full.bin && echo SAME`
3. Compare the recorded checksums.

On the factory board A1 and A2 were byte-identical (checksum `dbb1682f...e204`; A2 is stored only as [checksums](../data/backups/spracing-factory-A2.SHA256SUMS)). **[HW]**

## Verify a board against a backup

```
./scripts/spracingh7ef-flash-backup.sh verify data/backups/my-board-1
```

It reads the board again and prints match or DIFFERS for each of the four partitions. It exits with an error if any partition differs.

## Do the same by hand (no script)

The manual's own read commands work for firmware and config ([map doc](02-flash-map-and-bootloader.md#manual-dfu-util-commands-from-the-manual-p16)). For the other ranges use the same form:

```
dfu-util -a 0 -s 0x90000000:0x200000 -U full.bin      # whole chip
dfu-util -a 0 -s 0x900DE000:0x20000  -U system.bin    # system partition
```

## Problems

| Message | Meaning |
|---|---|
| `MISSING TOOL: dfu-util` | install it, see [prerequisites](00-prerequisites.md) |
| `expected exactly 1 DFU device, found 0` | board not in DFU mode. See [enter DFU mode](02-flash-map-and-bootloader.md#enter-bootloader-dfu-mode) |
| `... found 2` | unplug the other board |
| `two full reads differ` | the read is not stable. Do not trust the result. Try a different cable or port. |
| `full read size != 2 MiB` | the bootloader returned less than the full range. Use the partition-by-partition reads above. (Not seen on the real boards.) |
| `already holds a backup` | choose a new folder name |
