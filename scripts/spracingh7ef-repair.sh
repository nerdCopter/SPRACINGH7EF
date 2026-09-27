#!/usr/bin/env bash
# SPRacingH7EF one-command repair for a SINGLE board. Uses the factory data stored in this repo.
# Board must be in SP Racing bootloader DFU mode (hold BIND while plugging in USB, release on slow blink).
# Requires dfu-util and GNU tools: see docs/00-prerequisites.md.
# Usage: spracingh7ef-repair.sh [--firmware bf-alpha|factory|<file.bin>] [--force-system] [--dry-run] [--yes]
#   1. reads the whole flash twice (must match) and saves it to data/repair-backups/<time>/full.bin (before-state)
#   2. diagnoses system, firmware, config, group0
#   3. plans only the writes that are needed, shows them, asks for YES
#   4. writes, reads back, verifies
# System partition source:  data/backups/spracing-factory-A1/system.bin
# Firmware (only written when the firmware partition is blank or fails its hash, or --firmware is given):
#   bf-alpha (default) = Betaflight 2026.12.0-alpha SPRACINGH7EF (proven on a repaired board)
#   factory            = firmware read from a factory board
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "MISSING TOOL: $1. $2"; missing=1; }; }
missing=0
need dfu-util "Install it: Debian/Ubuntu 'sudo apt install dfu-util'; Fedora 'sudo dnf install dfu-util'; Arch 'sudo pacman -S dfu-util'."
for t in sha256sum md5sum od cmp dd tr tail head stat cut grep sort wc date mkdir chmod mktemp rm; do need "$t" "Install GNU coreutils, diffutils and grep."; done
[ "$missing" -eq 0 ] || { echo "See docs/00-prerequisites.md"; exit 1; }

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BASE=0x90000000; ALL_LEN=0x200000
SYS_ADDR=0x900DE000; SYS_LEN=$((0x20000)); SYS_OFF=$((0xDE000))
G0_LEN=$((0xDE000)); CFG_OFF=$((0xFE000)); CFG_LEN=$((0x2000))
FW_ADDR=0x90100000; FW_LEN=$((0x100000)); FW_OFF=$((0x100000))
SYSTEM_BIN="$ROOT/data/backups/spracing-factory-A1/system.bin"
FW_BFALPHA=""; for f in "$ROOT"/data/reference-images/betaflight-2026.12.0-alpha-SPRACINGH7EF/*.bin; do [ -f "$f" ] && FW_BFALPHA=$f && break; done
FW_FACTORY="$ROOT/data/backups/spracing-factory-A1/firmware.bin"

fw_choice=bf-alpha; fw_explicit=0; force_sys=0; dry=0; yes=0
while [ $# -gt 0 ]; do
  case $1 in
    --firmware) [ $# -ge 2 ] || { echo "--firmware needs a value"; exit 2; }; fw_choice=$2; fw_explicit=1; shift 2;;
    --force-system) force_sys=1; shift;;
    --dry-run) dry=1; shift;;
    --yes) yes=1; shift;;
    -h|--help) sed -n 2,14p "$0"; exit 0;;
    *) echo "unknown option $1"; exit 2;;
  esac
done
case $fw_choice in
  bf-alpha) FW_BIN=$FW_BFALPHA;;
  factory) FW_BIN=$FW_FACTORY;;
  *) FW_BIN=$fw_choice;;
esac
[ -f "$FW_BIN" ] || { echo "FAIL: firmware file not found: $FW_BIN"; exit 1; }
[ -f "$SYSTEM_BIN" ] || { echo "FAIL: missing $SYSTEM_BIN"; exit 1; }

tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
slice() { dd if="$1" bs=64K iflag=skip_bytes,count_bytes skip="$2" count="$3" status=none; }
is_blank() { [ "$(tr -d '\377' | wc -c)" -eq 0 ]; }
# EXST rule: MD5 of the 1 MiB image with its last 16 bytes zeroed equals its last 16 bytes
exst_ok() {
  [ "$(stat -c %s "$1")" -eq "$FW_LEN" ] || return 1
  calc=$( { head -c $((FW_LEN - 16)) "$1"; head -c 16 /dev/zero; } | md5sum | cut -d' ' -f1 )
  stored=$(tail -c 16 "$1" | od -An -v -tx1 | tr -d ' \n')
  [ "$calc" = "$stored" ]
}

echo "== Checking the repair data in this repo"
( cd "$ROOT/data" && sha256sum -c --ignore-missing SHA256SUMS >/dev/null ) || { echo "FAIL: repo data does not match data/SHA256SUMS"; exit 1; }
exst_ok "$FW_BIN" || { echo "FAIL: $FW_BIN is not a valid 1 MiB EXST image (hash rule failed)"; exit 1; }
echo "OK: system.bin and firmware image match their checksums; firmware hash valid ($FW_BIN)"

echo "== Looking for the board"
n=$(dfu-util -l | grep -o 'devnum=[0-9]*' | sort -u | wc -l)
[ "$n" -eq 1 ] || { echo "FAIL: expected exactly 1 DFU device, found $n. Hold BIND while plugging in USB, release on slow blink."; exit 1; }

stamp=$(date -u +%Y%m%dT%H%M%SZ)-$$
out="$ROOT/data/repair-backups/$stamp"; mkdir -p "$out"
echo "== Saving the board's current flash (before-state) to $out"
dfu-util -a 0 -s "$BASE:$ALL_LEN" -U "$out/full.bin" >/dev/null
dfu-util -a 0 -s "$BASE:$ALL_LEN" -U "$out/full_second_read.bin" >/dev/null
cmp -s "$out/full.bin" "$out/full_second_read.bin" || { echo "FAIL: two reads differ; not writing anything"; exit 1; }
[ "$(stat -c %s "$out/full.bin")" -eq $((ALL_LEN)) ] || { echo "FAIL: read is not 2 MiB; not writing anything"; exit 1; }
dfu-util -l > "$out/dfu-list.txt"; ( cd "$out" && sha256sum full.bin > SHA256SUMS ); chmod a-w "$out"/*

echo "== Diagnosis"
slice "$out/full.bin" 0 $G0_LEN > "$tmp/g0"; slice "$out/full.bin" $SYS_OFF $SYS_LEN > "$tmp/sys"
slice "$out/full.bin" $CFG_OFF $CFG_LEN > "$tmp/cfg"; slice "$out/full.bin" $FW_OFF $FW_LEN > "$tmp/fw"
do_sys=0; do_fw=0
if is_blank < "$tmp/sys"; then sys_state="BLANK (this is the known failure)"; do_sys=1
elif cmp -s "$tmp/sys" "$SYSTEM_BIN"; then sys_state="matches the factory system partition"
else sys_state="has other data (not blank, not the stored factory copy)"; [ $force_sys = 1 ] && do_sys=1; fi
if is_blank < "$tmp/fw"; then fw_state="BLANK"; do_fw=1
elif exst_ok "$tmp/fw"; then fw_state="valid image (hash OK)"
else fw_state="present but its hash check FAILS"; do_fw=1; fi
is_blank < "$tmp/g0" && g0_state=blank || g0_state="has data"
is_blank < "$tmp/cfg" && cfg_state=blank || cfg_state="has data (your settings)"
echo "  system   0x900DE000 : $sys_state"
echo "  firmware 0x90100000 : $fw_state"
echo "  config   0x900FE000 : $cfg_state (never written by this script)"
echo "  group0   0x90000000 : $g0_state (never written by this script)"
[ $fw_explicit = 1 ] && do_fw=1
[ "$sys_state" = "has other data (not blank, not the stored factory copy)" ] && [ $force_sys = 0 ] && echo "  note: system differs from the stored copy; not overwritten. Use --force-system to overwrite it."

if [ $do_sys = 0 ] && [ $do_fw = 0 ]; then
  echo "== Nothing to fix. The partitions this script manages look fine. Before-state saved in $out."
  exit 0
fi
echo "== Plan"
[ $do_sys = 1 ] && echo "  write system   <- $SYSTEM_BIN  (128 KiB at $SYS_ADDR)"
[ $do_fw = 1 ]  && echo "  write firmware <- $FW_BIN  (1 MiB at $FW_ADDR)"
[ $dry = 1 ] && { echo "DRY RUN: nothing written. Before-state saved in $out."; exit 0; }
if [ $yes = 0 ]; then read -rp "Type YES to write to the connected board: " ans; [ "$ans" = YES ] || { echo "aborted, nothing written"; exit 1; }; fi

[ $do_sys = 1 ] && dfu-util -a 0 -s "$SYS_ADDR" -D "$SYSTEM_BIN"
[ $do_fw = 1 ]  && dfu-util -a 0 -s "$FW_ADDR" -D "$FW_BIN"

echo "== Read-back check"
dfu-util -a 0 -s "$BASE:$ALL_LEN" -U "$out/after.bin" >/dev/null
rc=0
if [ $do_sys = 1 ]; then cmp -s <(slice "$out/after.bin" $SYS_OFF $SYS_LEN) "$SYSTEM_BIN" && echo "  system   : PASS" || { echo "  system   : FAIL"; rc=1; }; fi
if [ $do_fw = 1 ]; then cmp -s <(slice "$out/after.bin" $FW_OFF $FW_LEN) "$FW_BIN" && echo "  firmware : PASS" || { echo "  firmware : FAIL"; rc=1; }; fi
for pair in "config:$CFG_OFF:$CFG_LEN" "group0:0:$G0_LEN"; do
  IFS=: read -r nm off len <<<"$pair"
  cmp -s <(slice "$out/after.bin" "$off" "$len") <(slice "$out/full.bin" "$off" "$len") && echo "  $nm : unchanged" || { echo "  $nm : CHANGED (unexpected)"; rc=1; }
done
if [ $rc = 0 ]; then
  echo "PASS. Now unplug USB WITHOUT holding BIND and plug it in again. It may need several re-plugs to start (seen on the real repair)."
else
  echo "FAIL: read-back did not match. Do not power off yet; run this script again."
fi
exit $rc
