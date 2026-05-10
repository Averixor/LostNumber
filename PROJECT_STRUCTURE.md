# LostNumber — структура проєкту

Збірка не потрібна: відкривай **`index.html`** або обслуговуй корінь репозиторію як статичний сайт.

## Корінь репозиторію

- **`index.html`** — точка входу, послідовне підключення `<script>` без `type="module"`.
- **`manifest.json`** — PWA (іконки, `start_url`, знімок екрана тощо).
- **Ассети UI / PWA:** `favicon.ico`, `icon-192.png`, `icon-512.png`, `apple-touch-icon.png`, `logo.png`, заставка **`splash-screen.webp`** + **`splash-screen.png`** (fallback).
- **Node-інструменти:** `package.json`, `eslint.config.mjs`, `scripts/` (див. `README.md`).
- **Перевірка орфографії в IDE:** `cspell.json` (мови en, uk, ru; спільний словник), **`.vscode/extensions.json`** — рекомендовані розширення Code Spell Checker.
- **Документація:** `README.md`, цей файл, **`docs/PHASES.md`**.
- **Допоміжно:** `format.ps1`, `lint.ps1` (Windows, обхід обмежень на cmd/npx).

## `css/`

Стилі за зонами відповідальності:

| Файл                  | Призначення                                     |
| --------------------- | ----------------------------------------------- |
| `variables.css`       | Токени теми й кольорів                          |
| `base.css`            | Базова типографіка та глобальні правила         |
| `ui.css`              | Кнопки, панелі, налаштування                    |
| `grid.css`            | Ігрове поле та клітини                          |
| `overlays.css`        | Перемога, рівень, колесо тощо                   |
| `critical.css`        | Екран завантаження (splash) та критична помилка |
| `low-performance.css` | Спрощення для слабких пристроїв                 |

## `js/bootstrap/`

- **`env.js`** — `AppEnv`, режими дебагу (`?debug=`, `localStorage`).
- **`boot.js`** — ініціалізація після завантаження сторінки.

## `js/core/`

Правила й низькорівнева логіка без прив’язки до DOM:

- **`rules.js`**, **`GameCore.js`**, **`Chain.js`** — правила гри, ядро, ланцюг клітинок.
- **`SeededRandom.js`**, **`NumberWeights.js`** — генерація та ваги чисел.
- **`EventSystem.js`**, **`ErrorBoundary.js`** — події та межа помилок.

## `js/system/`

Платформа, периферія, глобальні сервіси:

- **`storage.js`**, **`audio.js`**, **`platform.js`**, **`i18n.js`**, **`plural-helpers.js`**
- **`errorHandler.js`**, **`errorHandlerFallback.js`**, **`debug.js`**
- **`analytics.js`**, **`lazy-script.js`**, **`freezeSystem.js`**

## `js/game/`

Ігровий стан і системи:

- **`state.js`**, **`bonuses.js`**, **`wheel.js`**, **`daily.js`**, **`achievements.js`**, **`stats.js`**

### `js/game/grid/`

Поле та його життєвий цикл:

- **`GridManager.js`**, **`grid-init.js`**, **`grid-physics.js`**, **`grid-render.js`**
- **`grid-animations.js`**, **`grid-freeze.js`**, **`grid-safety.js`**

## `js/ui/`

- **`screens.js`**, **`menu.js`**, **`settings.js`**, **`overlays.js`**
- **`DebugOverlay.js`** — дев-панель (наприклад **Ctrl+D** на десктопі)

## `js/app/`

Головний клас **`LostNumberGame.js`** і розбита по файлах логіка:

- флоу, збереження, UI-події: **`game-flow.js`**, **`save-load.js`**, **`ui-events.js`**, **`ui-refresh.js`**
- тема / мова в UI: **`i18n-theme.js`**
- **`dev-tools.js`**, **`error-runtime.js`**, **`performance-monitor.js`**, **`inventory.js`**, **`random.js`**, **`misc.js`**

## `scripts/`

- **`check.mjs`** — Prettier `--check` + ESLint (див. `npm run check`).
- **`cursor-audit-local.mjs`** — допоміжний скрипт під Cursor SDK: `npm run cursor:audit` або `npm run cursor:audit:stream` (режим `--stream`).

## `docs/`

- **`PHASES.md`** — етапи / нотатки розвитку.

## `.project/fonts/`

- Файли шрифтів у репозиторії (наприклад **`Charis-Regular.ttf`**); у поточних `css/` `@font-face` для них може бути відсутнім — перевір перед використанням.
