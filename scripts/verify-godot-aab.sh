#!/usr/bin/env bash
# Pre-AAB release gate: tests, release checks, Godot AAB export, artifact verification.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AAB="$ROOT/build/android/lost-number.aab"
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

if unzip -l "$AAB" | grep -E 'scripts/tests/'; then
  echo "Test and capture scripts must not ship in AAB (scripts/tests/)" >&2
  exit 1
fi
echo "OK: scripts/tests/ excluded from AAB"

echo "== AAB size =="
ls -lh "$AAB"

if [[ -f "$BUNDLETOOL" ]]; then
  echo "== bundletool verification dump (package/version/sdk/ABI/perms/icons/signing) =="
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  java -jar "$BUNDLETOOL" build-apks \
    --bundle="$AAB" \
    --output="$TMP/out.apks" \
    --mode=universal \
    --overwrite >/dev/null
  unzip -qo "$TMP/out.apks" -d "$TMP/unzipped"
  MANIFEST="$TMP/unzipped/universal.apk"

  AAPT2_BIN=""
  if command -v aapt2 >/dev/null 2>&1; then
    AAPT2_BIN="aapt2"
  elif [[ -n "${ANDROID_HOME:-}" ]]; then
    for v in 35.0.0 36.1.0 34.0.0 37.0.0; do
      if [[ -f "$ANDROID_HOME/build-tools/$v/aapt2" ]]; then
        AAPT2_BIN="$ANDROID_HOME/build-tools/$v/aapt2"
        break
      fi
    done
  fi

  if [[ -n "$AAPT2_BIN" ]]; then
    BADGING="$("$AAPT2_BIN" dump badging "$MANIFEST" || true)"
    echo "AAB package/version:"
    echo "$BADGING" | grep -E "^package:" || true
    echo "AAB SDK (min/target):"
    echo "$BADGING" | grep -E \"sdkVersion:'|targetSdkVersion:'\" || true
    echo "AAB ABI (native-code):"
    echo "$BADGING" | grep -E \"native-code:\" || true

    echo "AAB permissions:"
    if "$AAPT2_BIN" dump permissions "$MANIFEST" >/dev/null 2>&1; then
      "$AAPT2_BIN" dump permissions "$MANIFEST" | grep -E \"android\\.permission\\.|com\\.android\" || true
    else
      echo "note: aapt2 permissions dump unsupported — skipping"
    fi
  else
    echo "note: aapt2 not found — skip badging/permissions dump"
  fi

  APKSIGNER_BIN=""
  if command -v apksigner >/dev/null 2>&1; then
    APKSIGNER_BIN="apksigner"
  elif [[ -n "${ANDROID_HOME:-}" ]]; then
    for v in 35.0.0 36.1.0 34.0.0 37.0.0; do
      if [[ -f "$ANDROID_HOME/build-tools/$v/apksigner" ]]; then
        APKSIGNER_BIN="$ANDROID_HOME/build-tools/$v/apksigner"
        break
      fi
    done
  fi

  if [[ -n "$APKSIGNER_BIN" ]]; then
    echo "Signing (apksigner certs):"
    "$APKSIGNER_BIN" verify --print-certs "$MANIFEST" || true
  else
    echo "note: apksigner not found — skip signing dump"
  fi

  echo "Launcher / adaptive icon resources present in universal.apk:"
  unzip -l "$MANIFEST" | grep -E \"res/mipmap-anydpi-v26/|res/mipmap/.+icon_(foreground|background)\\.webp|res/mipmap/.+themed_icon|adaptive-icon\" || true
else
  if [[ \"${RELEASE_VERIFY:-}\" == \"1\" || \"${GITHUB_ACTIONS:-}\" == \"true\" || \"${CI:-}\" == \"true\" ]]; then
    echo "ERROR: bundletool.jar not found at: $BUNDLETOOL" >&2
    echo "ERROR: Install pinned bundletool and place it as ./bundletool.jar (or set BUNDLETOOL_JAR)." >&2
    exit 1
  else
    echo "warning: bundletool.jar not found at: $BUNDLETOOL — skipping deep badging/permissions/signing/icons dump"
  fi
fi

echo "Godot AAB verification passed: $AAB"
