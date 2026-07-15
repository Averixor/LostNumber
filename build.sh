#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="${GODOT_BIN:-godot4}"
if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
	GODOT_BIN="godot"
fi
if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
	echo "Godot executable not found. Set GODOT_BIN or install godot4." >&2
	exit 127
fi

mkdir -p "$ROOT_DIR/build"

printf '%s\n' "Importing Godot resources..."
"$GODOT_BIN" --headless --path "$ROOT_DIR/godot" --editor --quit

printf '%s\n' "Running resource path case check..."
python3 "$ROOT_DIR/tools/path_case_lint.py" "$ROOT_DIR/godot"

printf '%s\n' "Building Android debug APK..."
"$GODOT_BIN" --headless --path "$ROOT_DIR/godot" \
	--export-debug "Android" "$ROOT_DIR/build/lostnumber-debug.apk"

printf '%s\n' "Done: $ROOT_DIR/build/lostnumber-debug.apk"
