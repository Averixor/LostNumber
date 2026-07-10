#!/usr/bin/env bash
# Build LostNumberMigrationPlugin-release.aar for Godot export (.gdap local binary).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
GODOT_BUILD="$ROOT/../../build"
PLUGIN_DIR="$ROOT"
AAR_OUT="$PLUGIN_DIR/LostNumberMigrationPlugin-release.aar"

if [[ ! -f "$GODOT_BUILD/libs/release/godot-lib.template_release.aar" ]]; then
  echo "Run Godot Android export/import first so godot/android/build/libs exists." >&2
  echo "  npm run godot:import && npm run godot:android:debug" >&2
  exit 1
fi

export JAVA_HOME="${JAVA_HOME:-$HOME/Android/jbr}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"

cd "$PLUGIN_DIR"

# Minimal wrapper bootstrap if gradlew missing
if [[ ! -x "$GODOT_BUILD/gradlew" ]]; then
  echo "Missing Godot gradlew at $GODOT_BUILD/gradlew" >&2
  exit 1
fi

"$GODOT_BUILD/gradlew" -p "$PLUGIN_DIR" assembleRelease \
  -Pandroid.useAndroidX=true \
  -Pandroid.enableJetifier=true \
  --gradle-user-home "${GRADLE_USER_HOME:-$HOME/Android/.gradle}"

BUILT="$(find "$PLUGIN_DIR/build/outputs/aar" -name '*-release.aar' | head -1)"
if [[ -z "$BUILT" ]]; then
  echo "AAR build failed — no output in build/outputs/aar" >&2
  exit 1
fi

cp -f "$BUILT" "$AAR_OUT"
echo "Built $AAR_OUT"
ls -lh "$AAR_OUT"
