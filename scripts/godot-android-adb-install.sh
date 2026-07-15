#!/usr/bin/env bash
# Install/update the separate debug package without touching release userdata.
# Use after npm run godot:android:debug, or via godot-android-install.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK="$ROOT/build/android/lost-number-debug.apk"
PKG_DEV="com.averixor.lostnumber.dev"

adb start-server >/dev/null 2>&1 || true

if ! adb devices | awk 'NR>1 && $2=="device" {found=1} END{exit !found}'; then
  echo "No Android device connected. Plug in phone and enable USB debugging." >&2
  exit 1
fi

if [[ ! -f "$APK" ]]; then
  echo "APK not found: $APK (run: npm run godot:android:debug)" >&2
  exit 1
fi

echo "→ adb install -r $APK (preserve $PKG_DEV data; release package untouched)"
adb install -r "$APK"
