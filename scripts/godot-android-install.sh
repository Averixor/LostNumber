#!/usr/bin/env bash
# Clean reinstall Godot debug APK on connected phone (no stale WebView/cache).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG_DEV="com.averixor.lostnumber.dev"

adb start-server >/dev/null 2>&1 || true

if ! adb devices | awk 'NR>1 && $2=="device" {found=1} END{exit !found}'; then
  echo "No Android device connected. Plug in phone and enable USB debugging." >&2
  exit 1
fi

echo "→ godot:android:debug (build)"
"$ROOT/scripts/godot-android-export.sh" debug

"$ROOT/scripts/godot-android-adb-install.sh"

echo "→ launch"
adb shell monkey -p "$PKG_DEV" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true

echo "Done: $PKG_DEV installed fresh on device."
