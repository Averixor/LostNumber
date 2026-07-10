#!/usr/bin/env bash
# Build Lost Number (Godot) for Android — AAB or debug APK.
# Usage:
#   ./scripts/godot-android-export.sh debug
#   ./scripts/godot-android-export.sh release

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_DIR="$ROOT/godot"
BUILD_DIR="$ROOT/build/godot/android"
GODOT_BIN="${GODOT_BIN:-godot4}"
MODE="${1:-debug}"

mkdir -p "$BUILD_DIR"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "Godot not found. Install Godot 4.3+ and set GODOT_BIN." >&2
  exit 1
fi

GODOT_VERSION="$("$GODOT_BIN" --version | head -1 | awk '{print $1}')"
# Snap reports e.g. 4.5.stable.official.876b29033 — templates use 4.5-stable
TEMPLATE_VERSION="$(echo "$GODOT_VERSION" | sed -E 's/^([0-9]+\.[0-9]+)\..*/\1-stable/')"

_resolve_template_dir() {
  local candidates=(
    "${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${GODOT_VERSION}"
    "$HOME/snap/godot4/common/.local/share/godot/export_templates/${GODOT_VERSION}"
    "$HOME/snap/godot4/current/.local/share/godot/export_templates/${GODOT_VERSION}"
  )
  for dir in "${candidates[@]}"; do
    if [[ -f "$dir/android_source.zip" ]]; then
      echo "$dir"
      return 0
    fi
    if [[ -f "$dir/templates/android_source.zip" ]]; then
      echo "$dir/templates"
      return 0
    fi
  done
  echo "${candidates[0]}"
}

TEMPLATE_DIR="$(_resolve_template_dir)"

if [[ ! -f "$TEMPLATE_DIR/android_source.zip" ]]; then
  echo "Export templates missing for $GODOT_VERSION"
  SNAP_TEMPLATE_BASE="$HOME/snap/godot4/current/.local/share/godot/export_templates"
  if [[ ! -d "$SNAP_TEMPLATE_BASE" ]]; then
    SNAP_TEMPLATE_BASE="$HOME/snap/godot4/common/.local/share/godot/export_templates"
  fi
  INSTALL_DIR="$SNAP_TEMPLATE_BASE/${GODOT_VERSION}"
  if [[ ! -d "$SNAP_TEMPLATE_BASE" ]]; then
    INSTALL_DIR="$TEMPLATE_DIR"
  fi

  if [[ ! -f "$INSTALL_DIR/android_source.zip" ]]; then
    echo "Downloading export templates..."
    TPZ="/tmp/godot_export_templates_${TEMPLATE_VERSION}.tpz"
    URL="https://github.com/godotengine/godot/releases/download/${TEMPLATE_VERSION}/Godot_v${TEMPLATE_VERSION}_export_templates.tpz"
    curl -fsSL "$URL" -o "$TPZ"
    mkdir -p "$INSTALL_DIR"
    unzip -qo "$TPZ" -d "$INSTALL_DIR"
    rm -f "$TPZ"
    # Also expose short version folder name expected by some Godot builds.
    if [[ -d "$SNAP_TEMPLATE_BASE" ]]; then
      ln -sfn "${GODOT_VERSION}" "$SNAP_TEMPLATE_BASE/${TEMPLATE_VERSION%-stable}-stable" 2>/dev/null || true
    fi
  fi
  TEMPLATE_DIR="$(_resolve_template_dir)"
fi

echo "Importing Godot project..."
"$GODOT_BIN" --path "$GODOT_DIR" --import --headless

if [[ ! -f "$GODOT_DIR/android/build/build.gradle" ]]; then
  echo "Installing Android build template into project..."
  TEMPLATE_ZIP=""
  for candidate in \
    "$HOME/snap/godot4/current/.local/share/godot/export_templates/${GODOT_VERSION}/android_source.zip" \
    "$HOME/snap/godot4/current/.local/share/godot/export_templates/${GODOT_VERSION}/templates/android_source.zip" \
    "$HOME/snap/godot4/common/.local/share/godot/export_templates/${GODOT_VERSION}/android_source.zip" \
    "$HOME/snap/godot4/common/.local/share/godot/export_templates/${GODOT_VERSION}/templates/android_source.zip" \
    "$HOME/snap/godot4/10/.local/share/godot/export_templates/4.5.stable/android_source.zip" \
    "${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${GODOT_VERSION}/android_source.zip" \
    "${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${GODOT_VERSION}/templates/android_source.zip"; do
    if [[ -f "$candidate" ]]; then
      TEMPLATE_ZIP="$candidate"
      break
    fi
  done
  if [[ -n "$TEMPLATE_ZIP" ]]; then
    mkdir -p "$GODOT_DIR/android/build" "$GODOT_DIR/android/plugins"
    unzip -qo "$TEMPLATE_ZIP" -d "$GODOT_DIR/android/build"
    chmod +x "$GODOT_DIR/android/build/gradlew" 2>/dev/null || true
    echo "${GODOT_VERSION%%.official*}" > "$GODOT_DIR/android/.build_version"
  else
    "$GODOT_BIN" --path "$GODOT_DIR" --headless --install-android-build-template
  fi
fi

if [[ ! -x "$HOME/Android/jbr/bin/java" && -x /opt/android-studio/jbr/bin/java ]]; then
  echo "Copying JBR to ~/Android/jbr for snap Godot..."
  mkdir -p "$HOME/Android"
  cp -a /opt/android-studio/jbr "$HOME/Android/jbr"
fi

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_USER_HOME="${ANDROID_USER_HOME:-$HOME/Android/.android}"
export JAVA_HOME="${JAVA_HOME:-$HOME/Android/jbr}"
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$HOME/Android/.gradle}"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
mkdir -p "$GRADLE_USER_HOME" "$ANDROID_USER_HOME"

# Remove artifacts from a previous failed export (keep Gradle template files).
rm -rf "$GODOT_DIR/android/build/assets" "$GODOT_DIR/android/build/build" "$GODOT_DIR/android/build/.gradle"
find "$GODOT_DIR/android/build/res" -name '*.import' -delete 2>/dev/null || true
rm -rf "$GODOT_DIR/android/build/res/mipmap" "$GODOT_DIR/android/build/res/mipmap-"* 2>/dev/null || true

PRESET="Android Debug APK"
OUTPUT="$BUILD_DIR/lost-number-debug.apk"

if [[ "$MODE" == "release" ]]; then
  PRESET="Android"
  OUTPUT="$BUILD_DIR/lost-number.aab"
  KEYSTORE_PROPS="$ROOT/android/keystore.properties"

  if [[ ! -f "$KEYSTORE_PROPS" ]]; then
    echo "Missing $KEYSTORE_PROPS for release signing." >&2
    exit 1
  fi

  # Parse key=value pairs instead of sourcing: passwords with $, spaces or &
  # must not be interpreted by the shell.
  _prop() {
    local line
    line="$(grep -E "^[[:space:]]*$1[[:space:]]*=" "$KEYSTORE_PROPS" | tail -1)" || true
    printf '%s' "${line#*=}" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
  }
  storeFile="$(_prop storeFile)"
  storePassword="$(_prop storePassword)"
  keyAlias="$(_prop keyAlias)"
  keyPassword="$(_prop keyPassword)"
  if [[ -z "$storeFile" || -z "$storePassword" || -z "$keyAlias" || -z "$keyPassword" ]]; then
    echo "keystore.properties is missing storeFile/storePassword/keyAlias/keyPassword." >&2
    exit 1
  fi
  STORE_PATH="$ROOT/android/${storeFile}"
  if [[ ! -f "$STORE_PATH" ]]; then
    echo "Keystore not found: $STORE_PATH" >&2
    exit 1
  fi

  EXPORT_CFG="$GODOT_DIR/export_presets.cfg"
  EXPORT_CFG_BACKUP="$(mktemp)"
  cp "$EXPORT_CFG" "$EXPORT_CFG_BACKUP"
  restore_export_cfg() {
    if [[ -n "${EXPORT_CFG_BACKUP:-}" && -f "$EXPORT_CFG_BACKUP" ]]; then
      mv -f "$EXPORT_CFG_BACKUP" "$EXPORT_CFG"
    fi
  }
  trap restore_export_cfg EXIT

  # Inject signing at export time only (passwords never committed).
  sed -i '/^keystore\//d' "$EXPORT_CFG"
  cat >> "$EXPORT_CFG" <<EOF

[preset.0.options]

keystore/release="$STORE_PATH"
keystore/release_user="$keyAlias"
keystore/release_password="$storePassword"
keystore/release_user_password="$keyPassword"
EOF
fi

echo "Exporting $PRESET -> $OUTPUT"
if [[ "$MODE" == "release" ]]; then
  "$GODOT_BIN" --path "$GODOT_DIR" --headless --export-release "$PRESET" "$OUTPUT"
else
  "$GODOT_BIN" --path "$GODOT_DIR" --headless --export-debug "$PRESET" "$OUTPUT"
fi

if [[ "$MODE" == "release" ]]; then
  restore_export_cfg
  trap - EXIT
fi

echo "Done: $OUTPUT"
ls -lh "$OUTPUT"
