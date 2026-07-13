#!/usr/bin/env bash
# Uninstall existing Lost Number packages, then install debug APK (no -r upgrade).
# Use after npm run godot:android:debug, or via godot-android-install.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK="$ROOT/build/godot/android/lost-number-debug.apk"
PKG_DEV="com.averixor.lostnumber.dev"
PKG_RELEASE="com.averixor.lostnumber"

adb start-server >/dev/null 2>&1 || true

if ! adb devices | awk 'NR>1 && $2=="device" {found=1} END{exit !found}'; then
  echo "No Android device connected. Plug in phone and enable USB debugging." >&2
  exit 1
fi

if [[ ! -f "$APK" ]]; then
  echo "APK not found: $APK (run: npm run godot:android:debug)" >&2
  exit 1
fi

echo "→ adb uninstall old packages"
adb uninstall "$PKG_DEV" 2>/dev/null || true
adb uninstall "$PKG_RELEASE" 2>/dev/null || true

echo "→ adb install $APK"
adb install "$APK"
