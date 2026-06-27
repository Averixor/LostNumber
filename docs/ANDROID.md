# Lost Number — Android (Capacitor)

Гра збирається як **нативна Android-обгортка** навколо того ж HTML/CSS/JS, що й веб-версія. Движок — [Capacitor 7](https://capacitorjs.com/).

## Що вже налаштовано

| Компонент                              | Призначення                                                |
| -------------------------------------- | ---------------------------------------------------------- |
| `capacitor.config.json`                | `appId`, `appName`: Lost Number, `webDir: _site`, portrait |
| `android/`                             | Gradle-проєкт Android Studio                               |
| `js/bootstrap/capacitor-bridge.js`     | Status bar, `ln-native-app`, автозбереження при згортанні  |
| `js/app/navigation/back-navigation.js` | Системна кнопка «Назад» (`@capacitor/app`)                 |
| `public/audio/` → `_site/audio/`       | Музика та SFX у APK (див. `docs/AUDIO.md`)                 |
| `npm run android:prepare`              | `build:pages` + `cap sync android`                         |
| `npm run verify:android`               | Release security + `_site` bundle prerequisites            |
| `docs/ANDROID_QA.md`                   | Manual QA checklist перед установкою APK на телефон        |

**Capacitor-плагіни:** `@capacitor/status-bar`, `@capacitor/app`.

**Важливо:** у нативному APK чити **вимкнені** (Capacitor `localhost` не вважається dev-середовищем).

### Кнопка «Назад» (Android)

| Екран                                                  | Дія                                |
| ------------------------------------------------------ | ---------------------------------- |
| Колесо / оверлей рівня / перемога / confirm «Нова гра» | Закрити оверлей або перейти в меню |
| Ігрове поле                                            | Зберегти → головне меню            |
| Налаштування, статистика, завдання…                    | Головне меню                       |
| Головне меню                                           | `App.exitApp()`                    |

Реалізація: `handleBackNavigation()` + `setupNativeBackButton()` у `back-navigation.js`, виклик з `boot.js`.

## Вимоги

1. **Node.js** 18+ і `npm install` у корені репозиторію.
2. **JDK 17** — `openjdk-17-jdk` або SDKMAN (`sdk install java 17.0.13-tem`).
3. **Android Studio** + Android SDK 34+.

Швидка установка на Linux (у **своєму** терміналі, не в агенті без sudo):

```bash
bash scripts/install-android-studio.sh
source ~/.bashrc
```

Скрипт ставить Studio у `~/Android/android-studio` (або через `snap`, якщо є sudo) і дописує в `~/.bashrc` змінні `CAPACITOR_ANDROID_STUDIO_PATH`, `JAVA_HOME`, `ANDROID_HOME`.

## Швидкий старт

```bash
npm install
npm run android:prepare    # зібрати _site/ і скопіювати в android/
npm run android:open       # відкрити проєкт у Android Studio
```

У Android Studio: **Run ▶** на емуляторі або підключеному телефоні.

## CLI без Android Studio (якщо SDK налаштований)

```bash
npm run android:run
```

Або вручну:

```bash
cd android
./gradlew assembleDebug
# APK: android/app/build/outputs/apk/debug/app-debug.apk
```

Release AAB для Google Play:

```bash
cd android
./gradlew bundleRelease
# android/app/build/outputs/bundle/release/app-release.aab
```

Для release потрібен підписаний keystore (Android Studio → Build → Generate Signed Bundle).

## Робочий цикл розробки

1. Змінюєте `index.html`, `js/`, `css/` у корені репозиторію.
2. `npm run android:prepare` — оновлює assets у `android/`.
3. Знову Run у Android Studio (або `android:run`).

Під час розробки UI можна тестувати в браузері (`npx serve .` або Live Server) — швидше, ніж кожен раз збирати APK.

## Іконка застосунку

Брендовані іконки вже в проєкті. Після зміни `assets/icons/icon-1024.png`:

```bash
python3 scripts/generate-android-icons.py
cd android && ./gradlew assembleDebug
```

- **512×512** — `assets/icons/icon.png` (PWA, favicon)
- **1024×1024** — `assets/icons/icon-1024.png` (мастер для Android adaptive icon)

Скрипт генерує `mipmap-*/ic_launcher.png`, `ic_launcher_round.png`, `ic_launcher_foreground.png`; фон adaptive icon — `#1B1028`.

Альтернатива: Android Studio → Image Asset з `assets/icons/icon.png`, або [@capacitor/assets](https://github.com/ionic-team/capacitor-assets).

## PWA без магазину

Якщо APK не потрібен — гра вже PWA: відкрийте на телефоні  
<https://averixor.github.io/LostNumber/> → «Додати на головний екран».

## Дебаг-збірка з читами

У `capacitor.config.json` для debug можна тимчасово:

```json
"android": {
  "webContentsDebuggingEnabled": true
}
```

У `index.html` перед gate (лише для внутрішніх build):

```html
<script>
  window.LN_BUILD_FLAGS = { cheatsEnabled: true };
</script>
```

Не включайте `cheatsEnabled` у release для Play Store.

## Структура

```
public/audio/       ← джерело звуків (не в корені репо)
_site/              ← web-артефакт (npm run build:pages)
android/            ← нативний проєкт
capacitor.config.json
js/bootstrap/capacitor-bridge.js
js/app/navigation/back-navigation.js
```

Аудіо в APK: після `build:pages` файли лежать у `_site/audio/` і потрапляють у assets WebView. Шляхи в коді: `audio/sfx/...`, `audio/music/...`.

## Типові проблеми

| Проблема                 | Рішення                                                             |
| ------------------------ | ------------------------------------------------------------------- |
| Білий екран              | `npm run android:prepare`, перевірити Logcat                        |
| Старий UI після змін     | Знову `android:prepare`                                             |
| `SDK location not found` | Створити `android/local.properties`: `sdk.dir=/path/to/Android/sdk` |
| Gradle fails             | File → Invalidate Caches у Android Studio                           |
