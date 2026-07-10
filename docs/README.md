# Документація Lost Number

Короткий навігатор по репозиторію. Точка входу для розробника — **[README.md](../README.md)**.

**Primary ship target:** Godot 4 Android (`godot/`, `npm run godot:android:release`). Capacitor/Web (`js/`, `android/`) — візуальний еталон і legacy-збірка, не основний шлях у Play.

## Швидкі посилання

| Задача                                 | Документ                                                          |
| -------------------------------------- | ----------------------------------------------------------------- |
| Запуск у браузері, npm-скрипти         | [README.md](../README.md)                                         |
| Godot (primary Android), Boot→App      | [godot/README.md](../godot/README.md)                             |
| Візуальний перенос web → Godot         | [godot/docs/VISUAL_PORT_MAP.md](../godot/docs/VISUAL_PORT_MAP.md) |
| Структура папок і потоки коду          | [PROJECT_STRUCTURE.md](../PROJECT_STRUCTURE.md)                   |
| Android APK / AAB, Capacitor (legacy)  | [ANDROID.md](./ANDROID.md)                                        |
| QA перед релізом на телефон            | [ANDROID_QA.md](./ANDROID_QA.md)                                  |
| Google Play Console, IARC, Data safety | [PLAY_STORE.md](./PLAY_STORE.md)                                  |
| Тексти та графіка для листингу         | [store/PLAY_CONSOLE_LISTING.md](../store/PLAY_CONSOLE_LISTING.md) |
| GitHub Pages і privacy URL             | [GITHUB_PAGES.md](./GITHUB_PAGES.md)                              |
| Політика конфіденційності (файл)       | [privacy.html](../privacy.html)                                   |
| Звук (музика, SFX)                     | [AUDIO.md](./AUDIO.md)                                            |
| Дебаг-збірка з читами                  | [DEBUG_CHEATS.md](./DEBUG_CHEATS.md)                              |
| Етапи розвитку (performance, Firebase) | [PHASES.md](./PHASES.md)                                          |
| **English documentation (en)**         | [docs/en/README.md](./en/README.md)                              |

## Реліз Android → Play Console (порядок)

> **Актуальний ship target — Godot** (`npm run godot:android:release`, див. `godot/docs/ANDROID_RELEASE_READINESS.md` та `HANDOFF-IDEAL.md`). Порядок нижче — для legacy Capacitor-збірки.

1. `npm run release:check` — format, lint, typecheck, smoke-тести
2. `npm run verify:android` — release security і bundle prerequisites
3. `npm run android:bundle` → `android/app/build/outputs/bundle/release/app-release.aab`
4. `npm run store:prepare` → оновити `store/` (іконка, feature graphic, скріншоти)
5. Переконатися, що **privacy URL** відкривається ([GITHUB_PAGES.md](./GITHUB_PAGES.md))
6. Заповнити Console за [PLAY_STORE.md](./PLAY_STORE.md) (IARC, Data safety, листинг)
7. Завантажити AAB у **Closed testing**

## Тексти магазину

Готові рядки для копіювання: **`store/PLAY_CONSOLE_LISTING.md`**.

Окремі файли локалей: `docs/store-listing/` (uk, en, ru).

## Godot (primary ship target)

Godot — **основна** ціль релізу Android. Capacitor/Web — legacy і джерело візуального паритету.

- Запуск: `Boot.tscn` → `App.tscn` → екрани через `ScreenRouter` (autoload)
- Збірка: `npm run godot:android:release` → `build/godot/android/lost-number.aab`
- Документація: **`godot/README.md`**, `godot/docs/ANDROID_RELEASE_READINESS.md`, `godot/docs/VISUAL_PORT_MAP.md`

## CI

| Workflow                      | Призначення                                                   |
| ----------------------------- | ------------------------------------------------------------- |
| `.github/workflows/ci.yml`    | `npm run release:check` на push/PR (**без** `godot:test:all`) |
| `.github/workflows/pages.yml` | Деплой `_site/` на GitHub Pages (якщо Pages увімкнено)        |
