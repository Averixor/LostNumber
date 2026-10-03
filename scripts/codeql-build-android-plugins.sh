#!/usr/bin/env bash
# Збірка Android-плагінів для CodeQL (manual build-mode).
# Без повного Godot export: godot-lib підміняється codeql-stubs.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGINS_ROOT="$ROOT/godot/android/plugins"
GRADLE_VER="${CODEQL_GRADLE_VERSION:-8.7}"

if [[ -z "${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}" ]]; then
  echo "error: ANDROID_HOME / ANDROID_SDK_ROOT is required" >&2
  exit 1
fi
export ANDROID_HOME="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"

if ! command -v gradle >/dev/null 2>&1; then
  echo "error: gradle not on PATH (use gradle/actions/setup-gradle)" >&2
  exit 1
fi

build_plugin() {
  local plugin_dir="$1"
  local name
  name="$(basename "$plugin_dir")"
  echo "::group::CodeQL build $name"
  (
    cd "$plugin_dir"
    if [[ ! -x ./gradlew ]]; then
      gradle wrapper --gradle-version "$GRADLE_VER"
      chmod +x ./gradlew
    fi
    ./gradlew assembleRelease \
      -PcodeqlBuild=true \
      -Pandroid.useAndroidX=true \
      --no-daemon
  )
  echo "::endgroup::"
}

build_plugin "$PLUGINS_ROOT/LostNumberMigrationPlugin"
build_plugin "$PLUGINS_ROOT/LostNumberFirebasePlugin"

echo "CodeQL Android plugin builds finished."
