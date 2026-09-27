#!/usr/bin/env bash
# SPRacingH7EF/H7RF external flash BACKUP (read-only; never writes to the board).
# Board must be in SP Racing bootloader DFU mode (hold BIND at power-on, release on slow blink).
# Requires dfu-util and GNU coreutils: see docs/00-prerequisites.md.
# Usage: backup <dir> | check <dir> | verify <dir>
#   backup: 2 full reads + 4 direct partition reads must all agree; writes manifest, SHA256SUMS, read-only files.
#   check:  offline integrity test of a stored backup (no board needed).
#   verify: read the connected board again and compare with a stored backup.
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

read_range() { dfu-util -a 0 -s "$1" -U "$2" >/dev/null; }

one_device() {
  n=$(dfu-util -l | grep -o 'devnum=[0-9]*' | sort -u | wc -l)
  [ "$n" -eq 1 ] || { echo "FAIL: expected exactly 1 DFU device, found $n"; exit 1; }
}

slice() { tail -c +$(( $2 + 1 )) "$1" | head -c "$3"; }

check_backup() {
  ( cd "$1" && sha256sum -c SHA256SUMS >/dev/null && [ "$(stat -c %s full.bin)" -eq $((ALL_LEN)) ] ) || return 1
  for p in "${ORDER[@]}"; do
    off=$(( ${PART[$p]%%:*} - BASE )); len=$(( ${PART[$p]##*:} ))
    cmp -s <(slice "$1/full.bin" "$off" "$len") "$1/$p.bin" || return 1
  done
}

cmd=${1:-}; dir=${2:-}
[ -n "$cmd" ] && [ -n "$dir" ] || { sed -n 2,7p "$0"; exit 2; }

case $cmd in
backup)
  [ ! -e "$dir/SHA256SUMS" ] || { echo "FAIL: $dir already holds a backup; use a new directory"; exit 1; }
  mkdir -p "$dir"
  one_device
  dfu-util -l > "$dir/dfu-list.txt"
  for pass in 1 2; do read_range "$BASE:$ALL_LEN" "$dir/full_pass$pass.bin"; done
  cmp "$dir/full_pass1.bin" "$dir/full_pass2.bin" || { echo "FAIL: two full reads differ"; exit 1; }
  [ "$(stat -c %s "$dir/full_pass1.bin")" -eq $((ALL_LEN)) ] || { echo "FAIL: full read size != 2 MiB"; exit 1; }
  mv "$dir/full_pass1.bin" "$dir/full.bin"; discard "$dir/full_pass2.bin"
  for p in "${ORDER[@]}"; do
    off=$(( ${PART[$p]%%:*} - BASE )); len=$(( ${PART[$p]##*:} ))
    dd if="$dir/full.bin" of="$dir/$p.bin" bs=64K iflag=skip_bytes,count_bytes skip=$off count=$len status=none
    read_range "${PART[$p]}" "$dir/direct_$p.bin"
    cmp "$dir/$p.bin" "$dir/direct_$p.bin" || { echo "FAIL: $p differs between full read and direct read"; exit 1; }
    discard "$dir/direct_$p.bin"
    echo "$p: $len bytes, non-0xFF bytes: $(tr -d '\377' < "$dir/$p.bin" | wc -c)"
  done
  { echo "date_utc: $(date -u +%FT%TZ)"; echo "host: $(uname -srm)"; dfu-util --version | head -1
    echo "flash_base: $BASE  length: $ALL_LEN"; for p in "${ORDER[@]}"; do echo "$p: ${PART[$p]}"; done; } > "$dir/manifest.txt"
  ( cd "$dir" && sha256sum full.bin group0.bin system.bin config.bin firmware.bin > SHA256SUMS )
  chmod a-w "$dir"/*.bin "$dir/SHA256SUMS" "$dir/manifest.txt" "$dir/dfu-list.txt"
  check_backup "$dir" || { echo "FAIL: stored backup fails self-check"; exit 1; }
  cat "$dir/SHA256SUMS"
  echo "PASS: backup complete (2 identical full reads, 4 identical direct reads, self-check OK)";;
check)
  check_backup "$dir" && echo "PASS: backup intact" || { echo "FAIL: backup damaged"; exit 1; };;
verify)
  check_backup "$dir" || { echo "FAIL: stored backup damaged"; exit 1; }
  one_device
  tmp=$(mktemp); read_range "$BASE:$ALL_LEN" "$tmp"
  rc=0
  for p in "${ORDER[@]}"; do
    off=$(( ${PART[$p]%%:*} - BASE )); len=$(( ${PART[$p]##*:} ))
    if cmp -s <(slice "$tmp" "$off" "$len") "$dir/$p.bin"; then echo "$p: match"; else echo "$p: DIFFERS"; rc=1; fi
  done
  discard "$tmp"; [ $rc = 0 ] && echo "PASS: board equals backup" || echo "DIFFERENCES FOUND (expected for a restored board's config/group0 if skipped)"; exit $rc;;
*) sed -n 2,7p "$0"; exit 2;;
esac
