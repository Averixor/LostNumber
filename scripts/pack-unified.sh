#!/usr/bin/env bash
# Pack one distributable zip of Lost Number (source + store, no secrets).
# Contents come from committed HEAD via git archive — not the live working tree.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/dist"
STAMP="$(date +%Y%m%d)"
ARCHIVE="$OUT_DIR/LostNumber-unified-${STAMP}.zip"

DENYLIST_GREP='(^|/)(\.git|\.project|\.gradle|node_modules|dist|build)/|\.bak$|\.broken$|\.import$|soft-gothic-|keystore|\.jks$|\.keystore$|\.aab$|\.apk$|\.apks$'

REQUIRED_PATHS=(
  package.json
  godot/project.godot
  godot/export_presets.cfg
  godot/scenes/App.tscn

  docs/HANDOFF.txt
  docs/archive/MERGE_NOTES.md

  godot/android/plugins/LostNumberMigration.gdap
  godot/android/plugins/LostNumberMigrationPlugin/LostNumberMigrationPlugin-release.aar

  store/play-high-res-icon-512.png
  store/feature-graphic-1024x500.png
)

# Tracked in git but never shipped in unified handoff (parity with former zip -x rules).
EXCLUDE_TREE_PATHS=(
  build
  dist
  node_modules
  .project
  .gradle
  .cursor
  .idea
  .vscode
  audio-sources
  godot/.godot
  godot/android/build
  android/keystore
)

if [ -n "$(git -C "$ROOT" status --porcelain)" ]; then
  echo "Refusing to pack: working tree is dirty (commit or stash changes first)." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

STAGING="$(mktemp -d)"
FILE_LIST=""
cleanup() {
  rm -rf "$STAGING"
  [ -n "$FILE_LIST" ] && rm -f "$FILE_LIST"
}
trap cleanup EXIT

echo "Staging from git archive (HEAD) → temp dir"
git -C "$ROOT" archive --format=tar HEAD | tar -x -C "$STAGING"

echo "Removing denylisted file patterns from staging"
while IFS= read -r -d '' f; do
  rm -f "$f"
done < <(
  find "$STAGING" -type f \( \
    -name '*.bak' -o \
    -name '*.broken' -o \
    -name '*.import' -o \
    -name '*soft-gothic*' \
  \) -print0
)

echo "Removing non-shippable paths from staging"
for rel in "${EXCLUDE_TREE_PATHS[@]}"; do
  rm -rf "$STAGING/$rel"
done
rm -f \
  "$STAGING/android/keystore.properties" \
  "$STAGING/scripts/keystore-info.mjs" \
  "$STAGING/current_manifest.xml" \
  "$STAGING/old_manifest.xml"
while IFS= read -r -d '' f; do
  rm -f "$f"
done < <(
  find "$STAGING" -type f \( \
    -name '*.apk' -o -name '*.apks' -o -name '*.aab' -o \
    -name '*.jar' -o -name '*.so' -o -name '*.zip' -o -name '.DS_Store' \
  \) -print0
)

COMMIT_SHA="$(git -C "$ROOT" rev-parse HEAD)"
BRANCH_NAME="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"
UTC_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
PKG_VERSION=""
if [ -f "$STAGING/package.json" ]; then
  PKG_VERSION="$(node -e "const p=require('${STAGING}/package.json'); process.stdout.write(String(p.version||''));" 2>/dev/null || true)"
fi

cat > "$STAGING/PACKAGE-MANIFEST.txt" <<EOF
Lost Number unified package manifest
commit: ${COMMIT_SHA}
branch: ${BRANCH_NAME}
utc_timestamp: ${UTC_TS}
package_name: lost-number
package_version: ${PKG_VERSION}
archive: $(basename "$ARCHIVE")
EOF

echo "Packing unified project → $ARCHIVE"
rm -f "$ARCHIVE"
(
  cd "$STAGING"
  zip -rq "$ARCHIVE" .
)

echo "Verifying archive integrity"
unzip -t "$ARCHIVE" >/dev/null

FILE_LIST="$(mktemp)"
zipinfo -1 "$ARCHIVE" > "$FILE_LIST"

if grep -qE "$DENYLIST_GREP" "$FILE_LIST"; then
  echo "Package denylist check failed — forbidden paths in archive:" >&2
  grep -E "$DENYLIST_GREP" "$FILE_LIST" >&2 || true
  exit 1
fi

for req in "${REQUIRED_PATHS[@]}"; do
  if ! grep -Fxq "$req" "$FILE_LIST"; then
    echo "Required file missing from archive: $req" >&2
    exit 1
  fi
done

ls -lh "$ARCHIVE"
echo "Done. Handoff: docs/HANDOFF.txt + docs/archive/MERGE_NOTES.md"
