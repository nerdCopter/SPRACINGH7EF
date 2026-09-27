# 12 How to add findings

[Back to index](../README.md)

This repo will grow. Keep it accurate and easy to follow.

## Rules

1. **Tag every claim** with **[HW]**, **[SRC]**, **[INF]** or **[UNV]** ([meaning](../README.md#how-to-read-the-tags)). Never write an inference as a fact.
2. **Save the evidence** in [`data/evidence/`](../data/evidence) (logs, diffs) or [`data/backups/`](../data/backups) (flash dumps), and link to it.
3. **Add or update a row** in the [evidence ledger](10-evidence-ledger.md). If a test settles an open question, change its tag and move it out of "Open questions".
4. **New backups** go in `data/backups/<name>/` made with the [backup script](../scripts/spracingh7ef-flash-backup.sh) (it writes `SHA256SUMS`). Record the board serial, when, and the state of the board.
5. **New tool or script?** Add it to [Prerequisites](00-prerequisites.md) with the install command and how to check it. Add it to the file table in the [README](../README.md).
6. **New guide or doc?** Add it to the README index and link it from the docs it relates to. Use relative links so they work in a file browser.
7. **Update the [changelog](../CHANGELOG.md)** with the date and what changed.
8. **Keep text plain.** One fact per sentence. Explain a term the first time or link the [glossary](11-sources-and-glossary.md).
9. **Do not add other firmware or configurator work** here. This repo is about this board's hardware: flash layout, bootloader, backup, repair, restore, and Betaflight firmware.

## Before you publish

- Check redistribution rights for `data/backups/*/system.bin` and the reference images before making the repo public. No license has been chosen.
- Run `sha256sum -c SHA256SUMS` inside each backup directory (or `./scripts/spracingh7ef-flash-backup.sh check <dir>`), and `cd data && sha256sum -c SHA256SUMS` for every stored file. Regenerate `data/SHA256SUMS` after adding files.
