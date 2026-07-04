#!/usr/bin/env bash
# Pack one distributable zip of Lost Number (source + store, no secrets).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/dist"
STAMP="$(date +%Y%m%d)"
ARCHIVE="$OUT_DIR/LostNumber-unified-${STAMP}.zip"

mkdir -p "$OUT_DIR"

SYNCED_FLAGS="$ROOT/android/app/src/main/assets/public/js/system/build-flags.generated.js"
if [[ -f "$SYNCED_FLAGS" ]] && rg -q 'cheatsEnabled\s*:\s*true' "$SYNCED_FLAGS"; then
  echo "Refusing to pack archive: android synced assets still have cheatsEnabled:true"
  echo "Run: npm run android:sync"
  exit 1
fi

echo "Packing unified project → $ARCHIVE"

cd "$ROOT"
rm -f "$ARCHIVE"
zip -r "$ARCHIVE" . \
  -x 'node_modules/*' \
  -x '.git/*' \
  -x 'dist/*' \
  -x 'build/*' \
  -x 'godot/.godot/*' \
  -x 'godot/android/*' \
  -x 'android/.gradle/*' \
  -x 'android/.idea/*' \
  -x 'android/app/build/*' \
  -x 'android/build/*' \
  -x 'android/capacitor-cordova-android-plugins/build/*' \
  -x 'android/local.properties' \
  -x 'android/keystore/*' \
  -x 'android/keystore.properties' \
  -x '_site/*' \
  -x '.cursor/*' \
  -x '.idea/*' \
  -x '.vscode/*' \
  -x '.project' \
  -x 'audio-sources/*' \
  -x 'scripts/keystore-info.mjs' \
  -x '**/.DS_Store' \
  -x '**/*.import' \
  -x 'js/app/ui/*.bak_*' \
  -x 'js/game/grid/*.bak_*' \
  -x 'js/system/platform/*.bak_*'

ls -lh "$ARCHIVE"
echo "Done. Handoff: HANDOFF.txt + MERGE_NOTES.md"
