#!/usr/bin/env bash
# Pull debug NDJSON from device into workspace log file.
set -euo pipefail

PKG_DEV="com.averixor.lostnumber.dev"
OUT="/home/averixor/Desktop/LostNumber/.cursor/debug-98f8ff.log"
REMOTE="files/debug-98f8ff.log"

mkdir -p "$(dirname "$OUT")"

if adb exec-out run-as "$PKG_DEV" cat "$REMOTE" >"$OUT" 2>/dev/null; then
  lines="$(wc -l <"$OUT" | tr -d ' ')"
  echo "Pulled $lines lines -> $OUT"
  exit 0
fi

echo "No device log yet; trying logcat LN_DEBUG fallback..." >&2
adb logcat -d -v brief 2>/dev/null | grep 'LN_DEBUG' | sed 's/^.*LN_DEBUG //' >"$OUT" || true
lines="$(wc -l <"$OUT" | tr -d ' ')"
echo "Captured $lines lines -> $OUT"
