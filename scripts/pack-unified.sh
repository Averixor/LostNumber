#!/usr/bin/env bash
# Pack one distributable zip of Lost Number (source + store, no secrets).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/dist"
STAMP="$(date +%Y%m%d)"
ARCHIVE="$OUT_DIR/LostNumber-unified-${STAMP}.zip"

mkdir -p "$OUT_DIR"

echo "Packing unified project → $ARCHIVE"

cd "$ROOT"
zip -r "$ARCHIVE" . \
  -x 'node_modules/*' \
  -x '.git/*' \
  -x 'godot/.godot/*' \
  -x 'godot/android/*' \
  -x 'android/.gradle/*' \
  -x 'android/app/build/*' \
  -x 'android/build/*' \
  -x 'android/local.properties' \
  -x 'android/keystore/*' \
  -x 'android/keystore.properties' \
  -x '_site/*' \
  -x '.cursor/*' \
  -x '**/.DS_Store' \
  -x '**/*.import' \
  -x 'js/app/ui/*.bak_*' \
  -x 'js/game/grid/*.bak_*' \
  -x 'js/system/platform/*.bak_*'

# Optional: include prebuilt Godot binaries if present
if [[ -f "$ROOT/build/godot/android/lost-number-debug.apk" ]]; then
  echo "Including build/godot/android/*.apk and *.aab"
fi

ls -lh "$ARCHIVE"
echo "Done. Handoff: HANDOFF.txt + MERGE_NOTES.md"
