#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
mkdir -p "$PROJECT_DIR/build"

# Keep the temporary tree under the project/home mount. The Flatpak Godot
# wrapper cannot see the host's /tmp, even when the parent shell exports XDG.
ISOLATED_ROOT="$(mktemp -d "$PROJECT_DIR/build/.godot-userdata.XXXXXX")"
cleanup() {
  rm -rf "$ISOLATED_ROOT"
}
trap cleanup EXIT INT TERM

export XDG_DATA_HOME="$ISOLATED_ROOT/data"
export XDG_CONFIG_HOME="$ISOLATED_ROOT/config"
export XDG_CACHE_HOME="$ISOLATED_ROOT/cache"
export LOSTNUMBER_CAPTURE_ISOLATED=1
export LOSTNUMBER_ISOLATED_USER_ROOT="$XDG_DATA_HOME"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <godot-command> [args...]" >&2
  exit 64
fi

GODOT_COMMAND="$1"
shift
GODOT_BINARY="$(command -v "$GODOT_COMMAND" || true)"

# The local godot4 command is a Flatpak wrapper. Flatpak replaces XDG paths,
# so pass the isolated directories into the sandbox explicitly.
if [[ -n "$GODOT_BINARY" ]] \
  && command -v flatpak >/dev/null 2>&1 \
  && grep -q "org.godotengine.Godot" "$GODOT_BINARY"; then
  # Flatpak rewrites reserved XDG variables after processing --env options.
  # Launch through env *inside* the sandbox so Godot sees the test paths.
  flatpak run \
    --filesystem=home \
    --command=env \
    org.godotengine.Godot \
    XDG_DATA_HOME="$XDG_DATA_HOME" \
    XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
    XDG_CACHE_HOME="$XDG_CACHE_HOME" \
    LOSTNUMBER_CAPTURE_ISOLATED=1 \
    LOSTNUMBER_ISOLATED_USER_ROOT="$LOSTNUMBER_ISOLATED_USER_ROOT" \
    godot \
    "$@"
else
  "$GODOT_COMMAND" "$@"
fi
