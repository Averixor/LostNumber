#!/usr/bin/env bash
# Pre-AAB release gate: tests, release checks, Godot AAB export, artifact verification.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AAB="$ROOT/build/godot/android/lost-number.aab"
BUNDLETOOL="${BUNDLETOOL_JAR:-$ROOT/bundletool.jar}"

cd "$ROOT"

echo "== godot:test:all =="
npm run godot:test:all

echo "== release:check =="
npm run release:check

echo "== godot:android:release =="
npm run godot:android:release

if [[ ! -f "$AAB" ]]; then
  echo "AAB missing: $AAB" >&2
  exit 1
fi

echo "== AAB contents checks =="
if unzip -l "$AAB" | grep -Ei 'dev|cheat|DebugOverlay'; then
  echo "Forbidden dev/cheat strings found in AAB" >&2
  exit 1
fi
echo "OK: no dev/cheat/DebugOverlay paths in AAB"

if ! unzip -l "$AAB" | grep -E 'lib/.*/libgodot_android\.so'; then
  echo "libgodot_android.so not found in AAB" >&2
  exit 1
fi
echo "OK: libgodot_android.so present"

if unzip -l "$AAB" | grep -E 'assets/store/'; then
  echo "Store marketing assets must not ship in AAB (assets/store/)" >&2
  exit 1
fi
echo "OK: assets/store/ excluded from AAB"

echo "== AAB size =="
ls -lh "$AAB"

if [[ -f "$BUNDLETOOL" ]]; then
  echo "== bundletool manifest (versionCode) =="
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  java -jar "$BUNDLETOOL" build-apks \
    --bundle="$AAB" \
    --output="$TMP/out.apks" \
    --mode=universal \
    --overwrite >/dev/null
  unzip -qo "$TMP/out.apks" -d "$TMP/unzipped"
  MANIFEST="$TMP/unzipped/universal.apk"
  if command -v aapt2 >/dev/null 2>&1; then
    aapt2 dump badging "$MANIFEST" | grep -E "versionCode|native-code" || true
  elif [[ -n "${ANDROID_HOME:-}" && -f "$ANDROID_HOME/build-tools/35.0.0/aapt2" ]]; then
    "$ANDROID_HOME/build-tools/35.0.0/aapt2" dump badging "$MANIFEST" | grep -E "versionCode|native-code" || true
  else
    echo "note: aapt2 not found — skip badging dump"
  fi
else
  echo "note: bundletool.jar not found — skip versionCode dump"
fi

echo "Godot AAB verification passed: $AAB"
