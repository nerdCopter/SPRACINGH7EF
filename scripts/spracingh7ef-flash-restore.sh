#!/usr/bin/env bash
# SPRacingH7EF/H7RF external flash RESTORE. WRITES to the connected board.
# Independent of the backup script; needs a backup directory it made (full.bin, *.bin, SHA256SUMS).
# Board must be in SP Racing bootloader DFU mode (hold BIND at power-on, release on slow blink).
# Requires dfu-util and GNU coreutils: see docs/00-prerequisites.md.
# Usage: spracingh7ef-flash-restore.sh <backup-dir> [--system-only] [--with-config] [--with-group0] [--dry-run]
#   default writes: system, then firmware (with :leave). config and group0 only when asked.
#   --system-only writes only the system partition and leaves the board in DFU (firmware untouched).
set -euo pipefail

BASE=0x90000000
ALL_LEN=0x200000
declare -A PART=( [group0]="0x90000000:0xDE000" [system]="0x900DE000:0x20000" [config]="0x900FE000:0x2000" [firmware]="0x90100000:0x100000" )
ORDER=(group0 system config firmware)

need() { command -v "$1" >/dev/null 2>&1 || { echo "MISSING TOOL: $1. $2"; missing=1; }; }
missing=0
need dfu-util "Install it: Debian/Ubuntu 'sudo apt install dfu-util'; Fedora 'sudo dnf install dfu-util'; Arch 'sudo pacman -S dfu-util'."
for t in sha256sum cmp dd tr tail head stat mktemp grep sort wc date uname chmod mkdir mv rm; do need "$t" "Install GNU coreutils, diffutils and grep."; done
[ "$missing" -eq 0 ] || { echo "See docs/00-prerequisites.md"; exit 1; }
discard() { if command -v trash >/dev/null 2>&1; then trash "$@"; else rm -f -- "$@"; fi; }

dir=${1:-}; [ -n "$dir" ] || { sed -n 2,7p "$0"; exit 2; }; shift
with_config=0; with_g0=0; dry=0; sys_only=0
for a in "$@"; do case $a in --with-config) with_config=1;; --with-group0) with_g0=1;; --dry-run) dry=1;; --system-only) sys_only=1;; *) echo "unknown option $a"; exit 2;; esac; done

slice() { tail -c +$(( $2 + 1 )) "$1" | head -c "$3"; }
( cd "$dir" && sha256sum -c SHA256SUMS >/dev/null && [ "$(stat -c %s full.bin)" -eq $((ALL_LEN)) ] ) || { echo "FAIL: backup failed checksum/size test, refusing to write"; exit 1; }
for p in "${ORDER[@]}"; do
  off=$(( ${PART[$p]%%:*} - BASE )); len=$(( ${PART[$p]##*:} ))
  cmp -s <(slice "$dir/full.bin" "$off" "$len") "$dir/$p.bin" || { echo "FAIL: $p.bin does not match full.bin"; exit 1; }
done

sel=(system)
[ $with_g0 = 1 ] && sel=(group0 "${sel[@]}")
[ $with_config = 1 ] && sel+=(config)
fwtxt="firmware(:leave)"; [ $sys_only = 1 ] && fwtxt="(firmware untouched)"
echo "Will write: ${sel[*]} $fwtxt   from $dir"
if [ $dry = 1 ]; then
  for p in "${sel[@]}"; do echo "dfu-util -a 0 -s ${PART[$p]%%:*} -D $dir/$p.bin"; done
  [ $sys_only = 1 ] || echo "dfu-util -a 0 -s ${PART[firmware]%%:*}:leave -D $dir/firmware.bin"; echo "DRY RUN: nothing written"; exit 0
fi

n=$(dfu-util -l | grep -o 'devnum=[0-9]*' | sort -u | wc -l)
[ "$n" -eq 1 ] || { echo "FAIL: expected exactly 1 DFU device, found $n"; exit 1; }
read -rp "Type YES to write to the connected board: " ans; [ "$ans" = YES ] || { echo "aborted"; exit 1; }

for p in "${sel[@]}"; do dfu-util -a 0 -s "${PART[$p]%%:*}" -D "$dir/$p.bin"; done
if [ $sys_only = 0 ]; then dfu-util -a 0 -s "${PART[firmware]%%:*}:leave" -D "$dir/firmware.bin" || true; fi
echo "Write finished (with --system-only the board stays in DFU; otherwise it leaves DFU). Re-enter bootloader DFU mode and read back with: spracingh7ef-flash-backup.sh verify $dir"
