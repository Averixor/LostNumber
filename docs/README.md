# Документація Lost Number

**Єдина playable-реалізація:** Godot 4 Android (`godot/`, `npm run godot:android:release` → `build/android/lost-number.aab`).

Точка входу в репозиторій: **[README.md](../README.md)**.

## Швидкі посилання

| Задача                                     | Документ                                                                       |
| ------------------------------------------ | ------------------------------------------------------------------------------ |
| Запуск Godot, npm-скрипти                  | [README.md](../README.md)                                                      |
| Godot (Android), Boot→App                  | [godot/README.md](../godot/README.md)                                          |
| Структура папок                            | [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)                                 |
| Production handoff                         | [HANDOFF-IDEAL.md](./HANDOFF-IDEAL.md)                                         |
| Android (Godot)                            | [ANDROID.md](./ANDROID.md)                                                     |
| Android release checklist                  | [ANDROID_RELEASE_READINESS.md](./ANDROID_RELEASE_READINESS.md)                 |
| Roadmap (Play-first)                       | [ROADMAP.md](./ROADMAP.md)                                                     |
| Аудит 360°                                 | [AUDIT_PLAY_360.md](./AUDIT_PLAY_360.md)                                       |
| Play Console recon                         | [PLAY_CONSOLE_RECON.md](./PLAY_CONSOLE_RECON.md)                               |
| Closed testing runbook                     | [CLOSED_TESTING_RUNBOOK.md](./CLOSED_TESTING_RUNBOOK.md)                       |
| Closed testing smoke checklist (OWNER)     | [CT_SMOKE_CHECKLIST.md](./CT_SMOKE_CHECKLIST.md)                               |
| Stage 1 release record                     | [STAGE1_RELEASE_RECORD.md](./STAGE1_RELEASE_RECORD.md)                         |
| Stage 2 prep (no CT upload)                | [STAGE2_PREP.md](./STAGE2_PREP.md)                                             |
| Stage 3 repo hardening                     | [STAGE3_REPO_HARDENING.md](./STAGE3_REPO_HARDENING.md)                         |
| Stage 3 closeout                           | [STAGE3_CLOSEOUT.md](./STAGE3_CLOSEOUT.md)                                     |
| Firebase Stage 4 **sequence** (OWNER path) | [FIREBASE_STAGE4_SEQUENCE.md](./FIREBASE_STAGE4_SEQUENCE.md)                   |
| Firebase Stage 4 gates (OWNER)             | [FIREBASE_STAGE4_GATES.md](./FIREBASE_STAGE4_GATES.md)                         |
| Firebase ADR (en)                          | [en/FIREBASE_ADR.md](./en/FIREBASE_ADR.md)                                     |
| Firebase OWNER Console runbook             | [FIREBASE_OWNER_RUNBOOK.md](./FIREBASE_OWNER_RUNBOOK.md)                       |
| Firebase privacy delta                     | [FIREBASE_PRIVACY_DELTA.md](./FIREBASE_PRIVACY_DELTA.md)                       |
| QA перед релізом на телефон                | [ANDROID_QA.md](./ANDROID_QA.md)                                               |
| Google Play Console                        | [PLAY_STORE.md](./PLAY_STORE.md), [PLAY_STORE_GODOT.md](./PLAY_STORE_GODOT.md) |
| Тексти та графіка для листингу             | [store/PLAY_CONSOLE_LISTING.md](../store/PLAY_CONSOLE_LISTING.md)              |
| Privacy Policy (файл + хостинг)            | [privacy.html](../privacy.html), [PRIVACY_HOSTING.md](./PRIVACY_HOSTING.md)    |
| Звук (музика, SFX)                         | [AUDIO.md](./AUDIO.md)                                                         |
| Дебаг-збірка                               | [DEBUG_CHEATS.md](./DEBUG_CHEATS.md)                                           |
| Legacy save import                         | [LEGACY_SAVE_MIGRATION.md](./LEGACY_SAVE_MIGRATION.md)                         |
| Правила гри                                | [GAME_RULES.md](./GAME_RULES.md)                                               |
| **English documentation**                  | [docs/en/README.md](./en/README.md)                                            |
| **Source of truth (canonical)**            | [docs/en/SOURCE_OF_TRUTH.md](./en/SOURCE_OF_TRUTH.md)                          |
| **Візуальний target**                      | [docs/en/VISUAL_TARGET.md](./en/VISUAL_TARGET.md)                              |
| **Архів (міграція JS→Godot)**              | [archive/](./archive/)                                                         |

## Реліз Android → Play Console

1. `npm run release:check` — format, lint, tagline, Godot export config, smoke
2. `npm run godot:android:release` → `build/android/lost-number.aab`
3. `npm run store:prepare` → оновити `store/` (іконка, feature graphic, скріншоти)
4. Privacy URL — [PRIVACY_HOSTING.md](./PRIVACY_HOSTING.md)
5. Заповнити Console за [PLAY_STORE.md](./PLAY_STORE.md)
6. Завантажити AAB у **Closed testing**

## CI

| Workflow                   | Призначення                        |
| -------------------------- | ---------------------------------- |
| `.github/workflows/ci.yml` | `npm run release:check` на push/PR |

Godot headless tests (`npm run godot:test:all`) — локально перед upload.

## Архів

Історичні документи міграції з Web/JS/Capacitor — **`docs/archive/`**. Не використовуйте як актуальний source of truth.
