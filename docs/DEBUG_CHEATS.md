# Lost Number — Debug APK з читами

Окремий **debug**-шлях для особистого тестування на телефоні. **Release APK завжди без читів.**

| Збірка  | Package ID                    | Чити      | Label           |
| ------- | ----------------------------- | --------- | --------------- |
| Release | `com.averixor.lostnumber`     | вимкнено  | Lost Number     |
| Debug   | `com.averixor.lostnumber.dev` | увімкнено | Lost Number DEV |

Debug і release ставляться **поруч** — окремі package id, окремі сейви, без конфлікту підпису release-ключа.

## Як зібрати

### Debug APK з читами

```bash
npm run android:debug:cheats
```

Що відбувається:

1. `build:flags:debug-cheats` → `cheatsEnabled: true` у `js/system/build-flags.generated.js`
2. `build:pages` + `cap sync android`
3. `./gradlew assembleDebug` → `applicationIdSuffix .dev`
4. **Відновлення** `build:flags:release` → робоче дерево знову з `cheatsEnabled: false`

APK: `android/app/build/outputs/apk/debug/app-debug.apk`

### Release APK без читів

```bash
npm run android:release
```

APK: `android/app/build/outputs/apk/release/app-release.apk`

## Встановлення на телефон

```bash
adb install -r android/app/build/outputs/apk/debug/app-debug.apk
adb shell monkey -p com.averixor.lostnumber.dev 1
```

Release (окремо):

```bash
adb install -r android/app/build/outputs/apk/release/app-release.apk
adb shell monkey -p com.averixor.lostnumber 1
```

## Чит-панель у debug APK

Після встановлення **Lost Number DEV**:

- **Ctrl+Backquote** / **Ctrl+`** або `window.LN_CODES.panel()` у WebView console (якщо debugging увімкнено)
- Або 5 кліків по easter-egg тригеру в «Про гру» → режим розробника

Скрипт `js/system/dev/cheats.js` завантажується лише коли `LN_isDevToolsAllowed()` === true, тобто при `cheatsEnabled: true` на native.

## Build flags (не редагувати вручну)

Файл: `js/system/build-flags.generated.js`

```javascript
window.LN_BUILD_FLAGS = { cheatsEnabled: false };
```

| Команда                            | Результат              |
| ---------------------------------- | ---------------------- |
| `npm run build:flags:release`      | `cheatsEnabled: false` |
| `npm run build:flags:debug-cheats` | `cheatsEnabled: true`  |

У **main** комітиться тільки версія з `false`. `release:check` падає, якщо у робочій копії `true`.

## npm scripts

| Script                      | Призначення                                                      |
| --------------------------- | ---------------------------------------------------------------- |
| `android:sync`              | release flags + build + cap sync                                 |
| `android:sync:debug-cheats` | debug flags + build + sync (лише для sync, flags лишаються true) |
| `android:debug:cheats`      | повний debug APK + restore release flags                         |
| `android:release`           | release APK                                                      |

## Перевірка, що release чистий

```bash
npm run release:check
rg -n "cheatsEnabled:\s*true" index.html js/system/build-flags.generated.js
```

Для release-гілки остання команда має **нічого не виводити** (або лише коментар у generated-файлі — ні, там має бути false).

Після `android:sync:debug-cheats` без `android:debug:cheats` — поверни flags:

```bash
npm run build:flags:release
```

## Безпека

- Не коміть `cheatsEnabled: true` у main
- Не додавай `window.LN_BUILD_FLAGS = { cheatsEnabled: true }` у `index.html`
- Release для Play Store — тільки `npm run android:release`

Див. також: [ANDROID.md](./ANDROID.md), [ANDROID_QA.md](./ANDROID_QA.md)
