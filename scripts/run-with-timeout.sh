#!/usr/bin/env bash
# Кросплатформенний timeout: Linux (timeout), macOS (gtimeout) або без обмеження.
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <duration> <command> [args...]" >&2
  exit 2
fi

DURATION="$1"
shift

if command -v timeout >/dev/null 2>&1; then
  exec timeout "$DURATION" "$@"
fi

if command -v gtimeout >/dev/null 2>&1; then
  exec gtimeout "$DURATION" "$@"
fi

echo "error: neither 'timeout' nor 'gtimeout' found; cannot enforce timeout" >&2
exit 1
