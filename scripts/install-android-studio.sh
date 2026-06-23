#!/usr/bin/env bash
# Установка Android Studio на Linux (без привязки к /usr/local).
# Запускай в своём терминале: bash scripts/install-android-studio.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="${ANDROID_STUDIO_HOME:-$HOME/Android/android-studio}"
DIST_DIR="$HOME/Android/dist"
STUDIO_URL="https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2026.1.1.2/android-studio-quail1-patch2-linux.tar.gz"
STUDIO_TAR="$DIST_DIR/android-studio-quail1-patch2-linux.tar.gz"
STUDIO_SH="$INSTALL_DIR/bin/studio.sh"
BASHRC="$HOME/.bashrc"

mark_bashrc() {
  local key="$1"
  local line="$2"
  if ! grep -q "$key" "$BASHRC" 2>/dev/null; then
    {
      echo ""
      echo "# LostNumber / Android ($key)"
      echo "$line"
    } >>"$BASHRC"
  fi
}

echo "==> JDK"
if command -v java >/dev/null 2>&1; then
  java -version
else
  if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk install java 17.0.13-tem
  else
    echo "Нет Java. Установи: sudo apt install openjdk-17-jdk"
    echo "Или SDKMAN: curl -s https://get.sdkman.io | bash && sdk install java 17.0.13-tem"
    exit 1
  fi
fi

if [[ -x "$STUDIO_SH" ]]; then
  echo "Android Studio уже есть: $STUDIO_SH"
else
  if command -v snap >/dev/null 2>&1 && ! snap list android-studio >/dev/null 2>&1; then
    echo "==> Пробую snap (нужен sudo)..."
    if sudo snap install android-studio --classic; then
      STUDIO_SH="/snap/android-studio/current/bin/studio.sh"
    fi
  fi

  if [[ ! -x "$STUDIO_SH" ]]; then
    echo "==> Скачиваю tarball (~1.5 GB)..."
    mkdir -p "$DIST_DIR"
    curl -fL --retry 3 -o "$STUDIO_TAR" "$STUDIO_URL"
    echo "==> Распаковка в $HOME/Android ..."
    mkdir -p "$HOME/Android"
    tar -xzf "$STUDIO_TAR" -C "$HOME/Android"
    if [[ -x "$HOME/Android/android-studio/bin/studio.sh" ]]; then
      INSTALL_DIR="$HOME/Android/android-studio"
      STUDIO_SH="$INSTALL_DIR/bin/studio.sh"
    else
      echo "Не найден bin/studio.sh после распаковки. Проверь $HOME/Android"
      exit 1
    fi
  fi
fi

mark_bashrc "CAPACITOR_ANDROID_STUDIO_PATH" "export CAPACITOR_ANDROID_STUDIO_PATH=\"$STUDIO_SH\""
mark_bashrc "JAVA_HOME" "export JAVA_HOME=\"\${JAVA_HOME:-\$(dirname \"\$(dirname \"\$(readlink -f \"\$(command -v java)\")\")\")}\""
mark_bashrc "ANDROID_HOME" "export ANDROID_HOME=\"\${ANDROID_HOME:-\$HOME/Android/Sdk}\""

export CAPACITOR_ANDROID_STUDIO_PATH="$STUDIO_SH"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"

echo ""
echo "Готово."
echo "  Studio:  $STUDIO_SH"
echo "  SDK:     \$ANDROID_HOME (создастся при первом запуске Studio)"
echo ""
echo "Дальше:"
echo "  source ~/.bashrc"
echo "  cd $ROOT && npm run android:open"
echo ""
echo "Первый раз открой Studio вручную, пройди мастер и установи Android SDK."
