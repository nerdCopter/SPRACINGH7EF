# 00 Prerequisites

[Back to index](../README.md)

Install and check these before you start. **Keep this list current:** when a new step needs a new tool, add it here
([how to add findings](12-contributing-findings.md)). The two scripts also check their own tools and print an install hint if one is missing.

## Hardware

| Item | Why | Notes |
|---|---|---|
| The SP Racing H7EF board | the thing you are working on | |
| USB cable that carries data | connect the board to the computer | Some cables only charge. If the board never shows up in `lsusb`, try another cable. |
| Access to the **BIND** button | enter bootloader DFU mode | see [enter DFU mode](02-flash-map-and-bootloader.md#enter-bootloader-dfu-mode) |
| A second, working H7EF board (recommended) | source of a backup, if none exists yet | This repo already holds one factory backup: [`data/backups/spracing-factory-A1`](../data/backups/spracing-factory-A1) |
| About 5 MB of free disk per backup | each backup directory is about 4 MB | measured 4.1 MB |

## Software

| Tool | Needed by | Tested version | Install (Debian/Ubuntu) | Check |
|---|---|---|---|---|
| **`dfu-util`** | reading and writing the board over USB | 0.11 | `sudo apt install dfu-util` | `dfu-util --version` |
| `bash` | both scripts | (Linux system bash) | preinstalled | `bash --version` |
| GNU coreutils, diffutils, grep: `sha256sum cmp dd tr tail head stat mktemp chmod mkdir mv rm sort wc date uname grep` | both scripts | (Linux system tools) | preinstalled | the scripts check for each one |
| `python3` (standard library only) | the three helper tools in [`tools/`](../tools) | 3.x (tested with 3.12.3) | `sudo apt install python3` | `python3 --version` |
| `trash` (optional) | scripts move temp files to trash instead of deleting | not needed | `sudo apt install trash-cli` | `command -v trash` |
| Betaflight Configurator (optional) | confirm the repaired board boots and shows gyro/accel | not version-tested | see betaflight.com | it opens and connects |

Other distributions: Fedora `sudo dnf install dfu-util`, Arch `sudo pacman -S dfu-util`. **[UNV]** (install commands not run in this project).

## Computer

- Tested on Linux (kernel 6.14, x86-64) with `dfu-util` 0.11, running as a normal user with no `sudo`. **[HW]**
- macOS and Windows are **[UNV]**. The scripts use GNU options (`stat -c`, `dd iflag=skip_bytes`) that macOS does not have by default.
- If `dfu-util` says it cannot open the device, the usual cause is missing USB permissions. Try `sudo`, or add a udev rule. **[UNV]** (did not happen in this project)

## Check your setup

```
dfu-util --version          # prints 0.11 or newer
python3 --version           # prints 3.x
```

Put the board in [bootloader DFU mode](02-flash-map-and-bootloader.md#enter-bootloader-dfu-mode), then:

```
dfu-util -l
```

You should see exactly one line starting `Found DFU: [0483:df11]` and the text `@External Flash /0x90000000/111*8Kg,16*8Kg,1*8Kg,128*8Kg,0*8Ka`. **[HW]**
If you see nothing, see [troubleshooting](09-troubleshooting.md).

Next: [Safety rules](01-safety-rules.md), then [Backup](04-backup.md).
