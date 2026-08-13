#!/usr/bin/env bash
# Copy google-services.json into Godot android/build and enable the Gradle plugin.
# shellcheck shell=bash

_strip_google_services_gradle() {
  local build_dir="${1:?}"
  local settings="$build_dir/settings.gradle"
  local app_gradle="$build_dir/build.gradle"

  if [[ -f "$settings" ]] && grep -q "com.google.gms.google-services" "$settings"; then
    python3 - "$settings" <<'PY'
from pathlib import Path
import re
import sys
path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
cleaned = re.sub(
    r"\n?[ \t]*id\s+['\"]com\.google\.gms\.google-services['\"][^\n]*\n?",
    "\n",
    text,
)
if cleaned != text:
    path.write_text(cleaned, encoding="utf-8")
    print("Stripped google-services plugin from android/build/settings.gradle")
PY
  fi

  if [[ -f "$app_gradle" ]] && grep -q "com.google.gms.google-services" "$app_gradle"; then
    python3 - "$app_gradle" <<'PY'
from pathlib import Path
import re
import sys
path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
cleaned = re.sub(
    r"\n?[ \t]*id\s+['\"]com\.google\.gms\.google-services['\"][^\n]*\n?",
    "\n",
    text,
)
if cleaned != text:
    path.write_text(cleaned, encoding="utf-8")
    print("Stripped google-services plugin from android/build/build.gradle")
PY
  fi
}

install_google_services_for_export() {
  local root="${1:?}"
  local godot_dir="${2:?}"
  local mode="${3:?}" # debug|release
  local flavor="dev"
  if [[ "$mode" == "release" ]]; then
    flavor="prod"
  fi

  local src="$root/android/firebase/${flavor}/google-services.json"
  local build_dir="$godot_dir/android/build"
  local dest="$build_dir/google-services.json"

  if [[ ! -d "$build_dir" ]]; then
    echo "WARN: android/build missing; skip google-services install" >&2
    return 0
  fi

  if [[ ! -f "$src" ]]; then
    echo "WARN: missing $src — Google Sign-In needs OWNER Firebase config" >&2
    rm -f "$dest"
    # Previous export may have patched Gradle; undo so builds without JSON still work.
    _strip_google_services_gradle "$build_dir"
    return 0
  fi

  cp -f "$src" "$dest"
  echo "Installed google-services.json ($flavor) -> android/build/"

  local settings="$build_dir/settings.gradle"
  local app_gradle="$build_dir/build.gradle"
  if [[ -f "$settings" ]] && ! grep -q "com.google.gms.google-services" "$settings"; then
    python3 - "$settings" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
marker = "plugins {"
# Prefer pluginManagement.plugins block
pm = text.find("pluginManagement")
idx = text.find(marker, pm if pm >= 0 else 0)
if idx < 0:
    raise SystemExit("ERROR: plugins {} missing in settings.gradle")
brace = text.find("{", idx)
insert_at = brace + 1
line = "\n        id 'com.google.gms.google-services' version '4.4.2'\n"
if "com.google.gms.google-services" not in text:
    path.write_text(text[:insert_at] + line + text[insert_at:], encoding="utf-8")
    print("Patched android/build/settings.gradle: google-services plugin")
PY
  fi

  if [[ -f "$app_gradle" ]] && ! grep -q "com.google.gms.google-services" "$app_gradle"; then
    python3 - "$app_gradle" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
needle = "plugins {"
idx = text.find(needle)
if idx < 0:
    raise SystemExit("ERROR: plugins {} block missing in android/build/build.gradle")
brace = text.find("{", idx)
insert_at = brace + 1
line = "\n    id 'com.google.gms.google-services'\n"
path.write_text(text[:insert_at] + line + text[insert_at:], encoding="utf-8")
print("Patched android/build/build.gradle: apply google-services")
PY
  fi
}
