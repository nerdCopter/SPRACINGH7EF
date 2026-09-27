# 11 Sources and glossary

[Back to index](../README.md)

## Sources

| Source | What it gave us | Link |
|---|---|---|
| SP Racing manual (PDF, 19 pages; titled for a different SP Racing product — this project's board is SPRACINGH7EF, the manual's bootloader/DFU/partition content applies because both boards share the same STM32H730 EXST bootloader mechanism, confirmed on this hardware) | bootloader functions, error patterns, `dfu-util` recipes, partition addresses (pp.14-17) | <http://www.seriouslypro.com/files/SPRacingH7RF-Manual-latest.pdf> |
| Betaflight EXST bootloader doc | image layout, 64-byte bootloader block, MD5 | <https://betaflight.com/docs/development/EXST-Bootloader> |
| `spracing/ssbl` | a different bootloader for the H750 H7 EXTREME; **not** this board | <https://github.com/spracing/ssbl> |
| Betaflight Configurator source | how its DFU erase logic is written (`src/js/protocols/usbdfu.js`) | <https://github.com/betaflight/betaflight-configurator> |
| `dfu-util` | the tool | <https://dfu-util.sourceforge.net/> |

Manual page numbers are the page footers printed in the PDF (the firmware page is 14, bootloader page 15, developer flashing page 16, troubleshooting page 17).
The manual is not included in this repo; download it from the link above.

## Glossary

| Term | Plain meaning |
|---|---|
| **Flight controller (FC)** | the board that runs the aircraft's firmware |
| **Firmware** | the program the board runs, here Betaflight |
| **External flash** | a memory chip next to the CPU. On this board the firmware and boot software live in it |
| **Bootloader** | a small program in the CPU's own memory that starts first. It loads the firmware, and offers USB DFU mode when it cannot |
| **DFU mode** | USB mode used to read and write the flash. Entered by holding BIND while plugging in |
| **BIND button** | the button used to enter bootloader mode |
| **Partition / group** | a named region of the flash: group0, system, config, firmware |
| **System partition** | 128 KiB region at 0x900DE000 that holds the board's system software. Must not be blank |
| **Page** | the smallest erase unit, 8 KiB here |
| **Erase / blank** | erased flash reads as 0xFF in every byte |
| **EXST** | the image format that keeps firmware in external flash with an MD5 check |
| **`.hex` / `.bin`** | two file formats holding the same bytes; `dfu-util` writes the `.bin` |
| **MD5** | a fingerprint of data. The bootloader checks the image's fingerprint |
| **SHA-256** | a stronger fingerprint. Used in `SHA256SUMS` to prove a backup file did not change |
| **Full chip erase** | a configurator option that erases the whole flash before writing. Avoid it on this board |
| **`dfu-util`** | the command-line program that talks to the board in DFU mode |
| **VCP** | virtual COM port: how the running firmware looks to the computer |
