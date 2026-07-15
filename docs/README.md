# Документація Lost Number

**Єдина playable-реалізація:** Godot 4 Android (`godot/`, `npm run godot:android:release` → `build/android/lost-number.aab`).

Точка входу в репозиторій: **[README.md](../README.md)**.

## Швидкі посилання

| Задача | Документ |
| ------ | -------- |
| Запуск Godot, npm-скрипти | [README.md](../README.md) |
| Godot (Android), Boot→App | [godot/README.md](../godot/README.md) |
| Структура папок | [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md) |
| Production handoff | [HANDOFF-IDEAL.md](./HANDOFF-IDEAL.md) |
| Android (Godot) | [ANDROID.md](./ANDROID.md) |
| Android release checklist | [ANDROID_RELEASE_READINESS.md](./ANDROID_RELEASE_READINESS.md) |
| QA перед релізом на телефон | [ANDROID_QA.md](./ANDROID_QA.md) |
| Google Play Console | [PLAY_STORE.md](./PLAY_STORE.md), [PLAY_STORE_GODOT.md](./PLAY_STORE_GODOT.md) |
| Тексти та графіка для листингу | [store/PLAY_CONSOLE_LISTING.md](../store/PLAY_CONSOLE_LISTING.md) |
| Privacy Policy (файл + хостинг) | [privacy.html](../privacy.html), [PRIVACY_HOSTING.md](./PRIVACY_HOSTING.md) |
| Звук (музика, SFX) | [AUDIO.md](./AUDIO.md) |
| Дебаг-збірка | [DEBUG_CHEATS.md](./DEBUG_CHEATS.md) |
| Legacy save import | [LEGACY_SAVE_MIGRATION.md](./LEGACY_SAVE_MIGRATION.md) |
| Правила гри | [GAME_RULES.md](./GAME_RULES.md) |
| **English documentation** | [docs/en/README.md](./en/README.md) |
| **Source of truth (canonical)** | [docs/en/SOURCE_OF_TRUTH.md](./en/SOURCE_OF_TRUTH.md) |
| **Візуальний target** | [docs/en/VISUAL_TARGET.md](./en/VISUAL_TARGET.md) |
| **Архів (міграція JS→Godot)** | [archive/](./archive/) |

## Реліз Android → Play Console

1. `npm run release:check` — format, lint, tagline, Godot export config, smoke
2. `npm run godot:android:release` → `build/android/lost-number.aab`
3. `npm run store:prepare` → оновити `store/` (іконка, feature graphic, скріншоти)
4. Privacy URL — [PRIVACY_HOSTING.md](./PRIVACY_HOSTING.md)
5. Заповнити Console за [PLAY_STORE.md](./PLAY_STORE.md)
6. Завантажити AAB у **Closed testing**

## CI

| Workflow | Призначення |
| -------- | ----------- |
| `.github/workflows/ci.yml` | `npm run release:check` на push/PR |

Godot headless tests (`npm run godot:test:all`) — локально перед upload.

## Архів

Історичні документи міграції з Web/JS/Capacitor — **`docs/archive/`**. Не використовуйте як актуальний source of truth.
