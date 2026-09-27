# 02 Flash map and bootloader

[Back to index](../README.md) | Next: [Firmware image format](03-firmware-image-format.md)

## How the board starts

The CPU has only a small internal flash (128 KiB). It holds the SP Racing **bootloader**. The firmware you flash lives in a separate
**external flash chip**. At power-on the bootloader loads the system software and the firmware from that chip and starts them.
If it cannot find suitable firmware, it blinks error codes on the red LED and enters USB DFU mode. **[SRC]** (manual p.15, see [sources](11-sources-and-glossary.md))

## External flash map

Read from the board's DFU descriptor: `@External Flash /0x90000000/111*8Kg,16*8Kg,1*8Kg,128*8Kg,0*8Ka` **[HW]**
(saved in [`dfu-list.txt`](../data/backups/spracing-factory-A1/dfu-list.txt)). Each `8K` is one erase page.

| Group | Name | Start | Size | Content on the factory board | Content on the broken board (before repair) |
|---|---|---|---|---|---|
| 0 | group0 (reserved) | 0x90000000 | 888 KiB | all 0xFF (blank) | all 0xFF |
| 1 | **system** | 0x900DE000 | 128 KiB | **32,768 bytes of data**, rest blank | **all 0xFF (wiped)** |
| 2 | config | 0x900FE000 | 8 KiB | all 0xFF (blank) | all 0xFF |
| 3 | firmware | 0x90100000 | 1 MiB | Betaflight image, strings show 4.3.0 | a Betaflight image (version not identified) |

Arithmetic check: 111 x 8 KiB = 0xDE000; plus 16 x 8 KiB = 0xFE000; plus 8 KiB = 0x100000; plus 128 x 8 KiB = 0x200000. **[HW]**
The group names (system, config, firmware) come from the SP Racing manual's `dfu-util` recipes **[SRC]**.
The contents columns come from the dumps in [`data/backups`](../data/backups) **[HW]**.
The factory board's config partition is blank, so a blank config does not mean damage.

## USB identities

| State | USB ID | Seen as |
|---|---|---|
| Bootloader DFU mode | `0483:df11` | "STM Device in DFU Mode" **[HW]** |
| Firmware running | `0483:5740` | "Virtual COM Port", `/dev/ttyACM0` on Linux **[HW]** |

## Enter bootloader DFU mode

1. Unplug USB and battery.
2. Hold the BIND button.
3. Plug in USB. The LED blinks very fast.
4. Release BIND. The LED blinks slowly. You are in DFU mode. **[SRC]** manual p.15; **[HW]** result: `dfu-util -l` lists the device.
5. Confirm: `dfu-util -l` shows one line `Found DFU: [0483:df11]`.

## Bootloader functions

While the board is powered with BIND held in bootloader mode, the LED flashes once every 2 seconds. Each flash counts one function number. Release BIND after N flashes to run function N. **[SRC]** manual p.15. None of these were run in this project.

| N | Function | Safe? |
|---|---|---|
| 1 | Load and launch system software and firmware from external flash | yes |
| 2 | Launch loaded system software and firmware in RAM (developers) | yes |
| 3 | Clear firmware in RAM | yes |
| 4 | Enter CPU ROM DFU bootloader (developers) | advanced |
| 5 | Reboot | yes |
| 6 | Erase config on external flash | erases settings |
| 7 | Erase firmware on external flash | erases firmware only |
| 8 | Erase entire external flash incl. system software, firmware, config | **no** (only if SP Racing tells you) |
| 15 | Erase CPU bootloader | **never** (factory repair needed) |
| 16 | Erase external flash reserved area | **no** |
| 17 | Erase system software on external flash | **no** |

The manual describes function 17 as "Erase system software on external flash". That is the same partition this project found blank on the broken board.

## DFU interface details

What `dfu-util` reported for both boards **[HW]**:

| Item | Value |
|---|---|
| USB ID | `0483:df11` |
| DFU version | 0x011A on the device (descriptor `ver=0200` in `dfu-util -l`) |
| Alternate settings | one (`alt=0`), named `@External Flash /0x90000000/...`. Use `-a 0`. |
| Transfer size | 1024 bytes per USB block |
| Interface name | "External Flash" |
| Erase | done by the bootloader while you download: writing 1 MiB to 0x90100000 first erases the 1 MiB range, then writes; writing 128 KiB to 0x900DE000 erases those 128 KiB first |
| Timing | the whole backup script (two 2 MiB reads plus four partition reads, about 6 MiB) took 9.3 s. Write time was not measured. |

`:leave` after an address (`-s 0x90100000:leave`) tells the bootloader to leave DFU and start running after the download. Without it the board stays in DFU so you can read back first.

## Contents of the system partition

On the factory board **[HW]**: data in the first 32,768 bytes (0x0000 to 0x7FFF); the remaining 96 KiB are 0xFF. It begins `01 00 30 4f c5 b5 00 00 7d a4 00 00 51 a3 00 00 35 a2 00 00 ...`. After the first eight bytes the values look like 32-bit little-endian program addresses (0xA47D, 0xA351, 0xA235, ...). No text strings were found in it. Its exact role is **[UNV]**; the manual calls it "system software" and marks it "do not erase".

## The chip's internal flash and boot pins

- The STM32H730 has only 128 KiB of internal flash. It holds the bootloader and nothing else of the firmware. **[SRC]** (Betaflight's H730 target header says the chip "only has one flash page which contains the bootloader")
- The bootloader configures the external flash's OctoSPI pins before the firmware starts: PB2 (clock), PB10 (chip select), PE7, PE8, PE9, PE10 (data lines IO4 to IO7). The firmware must not reconfigure them. Betaflight's board config reserves these pins. **[SRC]** ([config diff](../data/evidence/bf-config-diff-H7EF-vs-H7RF.txt))
- The H7EF has a second, separate flash chip on SPI6 (an M25P16, chip select PD7) used for blackbox logs. **[SRC]** That chip is not the one the DFU shows.

## Manual `dfu-util` commands (from the manual, p.16)

These are the manual's own recipes for the H7RF. They work on the H7EF because the bootloader and flash map are the same ([H7EF vs H7RF](08-h7ef-vs-h7rf.md)). **[SRC]**; firmware write and read-back **[HW]** (used with `-a 0`).

| Action | Command |
|---|---|
| Write firmware | `dfu-util -D firmware.bin -s 0x90100000:leave` |
| Read firmware | `dfu-util -U fw.bin -s 0x90100000:0x100000` |
| Erase firmware | `dd if=/dev/zero ibs=1k count=1024 of=ZERO_1024K.bin` then `dfu-util -D ZERO_1024K.bin -s 0x90100000:0x100000` |
| Read config | `dfu-util -U config.bin -s 0x900FE000:0x2000` |
| Erase config | `dd if=/dev/zero ibs=1k count=8 of=ZERO_8K.bin` then `dfu-util -D ZERO_8K.bin -s 0x900FE000:0x2000` |
| Write system software | `dfu-util -D system.bin -s 0x900DE000:leave` |

The manual gives no read command for the system partition, group 0, or the whole chip. The same `-U ... -s address:length`
form worked for all of them on the real boards, including the whole chip in one read: `dfu-util -a 0 -s 0x90000000:0x200000 -U full.bin`. **[HW]**

The manual's `SPRacingH7RF.bin` system file is not published in the `spracing/betaflight` release assets. The only source found is a dump of a good board ([data/backups/spracing-factory-A1/system.bin](../data/backups/spracing-factory-A1/system.bin)). **[HW]**

## Not covered

The CPU's internal flash (128 KiB, the bootloader itself) cannot be read or written by these commands. Whether function 4 (CPU ROM DFU)
can read it is **[UNV]**. If the bootloader is damaged, this repo cannot help.
