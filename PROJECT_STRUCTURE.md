# Lost Number — структура проєкту

Збірка web-артефакту: **`npm run build:pages`** → `_site/`. Для розробки UI — `index.html` або `npx serve .` (аудіо з `public/audio/` або після `build:pages`).

## Корінь репозиторію

| Шлях                                 | Призначення                                                    |
| ------------------------------------ | -------------------------------------------------------------- |
| `index.html`                         | Точка входу, послідовні `<script>` без `type="module"`         |
| `privacy.html`                       | Privacy Policy (UK + EN); копіюється в `_site/` для Play Store |
| `manifest.json`                      | PWA (`name`: Lost Number)                                      |
| `capacitor.config.json`              | Capacitor 7, `appName`: Lost Number, `webDir`: `_site`         |
| `assets/images/dark/menu-bg-*.png`   | 6 арт-фонів для dusk (тёмна тема)                              |
| `assets/images/light/bg-light-*.png` | 6 арт-фонів для dawn (світла тема)                             |
| `assets/icons/neon/icons/*.svg`      | Neon SVG для UI (`LostNumberIcons`)                            |
| `css/lostnumber-icons.css`           | Стилі neon-іконок                                              |
| `js/ui/icons.js`                     | `LostNumberIcons` — mount / `applyAll`                         |
| `assets/icons/icon.png`              | Іконка 512×512 (PWA, favicon)                                  |
| `assets/icons/icon-1024.png`         | Мастер-іконка 1024×1024 (Android, maskable PWA)                |
| `public/audio/`                      | Музика та SFX → `_site/audio/`                                 |
| `css/`                               | Стилі                                                          |
| `js/`                                | Логіка гри                                                     |
| `android/`                           | Gradle-проєкт Android                                          |
| `scripts/`                           | Збірка, перевірки, генерація іконок                            |
| `store/`                             | Графіка та тексти Google Play (`PLAY_CONSOLE_LISTING.md`)      |
| `docs/`                              | Документація — індекс у **`docs/README.md`**                   |

## Фони (чергування)

| Компонент                             | Файл                               | Хто викликає                                                        |
| ------------------------------------- | ---------------------------------- | ------------------------------------------------------------------- |
| `BackgroundRotator.init()`            | `js/system/platform/background.js` | inline-скрипт у `index.html` після `#appBackground`                 |
| `BackgroundRotator.onMainMenuEnter()` | там же                             | `ScreenManager.showScreen('mainMenu')` у `js/ui/screens/screens.js` |

Логіка: при кожному відкритті головного меню, якщо змінився календарний день — індекс скіна циклічно `0 → … → 5 → 0` (окремо для **dawn** і **dusk**). Стан у `localStorage` ключ **`lostNumberBackground`** — гілки `dawn` / `dusk`, ручний вибір фону (`selectedLightBackground` / `selectedDarkBackground`).

CSS: `css/background.css` — `--app-bg-image` на `#appBackground`.

## `public/audio/`

```
public/audio/
├── music/     ambient.mp3, Crystal Flow.mp3, Digital Horizon.mp3, Neon Drift.mp3, Stellar Logic.mp3
└── sfx/       connect, chain-complete, button, bonus, xp, error, quest-complete, victory (8 файлів)
```

Детально: **`docs/AUDIO.md`**.

## `css/`

| Файл                   | Призначення                                                     |
| ---------------------- | --------------------------------------------------------------- |
| `variables.css`        | Токени теми, PWA-кольори                                        |
| `background.css`       | `#appBackground`, CSS-змінна фону                               |
| `base.css`             | Базова типографіка, `.screen`                                   |
| `ui.css`               | Меню (центроване), кнопки [іконка 32px \| текст]                |
| `grid.css`             | Поле 5×8 (квадратні клітини, `aspect-ratio`), підсвітка ланцюга |
| `overlays.css`         | Перемога, рівень, колесо, confirm                               |
| `critical.css`         | Splash, критична помилка                                        |
| `low-performance.css`  | Lite-режим (`html.low-performance`)                             |
| `lostnumber-icons.css` | Neon SVG іконки (`ln-icon`, слоти HUD/меню)                     |

## Neon icons

| Компонент         | Файл                       | Хто викликає                                     |
| ----------------- | -------------------------- | ------------------------------------------------ |
| `LostNumberIcons` | `js/ui/icons.js`           | `index.html`; `i18n-theme.js`, `daily.js`, wheel |
| SVG assets        | `assets/icons/neon/icons/` | `LostNumberIcons.resolveUrl`                     |
| Стилі             | `css/lostnumber-icons.css` | `index.html`                                     |

Mount: елемент з `data-ln-icon="slug"`. Після `innerHTML` — `LostNumberIcons.applyAll(container)`.

## `js/bootstrap/`

| Файл                  | Призначення                                                                  |
| --------------------- | ---------------------------------------------------------------------------- |
| `index.html` (inline) | `LN_BUILD_FLAGS`, `LN_isDevToolsAllowed()`, умовне завантаження dev-скриптів |
| `env.js`              | `AppEnv`, режими дебагу                                                      |
| `boot.js`             | `new LostNumberGame()`, `setupNativeBackButton()`                            |
| `capacitor-bridge.js` | Status bar, `LN_NATIVE_APP`, автозбереження при згортанні                    |

## `js/system/platform/`

| Файл              | Призначення         | Основні виклики                                                                                                                                 |
| ----------------- | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `storage.js`      | `StorageManager`    | `LostNumberGame` constructor; `save-load.js`, `settings.js`, `daily.js`                                                                         |
| `audio.js`        | `AudioManager`      | `applySettings` ← `LostNumberGame`, `settings.js`; SFX ← `ui-events`, `game-flow`, `bonuses`, `daily.js`; `setSoundEnabled` ← футер `ui-events` |
| `background.js`   | `BackgroundRotator` | `index.html`, `screens.js`                                                                                                                      |
| `platform.js`     | `PlatformDetector`  | `index.html` (lite bootstrap), `settings.js`                                                                                                    |
| `freezeSystem.js` | заморозка клітин    | `grid-freeze.js`, `save-load.js`, `game-flow.js`                                                                                                |
| `lazy-script.js`  | `LN_loadScriptOnce` | `LostNumberGame._scheduleLazySideModules`, `misc.js`                                                                                            |

## `js/core/`

`rules.js`, `GameCore.js`, `Chain.js`, `SeededRandom.js`, `ErrorBoundary.js`

- `GameCore.validateMove` / `canFinishChain` ← `ui-events.js`, `game-flow.js`
- `updateChainSum()` ← `ui-events.js` (ланцюг)

## `js/game/`

| Модуль                   | Викликається з                                                |
| ------------------------ | ------------------------------------------------------------- |
| `state.js` (`GameState`) | `LostNumberGame` constructor; рівні, XP, `generateCellNumber` |
| `mechanics/bonuses.js`   | UI бонусів, `game-flow`                                       |
| `mechanics/wheel.js`     | оверлей колеса, меню                                          |
| `meta/daily.js`          | меню, `game-flow` (квести)                                    |
| `meta/achievements.js`   | меню, `game-flow`                                             |
| `meta/stats.js`          | **lazy** — `misc.js`, `_scheduleLazySideModules`              |
| `grid/*`                 | див. нижче                                                    |

### `js/game/grid/`

| Файл                 | Ключові методи                                             | Хто викликає                                                         |
| -------------------- | ---------------------------------------------------------- | -------------------------------------------------------------------- |
| `grid-init.js`       | `initGame`, `performFullRender`                            | `game-flow`, `save-load`, `bonuses`                                  |
| `grid-render.js`     | `render`, `syncGridDOMFromModel`, `preferSyncOrFullRender` | `ui-events`, `game-flow`, `grid-physics`, `grid-safety`, `save-load` |
| `grid-physics.js`    | `applyLocalGravity`, `shuffleGrid`                         | `game-flow`, `bonuses`                                               |
| `grid-animations.js` | `runPostMergeEffects`, `animateGravity`                    | `game-flow`, `bonuses`                                               |
| `grid-freeze.js`     | `updateFrozenCells`, `initFreezeSystem`                    | `game-flow`, `grid-render`                                           |
| `grid-safety.js`     | `validateGrid`, `repairGrid`                               | `save-load.js`                                                       |

## `js/ui/`

| Файл                       | Викликається з                                   |
| -------------------------- | ------------------------------------------------ |
| `screens/screens.js`       | `LostNumberGame.showScreen` (bind у constructor) |
| `screens/menu.js`          | `setupUI` → кнопки меню, confirm «Нова гра»      |
| `overlays/settings.js`     | меню → налаштування                              |
| `overlays/overlays.js`     | HUD суми, перемога, рівень, колесо               |
| `overlays/DebugOverlay.js` | **lazy**, лише `AppEnv.isDev`                    |

## `js/app/`

| Файл                            | Призначення                                     | Вхідні точки                                                |
| ------------------------------- | ----------------------------------------------- | ----------------------------------------------------------- |
| `core/LostNumberGame.js`        | головний клас                                   | `boot.js`                                                   |
| `flow/game-flow.js`             | `startNewGame`, `mergeChain`, `checkWin`, рівні | `menu.js`, `ui-events.js`, `overlays.js`                    |
| `persistence/save-load.js`      | збереження, «Продовжити», grid v2               | `screens.js` (вихід з гри), `game-flow`, `capacitor-bridge` |
| `navigation/back-navigation.js` | Android «Назад»                                 | `boot.js` → `Capacitor.App.backButton`                      |
| `ui/ui-events.js`               | поле, ланцюг, футер                             | `setupUI`                                                   |
| `ui/ui-refresh.js`              | XP, ціль, HUD                                   | `game-flow`, `bonuses`, `wheel`                             |
| `ui/i18n-theme.js`              | мова, тема                                      | constructor, `settings.js`                                  |
| `runtime/error-runtime.js`      | `ErrorHandler`, wrap критичних методів          | constructor                                                 |
| `runtime/misc.js`               | екрани stats/achievements                       | `menu.js`                                                   |
| `random/random.js`              | `nextRandomInt`                                 | `grid-physics`, `state`                                     |
| `inventory/inventory.js`        | бонусний інвентар                               | `game-flow`, `bonuses`                                      |

## Dev (gated)

| Файл                                             | Завантаження                                                      |
| ------------------------------------------------ | ----------------------------------------------------------------- |
| `system/dev/cheats.js`                           | `index.html` `loadDevToolScripts()` якщо `LN_isDevToolsAllowed()` |
| `system/dev/dev-entry.js`                        | статично в `index.html` (5 кліків About)                          |
| `system/dev/debug.js`                            | `index.html` defer                                                |
| `app/dev/dev-tools.js`, `performance-monitor.js` | умовно з `index.html`                                             |

## `scripts/`

| Скрипт                                       | Призначення                                           |
| -------------------------------------------- | ----------------------------------------------------- |
| `build-pages.mjs`                            | `_site/`                                              |
| `prepare-android.mjs`                        | `build:pages` + `cap sync android`                    |
| `generate-android-icons.py`                  | `icon-1024.png` → `mipmap-*`                          |
| `release-check.mjs`                          | format, lint, typecheck, verify, smoke                |
| `verify-static-assets.mjs`                   | посилання, розміри іконок, PWA-кольори                |
| `test-min-tile.mjs`, `test-level-config.mjs` | рівні, min spawn                                      |
| `test-storage-fallback.mjs`                  | `StorageManager` fallback                             |
| `test-error-handler-fallback.mjs`            | `ErrorHandler` fallback                               |
| `test-grid-dom-sync.mjs`                     | DOM ↔ модель сітки, gravity, save                    |
| `test-android-assets.mjs`                    | `_site` + Android public assets (окремий запуск)      |
| `smoke-tests.mjs`                            | `npm run test` — усі `test-*.mjs` крім android-assets |
| `install-android-studio.sh`                  | Linux: Studio + JDK                                   |

## localStorage

| Ключ                   | Вміст                                                                                                         |
| ---------------------- | ------------------------------------------------------------------------------------------------------------- |
| `lostNumberSave`       | Активна партія (grid v2, рівень, XP…)                                                                         |
| `lostNumberSettings`   | `soundEnabled`, `musicEnabled`, гучності, `musicTrack`, `theme`, `lang`, `animationEnabled`, `liteVisualMode` |
| `lostNumberBackground` | Чергування фонів меню (гілки `dawn` / `dusk`, індекс 0–5)                                                     |
| `dailyQuests`          | Щоденні завдання                                                                                              |
| `lostNumberFirstRun`   | Прапорець першого запуску                                                                                     |

## Потік ходу (коротко)

```
pointerdown/up (ui-events) → validateMove (GameCore) → mergeChain (game-flow)
  → runPostMergeEffects (grid-animations) → applyLocalGravity (grid-physics)
  → preferSyncOrFullRender (grid-render) → saveGameState → checkWin
bonuses destroy/explosion → runPostMergeEffects (той самий pipeline)
```

## `docs/`

Повний навігатор: **`docs/README.md`**.

- **`ANDROID.md`** — Capacitor, APK/AAB, іконки, «Назад»
- **`ANDROID_QA.md`** — manual QA перед установкою на телефон
- **`PLAY_STORE.md`** — Google Play Console, IARC, Data safety, closed testing
- **`GITHUB_PAGES.md`** — деплой `_site/` і privacy URL
- **`AUDIO.md`** — музика, SFX, `applySettings`
- **`DEBUG_CHEATS.md`** — debug APK з читами
- **`PHASES.md`** — етапи розвитку, performance, lite
- **`store-listing/`** — короткі/повні описи (uk, en, ru)
