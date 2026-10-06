#!/usr/bin/env bash
# Enable R8 minify/shrink for Godot android/build release exports.
# Godot regenerates android/build/; we patch build.gradle and copy proguard-rules on each export.
# shellcheck shell=bash

install_r8_for_export() {
  local root="${1:?}"
  local godot_dir="${2:?}"
  local build_dir="$godot_dir/android/build"
  local app_gradle="$build_dir/build.gradle"
  local rules_src="$root/android/proguard-rules.pro"
  local rules_dest="$build_dir/proguard-rules.pro"

  if [[ ! -d "$build_dir" ]]; then
    echo "WARN: android/build missing; skip R8 install" >&2
    return 0
  fi

  if [[ ! -f "$rules_src" ]]; then
    echo "ERROR: missing $rules_src (required for R8 release minify)" >&2
    return 1
  fi

  cp -f "$rules_src" "$rules_dest"
  echo "Installed proguard-rules.pro -> android/build/"

  if [[ ! -f "$app_gradle" ]]; then
    echo "WARN: android/build/build.gradle missing; skip R8 minify patch" >&2
    return 0
  fi

  python3 - "$app_gradle" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

if re.search(r"minifyEnabled\s+true", text) and "proguard-rules.pro" in text:
    print("R8 minify already enabled in android/build/build.gradle")
    raise SystemExit(0)

bt = re.search(r"buildTypes\s*\{", text)
if bt is None:
    raise SystemExit("ERROR: buildTypes {} missing in android/build/build.gradle")

# Find the release { that belongs to buildTypes (not signingConfigs.release).
search_from = bt.end()
rel = re.search(r"(^|\n)([ \t]*)release\s*\{", text[search_from:])
if rel is None:
    raise SystemExit("ERROR: release {} block missing under buildTypes")

rel_abs = search_from + rel.start()
brace_open = text.find("{", search_from + rel.start())
if brace_open < 0:
    raise SystemExit("ERROR: release { open brace not found")

depth = 0
i = brace_open
while i < len(text):
    ch = text[i]
    if ch == "{":
        depth += 1
    elif ch == "}":
        depth -= 1
        if depth == 0:
            break
    i += 1
else:
    raise SystemExit("ERROR: unmatched braces in release buildType")

indent = rel.group(2) + "    "
r8_block = (
    f"\n{indent}minifyEnabled true\n"
    f"{indent}shrinkResources true\n"
    f"{indent}proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), "
    f"'proguard-rules.pro'"
)
insert_at = brace_open + 1
new_text = text[:insert_at] + r8_block + text[insert_at:]
path.write_text(new_text, encoding="utf-8")
print("Patched android/build/build.gradle: release minifyEnabled + shrinkResources (R8)")
PY
}
