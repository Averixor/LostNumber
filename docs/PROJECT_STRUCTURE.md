# Lost Number — структура проєкту

**Єдина playable-реалізація:** Godot 4.7 Android (`godot/`, `npm run godot:android:release`). Канон: `docs/en/SOURCE_OF_TRUTH.md`.

**Endless progression:** рівні 1–40 — preset-таблиця (`LevelManager.MANUAL_LEVEL_COUNT := 40`); далі — процедурні цілі через `getLevelConfig(levelIndex)`.

## Корінь репозиторію

| Шлях                | Призначення                                               |
| ------------------- | --------------------------------------------------------- |
| `godot/`            | Гра: сцени, GDScript, assets, Android export              |
| `privacy.html`      | Privacy Policy (UK + EN) для Google Play — не гра         |
| `android/keystore/` | Release keystore (gitignored)                             |
| `store/`            | Графіка та тексти Google Play (`PLAY_CONSOLE_LISTING.md`) |
| `scripts/`          | npm-скрипти: export, verify, store:prepare                |
| `docs/`             | Документація — індекс у **`docs/README.md`**              |

## `godot/`

| Шлях                                                                        | Призначення                                                                                                                                                                        |
| --------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `project.godot`                                                             | `main_scene` → `scenes/Boot.tscn`; autoloads: SaveManager, SettingsManager, AudioManager, I18nManager, ThemeManager, LeaderboardService, **ScreenRouter**, **LegacySaveMigration** |
| `scenes/Boot.tscn`                                                          | Splash: preload App, fade                                                                                                                                                          |
| `scenes/App.tscn`                                                           | Shell: BackgroundLayer, ScreenRoot, OverlayRoot (Toast/Modal/Transition), AudioRoot                                                                                                |
| `scenes/MainMenu.tscn`, `Game.tscn`, `Settings.tscn`, `SkinPreview.tscn`, … | Екрани; монтуються в ScreenRoot через ScreenRouter                                                                                                                                 |
| `scripts/ui/ScreenRouter.gd`                                                | Autoload: push/replace/go_back, back-stack, fade                                                                                                                                   |
| `scripts/core/LevelManager.gd`                                              | 40 preset levels + procedural endless                                                                                                                                              |
| `assets/ui/backgrounds/{dark,light}/`                                       | 6+6 фонів меню                                                                                                                                                                     |
| `assets/ui/icons/`                                                          | Gothic PNG pack (`icons/gothic/`), wheel PNGs, shared `tile-crown.png`                                                                                                             |
| `assets/audio/{music,sfx}/`                                                 | mp3 (git LFS)                                                                                                                                                                      |
| `assets/i18n/{uk,ru,en}.json`                                               | 285 ключів кожна локаль                                                                                                                                                            |
| `export_presets.cfg`                                                        | Android AAB/APK, version 2.1.6 / code 16                                                                                                                                           |

Потік запуску: **Boot → App → MainMenu** (`ScreenRouter.replace("main_menu")`). Збірка: `npm run godot:android:release` → `build/android/lost-number.aab`.

## `scripts/`

| Скрипт                         | Призначення                                |
| ------------------------------ | ------------------------------------------ |
| `godot-android-export.sh`      | Debug APK / release AAB                    |
| `verify-godot-release.mjs`     | export_presets, secrets, SDK checks        |
| `release-check.mjs`            | format, lint, tagline, Godot config, smoke |
| `smoke-tests.mjs`              | `npm run test` — layout Godot-проєкту      |
| `generate-android-icons.py`    | `godot/icon.png` з master 1024             |
| `prepare-play-store-assets.py` | `store/` graphics з Godot backgrounds      |
| `package-privacy-host.mjs`     | `privacy-host/` для хостингу privacy.html  |
| `pack-unified.sh`              | zip handoff без секретів                   |

## `docs/`

Повний навігатор: **`docs/README.md`**.

- **`docs/ANDROID_RELEASE_READINESS.md`** — Godot Android, AAB, підпис
- **`ANDROID_QA.md`** — manual QA перед установкою на телефон
- **`PLAY_STORE.md`** — Google Play Console, IARC, Data safety
- **`docs/en/SOURCE_OF_TRUTH.md`** — канонічні рішення
- **`docs/en/VISUAL_TARGET.md`** — візуальний north star
- **`store-listing/`** — короткі/повні описи (uk, en, ru)

## Збереження (Godot)

| Шлях                               | Вміст                        |
| ---------------------------------- | ---------------------------- |
| `user://lost_number_save.json`     | Активна партія (envelope v1) |
| `user://lost_number_save.bak.json` | Авто-rollback backup         |

Legacy import зі старих Web/Capacitor save: `LegacySaveMigration` autoload + Android plugin AAR. Див. `docs/LEGACY_SAVE_MIGRATION.md`.
