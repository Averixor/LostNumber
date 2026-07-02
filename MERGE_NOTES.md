# Lost Number — єдиний проєкт (консолідація)

**Канонічна папка:** `~/Desktop/LostNumber` — усі архіви злиті сюди.

## Джерела (що було на Desktop)

| Файл                          | Роль                            | Статус                                                    |
| ----------------------------- | ------------------------------- | --------------------------------------------------------- |
| `LostNumber-good-project.zip` | Web + Capacitor + Godot + store | **База** — вже в репо                                     |
| `LostNumber-handoff (1).zip`  | Старіший handoff                | **Не використовувати** — гірші chain/audio фікси          |
| `Нова тека.zip`               | Логотипи, фони, feature graphic | **Вже в** `assets/`, `store/google-play-games/originals/` |
| `lost-number-debug.apk`       | Godot debug збірка              | **Скопійовано в** `build/godot/android/`                  |
| `lost-number.aab`             | Godot release для Play          | **Скопійовано в** `build/godot/android/`                  |

## Що взято з кожного джерела

### good-project + поточна робота (перемагає)

- Повна web-гра (`js/`, `css/`, `index.html`) з фіксами chain/touch
- Capacitor Android (`android/`, `npm run android:*`)
- Godot 4 MVP + **Android export** (`godot/export_presets.cfg`, `scripts/godot-android-export.sh`)
- Аудіо в Godot (`godot/assets/audio/`, `AudioManager.gd`)
- Path interpolation у `godot/scripts/game/Board.gd`
- Store listing (`store/`, `godot/docs/store-listing/`)

### handoff — свідомо відкинуто

- Скидання chain при pointer leave
- Немає `store/google-play-games/`
- Тонший Godot без NumberFormatter/PlayerProgress

### Нова тека — лише графіка (вже інтегрована)

- `store/feature-graphic-1024x500.png`
- `store/google-play-games/cover-1920x1080.jpg`, `logo-600x400.png`
- Оригінали логотипів у `store/google-play-games/originals/`

## Два шляхи Android

| Мета                            | Команда                         | Артефакт                                            |
| ------------------------------- | ------------------------------- | --------------------------------------------------- |
| **Play Market (рекомендовано)** | `npm run godot:android:release` | `build/godot/android/lost-number.aab`               |
| Debug на телефон (Godot)        | `npm run godot:android:debug`   | `build/godot/android/lost-number-debug.apk`         |
| WebView (legacy)                | `npm run android:debug:cheats`  | `android/app/build/outputs/apk/debug/app-debug.apk` |

## Перевірка після клону / розпакування

```bash
npm ci
npm run release:check
npm run test:smoke
npm run godot:test
```

Godot Android (один раз): JDK у `~/Android/jbr`, SDK у `~/Android/Sdk` — див. `godot/docs/PLAY_STORE_GODOT.md`.

## Запакувати один архів для передачі

```bash
./scripts/pack-unified.sh
# → dist/LostNumber-unified.zip
```
