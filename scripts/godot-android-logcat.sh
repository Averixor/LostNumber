#!/usr/bin/env bash
# Stream Lost Number (Godot) logs from connected Android device.
set -euo pipefail

PKG_DEV="com.averixor.lostnumber.dev"

adb start-server >/dev/null 2>&1 || true

if ! adb devices | awk 'NR>1 && $2=="device" {found=1} END{exit !found}'; then
  echo "Нет устройства. Включи USB-отладку и подтверди RSA на телефоне." >&2
  exit 1
fi

MODEL="$(adb devices -l | awk 'NR==2{for(i=1;i<=NF;i++) if($i~/model:/) print $i}')"
echo "Устройство подключено: ${MODEL:-ok}"
echo "Пакет: $PKG_DEV"
echo ""
echo "Запусти игру на телефоне и воспроизведи баг — логи пойдут ниже."
echo "Ctrl+C — остановить."
echo "────────────────────────────────────────"

adb logcat -c

PID="$(adb shell pidof -s "$PKG_DEV" 2>/dev/null | tr -d '\r' || true)"

if [[ -n "$PID" && "$PID" =~ ^[0-9]+$ ]]; then
  echo "(фильтр по PID $PID — только ошибки Godot/скриптов)"
  exec adb logcat -v time --pid="$PID" 2>&1 | grep -iE --line-buffered \
    'E/godot|W/godot|SCRIPT ERROR|push_error|push_warning|GDScript|FATAL EXCEPTION|AndroidRuntime'
fi

echo "(игра не запущена — общий фильтр Godot/ошибки; открой Lost Number на телефоне)"
exec adb logcat -v time 2>&1 | grep -iE --line-buffered \
  'godot|GDScript|SCRIPT ERROR|push_error|push_warning|AndroidRuntime|FATAL|averixor\.lostnumber'
