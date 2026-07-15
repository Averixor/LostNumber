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
rm -f "$ARCHIVE"
zip -r "$ARCHIVE" . \
  -x 'node_modules/*' \
  -x '.git/*' \
  -x 'dist/*' \
  -x 'build/*' \
  -x 'godot/.godot/*' \
  -x 'godot/android/build/*' \
  -x 'android/keystore/*' \
  -x 'android/keystore.properties' \
  -x '.cursor/*' \
  -x '.idea/*' \
  -x '.vscode/*' \
  -x '.project' \
  -x 'audio-sources/*' \
  -x 'scripts/keystore-info.mjs' \
  -x '**/.DS_Store' \
  -x '**/*.import' \
  -x '*.apk' \
  -x '*.apks' \
  -x '*.aab' \
  -x '*.jar' \
  -x '*.so' \
  -x '*.zip' \
  -x 'current_manifest.xml' \
  -x 'old_manifest.xml' \

ls -lh "$ARCHIVE"
echo "Done. Handoff: docs/HANDOFF.txt + docs/archive/MERGE_NOTES.md"
