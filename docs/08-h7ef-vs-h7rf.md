# 08 H7EF vs H7RF

[Back to index](../README.md) | Related: [Flash map](02-flash-map-and-bootloader.md)

SP Racing sells two boards on the same STM32H730 with the same bootloader. This repo is about the **H7EF**. The SP Racing manual in [sources](11-sources-and-glossary.md) is for the **H7RF**.

## What is the same

| Item | Evidence |
|---|---|
| CPU STM32H730, firmware runs from external flash (EXST) | the Betaflight build of SPRACINGH7EF prints `Creating EXST`; the official H7RF release has the EXST layout [HW] |
| Bootloader DFU mode, USB ID `0483:df11` | [HW] on H7EF. The manual describes it for H7RF [SRC] |
| External flash map (2 MiB, four groups) | [HW] on H7EF via the DFU descriptor. The manual's recipes for H7RF use the same addresses [SRC] |
| EXST image format | official H7RF image and H7EF images both pass the same [hash rule](03-firmware-image-format.md) [HW] |

So the manual's bootloader and DFU pages apply to the H7EF. What does **not** transfer: anything about SD card, ExpressLRS, pinouts, and config storage.

## What differs

From the Betaflight board configs, `configs/SPRO/SPRACINGH7EF/config.h` against `configs/SPRO/SPRACINGH7RF/config.h`
([full diff](../data/evidence/bf-config-diff-H7EF-vs-H7RF.txt), config repo commit `96910e908`). **[SRC]**

| Item | H7EF | H7RF |
|---|---|---|
| Board id / USB string | `SP7E` / `SPRacingH7EF` | `SP7R` / `SPRacingH7RF` |
| Gyros | two (SPI3 chip select PA15, and SPI2), multi-gyro | one (SPI6, chip select PA15, alignment `CW270_DEG_FLIP`) |
| Receiver default | serial | ExpressLRS on an SX1280 chip (SPI2) |
| SD card | none | SDIO 4-bit |
| Config storage | in external flash (`CONFIG_IN_EXTERNAL_FLASH`); a separate SPI6 flash chip is for blackbox logs | memory-mapped flash (`CONFIG_IN_MEMORY_MAPPED_FLASH`) |
| Motors 1 to 8 | PA0, PA1, PA2, PA3, PA6, PA7, PB0, PB1 | PB0, PB1, PA6, PA7, PA0, PA1, PA2, PA3 |
| Buttons | both on PD10 | both on PC14 |
| I2C, UART pins, beeper, LED strip pin | differ (see diff) | differ |

## Identity strings found in the flash images

| Image | Strings |
|---|---|
| Factory H7EF board firmware | `SPRACINGH7EF`, `SP7E` |
| Broken board's old firmware | `SPRACINGH7EF`, `SP7E`, `SPRO` |
| Betaflight 2026.12.0-alpha H7EF build | `SPRACINGH7EF`, `SP7E`, `SPRO` |
| Official SP Racing H7RF 4.5.0 release | `SPRACINGH7RF`, `SP7R`, `SPRacingH7RF`, `SPRO` |

**[HW]** (searched for these strings in each file). No firmware on the H7EF boards carries H7RF identity strings.

## Safe rule

Flash only images built for `SPRACINGH7EF` onto this board. The official SP Racing releases in [`data/reference-images`](../data/reference-images) named `SPRACINGH7RF` are kept only as a reference for the image format. **Do not flash them to an H7EF.**
