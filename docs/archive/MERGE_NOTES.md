# Lost Number — єдиний проєкт (консолідація)

> **Архів (2026-07):** Історичний документ про злиття zip-архівів. Актуальний стан — Godot-only, див. [docs/README.md](../README.md).

**Канонічна папка:** `~/Desktop/LostNumber` — усі архіви злиті сюди.

## Джерела (що було на Desktop)

| Файл                          | Роль                            | Статус                                                    |
| ----------------------------- | ------------------------------- | --------------------------------------------------------- |
| `LostNumber-good-project.zip` | Web + Capacitor + Godot + store | **База** — вже в репо                                     |
| `LostNumber-handoff (1).zip`  | Старіший handoff                | **Не використовувати** — гірші chain/audio фікси          |
| `Нова тека.zip`               | Логотипи, фони, feature graphic | **Вже в** `assets/`, `store/google-play-games/originals/` |
| `lost-number-debug.apk`       | Godot debug збірка              | **Скопійовано в** `build/android/`                        |
| `lost-number.aab`             | Godot release для Play          | **Скопійовано в** `build/android/`                        |

## Що взято з кожного джерела

### good-project + поточна робота (перемагає)

- Godot 4.5 Android — єдина playable-реалізація (`godot/`)
- Godot 4 + **Android export** (`godot/export_presets.cfg`, `scripts/godot-android-export.sh`) — **єдиний Android ship path**
- Godot UI shell Sprint 1: Boot/App, ScreenRouter, BackgroundLayer, NeonButton, ThemeTokens (`docs/archive/VISUAL_PORT_MAP.md`)
- Аудіо в Godot (`godot/assets/audio/`, `AudioManager.gd`)
- Path interpolation у `godot/scripts/game/Board.gd`
- Store listing (`store/`, `docs/store-listing/`)

### handoff — свідомо відкинуто

- Скидання chain при pointer leave
- Немає `store/google-play-games/`
- Тонший Godot без NumberFormatter/PlayerProgress (застаріло — у поточному godot/ ці модулі є)

### Нова тека — лише графіка (вже інтегрована)

- `store/feature-graphic-1024x500.png`
- `store/google-play-games/cover-1920x1080.jpg`, `logo-600x400.png`
- Оригінали логотипів у `store/google-play-games/originals/`

## Android (Godot only)

| Мета             | Команда                         | Артефакт                              |
| ---------------- | ------------------------------- | ------------------------------------- |
| **Play Market**  | `npm run godot:android:release` | `build/android/lost-number.aab`       |
| Debug на телефон | `npm run godot:android:debug`   | `build/android/lost-number-debug.apk` |

> Capacitor/WebView шлях видалено з репозиторію (2026-07).

## Перевірка після клону / розпакування

```bash
npm ci
npm run release:check
npm run test:smoke
npm run godot:test:all
```

Godot Android (один раз): JDK у `~/Android/jbr`, SDK у `~/Android/Sdk` — див. `docs/PLAY_STORE_GODOT.md`.

## Запакувати один архів для передачі

```bash
./scripts/pack-unified.sh
# → dist/LostNumber-unified.zip
```
