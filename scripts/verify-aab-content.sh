#!/usr/bin/env bash
set -euo pipefail

AAB="${1:-android/app/build/outputs/bundle/release/app-release.aab}"

if [ ! -f "$AAB" ]; then
  echo "❌ AAB не найден: $AAB"
  exit 1
fi

SIZE_MB=$(du -m "$AAB" | cut -f1)

echo "Проверяю: $AAB"
echo "Размер: ${SIZE_MB} MB"

if [ "$SIZE_MB" -lt 25 ]; then
  echo "❌ AAB подозрительно маленький. Возможно, это пустая Capacitor/Vite-сборка."
  exit 1
fi

TMP_LIST="$(mktemp)"
trap 'rm -f "$TMP_LIST"' EXIT

unzip -l "$AAB" > "$TMP_LIST"

check_file() {
  local pattern="$1"
  local label="$2"

  if grep -E "$pattern" "$TMP_LIST" >/dev/null; then
    echo "✅ $label"
  else
    echo "❌ Нет: $label"
    exit 1
  fi
}

echo "=== Проверка игровых файлов ==="

check_file 'LostNumberGame\.js' 'LostNumberGame.js'
check_file 'game-flow\.js' 'game-flow.js'
check_file 'save-load\.js' 'save-load.js'
check_file 'grid\.css' 'grid.css'
check_file 'ui\.css' 'ui.css'

echo "=== Проверка аудио ==="

AUDIO_COUNT=$(grep -Ei '\.(mp3|ogg|wav|m4a)$' "$TMP_LIST" | wc -l)

if [ "$AUDIO_COUNT" -lt 5 ]; then
  echo "❌ Слишком мало аудиофайлов: $AUDIO_COUNT"
  exit 1
fi

echo "✅ Аудиофайлов: $AUDIO_COUNT"

echo "=== Проверка на Vite-пустышку ==="

if grep -Ei 'vite-BF8QNONU|vite\.svg|hero-CLDdwZDr' "$TMP_LIST" >/dev/null; then
  echo "❌ Похоже на пустую Vite-сборку"
  exit 1
fi

echo "✅ Vite-пустышки не видно"
echo "✅ AAB похож на полноценную сборку Lost Number"
