# 09 Troubleshooting and LED patterns

[Back to index](../README.md) | Related: [Repair and restore](05-repair-restore.md), [Flash map and bootloader](02-flash-map-and-bootloader.md)

## LEDs

The manual says the GREEN and BLUE LEDs must always be on, and red and orange are controlled by software. The board has 5 V OK, 3 V OK and status LEDs; the manual does not say which colour is which. **[SRC]** (manual p.10)

| What you see | Meaning | Tag |
|---|---|---|
| Green and blue solid, red flashing, board stays in DFU (`0483:df11`) after a normal power-up | The bootloader did not start the firmware and is showing an error pattern. Seen on the broken board when its system partition was blank. | [HW] |
| Status LED blinks very fast while BIND is held at power-up, then slowly after release | You are in bootloader DFU mode | [SRC] (manual p.15); the resulting DFU device was seen on the computer [HW] |
| No LED at all | Check the 5 V supply and the cable | [SRC] |
| Only the 5 V LED on, no 3 V LED and no red status LED | The manual says this is most often a wiring or short-circuit problem and the board may be destroyed. Stop and check for shorts. | [SRC] (manual p.17) |

## Error patterns: count the slow flashes

After a few quick flashes the LED gives slow flashes. Count the slow ones. **[SRC]** (manual p.15). None of these were decoded on the real broken board, because the flash count was not recorded.

| Slow flashes | Meaning |
|---|---|
| 2 | Firmware verification failed (corruption, hash mismatch) |
| 3 | Firmware load failed, no valid firmware found |
| 4 | Firmware write failed |
| 5 | External flash write failed |
| 6 | External flash read failed |
| 7 | SD write failed |
| 8 | SD read failed |

The bootloader's patterns start with faster flashes than Betaflight's own patterns. If you see a pattern, write down the count in your notes: it would be new evidence ([contributing](12-contributing-findings.md)).

## Symptoms and actions

| Symptom | Likely cause | What to do |
|---|---|---|
| `dfu-util -l` shows no device | Board not in DFU mode, bad cable, or damaged bootloader | Retry [entering DFU mode](02-flash-map-and-bootloader.md#enter-bootloader-dfu-mode). Try another cable and USB port. If it never appears, the CPU bootloader may be damaged: this repo cannot fix that. |
| `dfu-util -l` shows two devices | two boards in DFU mode | unplug one |
| `dfu-util` cannot open the device | USB permissions | try `sudo`, or add a udev rule [UNV] |
| The board boots as a COM port (`0483:5740`) but you need DFU | normal for a working board | hold BIND while plugging in USB |
| After a repair the board does not start at once | happened on the real repair: three re-plugs were needed | unplug and plug in a few times ([repair guide](05-repair-restore.md#what-to-expect)) |
| Board stays in DFU with a red error blink, valid firmware present | system partition empty (the case that was fixed) | [Repair and restore](05-repair-restore.md) |
| Firmware write ends with an error | interrupted or unstable write | read the partition back, compare, write again ([flash firmware](06-flash-firmware.md)) |
| Verification fails at the same byte every time | image not valid for this board (shape or hash) | run [`tools/exst_hex_to_bin.py`](../tools/exst_hex_to_bin.py) on it ([image format](03-firmware-image-format.md)) |
| Betaflight Configurator does not connect | board not running firmware, or wrong port | check the COM port exists; see rows above |

## USB IDs

| ID | State |
|---|---|
| `0483:df11` | bootloader DFU mode |
| `0483:5740` | firmware running as a virtual COM port |

Check with `lsusb | grep 0483`. **[HW]**
