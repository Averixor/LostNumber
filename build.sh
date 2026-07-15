#!/usr/bin/env bash
set -e

echo "🤖 Import resources..."
godot --headless --quit --import-resources .

echo "📦 Build debug APK..."
mkdir -p build
godot --headless --export-debug "Android" build/lostnumber-debug.apk

echo "✅ Done!"