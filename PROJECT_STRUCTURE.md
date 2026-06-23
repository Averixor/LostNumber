# LostNumber — структура проєкту

Збірка web-артефакту: **`npm run build:pages`** → `_site/`. Для розробки UI можна відкрити **`index.html`** або `npx serve .` (аудіо — з `public/audio/` або після `build:pages`).

## Корінь репозиторію

| Шлях                           | Призначення                                            |
| ------------------------------ | ------------------------------------------------------ |
| `index.html`                   | Точка входу, послідовні `<script>` без `type="module"` |
| `manifest.json`                | PWA                                                    |
| `capacitor.config.json`        | Capacitor 7, `webDir: _site`                           |
| `assets/images/background.jpg` | Єдиний статичний фон                                   |
| `assets/icons/icon.png`        | Іконка 512×512                                         |
| `public/audio/`                | Музика та SFX (копіюється в `_site/audio/`)            |
| `css/`                         | Стилі                                                  |
| `js/`                          | Логіка гри                                             |
| `android/`                     | Gradle-проєкт Android (після `cap sync`)               |
| `scripts/`                     | Збірка, перевірки, `install-android-studio.sh`         |
| `docs/`                        | `ANDROID.md`, `AUDIO.md`, `PHASES.md`                  |

## `public/audio/`

```
public/audio/
├── music/          ambient.mp3, Crystal Flow.mp3, Digital Horizon.mp3, Neon Drift.mp3, Stellar Logic.mp3
└── sfx/            connect, chain-complete, button, bonus, xp, error, quest-complete, victory (8 файлів)
```

Детально: **`docs/AUDIO.md`**.

## `css/`

| Файл                  | Призначення                                     |
| --------------------- | ----------------------------------------------- |
| `variables.css`       | Токени теми                                     |
| `background.css`      | Статичний фон `#appBackground`                  |
| `base.css`            | Базова типографіка                              |
| `ui.css`              | Меню, кнопки (іконка + текст), HUD суми ланцюга |
| `grid.css`            | Поле, клітини, підсвітка ланцюга                |
| `overlays.css`        | Перемога, рівень, колесо                        |
| `critical.css`        | Splash, критична помилка                        |
| `low-performance.css` | Lite-режим                                      |

## `js/bootstrap/`

| Файл                  | Призначення                                                                  |
| --------------------- | ---------------------------------------------------------------------------- |
| `index.html` (inline) | `LN_BUILD_FLAGS`, `LN_isDevToolsAllowed()`, умовне завантаження dev-скриптів |
| `env.js`              | `AppEnv`, режими дебагу                                                      |
| `boot.js`             | `new LostNumberGame()`, `setupNativeBackButton()`                            |
| `capacitor-bridge.js` | Status bar, `LN_NATIVE_APP`, автозбереження при згортанні                    |

## `js/core/`

`rules.js`, `GameCore.js`, `Chain.js`, `SeededRandom.js`, `ErrorBoundary.js`

## `js/system/`

| Файл                                               | Призначення                                          |
| -------------------------------------------------- | ---------------------------------------------------- |
| `platform/storage.js`                              | `lostNumberSave`, `lostNumberSettings`, daily quests |
| `platform/audio.js`                                | **AudioManager** — музика + SFX                      |
| `platform/freezeSystem.js`, `lazy-script.js`       | Заморозка, lazy load                                 |
| `i18n/i18n.js`                                     | UA / RU / EN                                         |
| `error/errorHandler.js`, `errorHandlerFallback.js` | Помилки                                              |
| `dev/cheats.js`, `dev-entry.js`                    | Gated dev cheats                                     |

## `js/game/`

`state.js`, `mechanics/bonuses.js`, `mechanics/wheel.js`, `meta/daily.js`, `meta/achievements.js`, `meta/stats.js`, `grid/*`

## `js/ui/`

`screens/screens.js`, `screens/menu.js`, `overlays/settings.js`, `overlays/overlays.js`, `overlays/DebugOverlay.js`

## `js/app/`

| Файл                                   | Призначення                                      |
| -------------------------------------- | ------------------------------------------------ |
| `core/LostNumberGame.js`               | Головний клас                                    |
| `flow/game-flow.js`                    | Ходи, злиття, рівні                              |
| `persistence/save-load.js`             | Збереження, «Продовжити», `updateContinueButton` |
| `navigation/back-navigation.js`        | Android «Назад», логіка екранів                  |
| `ui/ui-events.js`                      | Поле, цепочка, футер                             |
| `ui/i18n-theme.js`, `ui/ui-refresh.js` | Мова, тема, HUD                                  |

## `scripts/`

| Скрипт                          | Призначення                                                     |
| ------------------------------- | --------------------------------------------------------------- |
| `build-pages.mjs`               | `_site/` = index + assets + css + js + **public/audio → audio** |
| `prepare-android.mjs`           | `build:pages` + `cap sync android`                              |
| `release-check.mjs`             | format, lint, typecheck, verify, smoke                          |
| `verify-static-assets.mjs`      | Посилання на `audio/`, `assets/`, PWA-кольори                   |
| `install-android-studio.sh`     | Установка Studio / JDK (Linux)                                  |
| `test-*.mjs`, `smoke-tests.mjs` | Node smoke без test framework                                   |

## Збереження (localStorage)

| Ключ                 | Вміст                                                                                                                           |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `lostNumberSave`     | Стан активної партії (сітка, рівень, XP, бонуси…)                                                                               |
| `lostNumberSettings` | `soundEnabled`, `musicEnabled`, `sfxVolume`, `musicVolume`, `musicTrack`, `theme`, `lang`, `animationEnabled`, `liteVisualMode` |
| `dailyQuests`        | Щоденні завдання                                                                                                                |

## `docs/`

- **`AUDIO.md`** — музика, SFX, налаштування
- **`ANDROID.md`** — Capacitor, APK, Studio
- **`PHASES.md`** — етапи розвитку
