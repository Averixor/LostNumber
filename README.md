# LostNumber

Браузерна головоломка з числами: будуй ланцюг суміжних клітинок на сітці, дотримуючись правил злиття, збирай XP, проходь рівні та користуйся бонусами, щоденними завданнями та колесом фортуни.

Інтерфейс локалізовано українською, російською та англійською. Типовий розмір сітки — 5×8; ціль на рівні зростає разом із прогресом.

## Швидкий старт

Збірка не потрібна — звичайні HTML/CSS/JS без модулів і без бандлера (`<script>` без `type="module"`).

1. Клонуй репозиторій.
2. Відкрий `index.html` у браузері або підніми локальний статичний сервер.

Для розробки зручно:

```bash
npx serve .
```

## Брендинг та графіка

Лише **два** растрові файли:

- `assets/images/background.jpg` — єдиний статичний фон для всіх екранів (завантаження, меню, гра, налаштування).
- `assets/icons/icon.png` — іконка застосунку (512×512; PWA, браузер, Android Studio Image Asset).

Колір оболонки PWA / `theme-color`: **`#1b1028`**.

## PWA та публічний демо

Живий приклад на GitHub Pages: <https://averixor.github.io/LostNumber/>

Деплой налаштований через GitHub Pages як статичний сайт без Jekyll. Workflow запускає `npm run release:check`, готує `_site/` командою `npm run build:pages` і публікує лише runtime-асети гри.

## Android (APK / Google Play)

Нативна збірка через **Capacitor 7** — той самий код, що в браузері, у WebView-обгортці.

```bash
npm install
npm run android:prepare   # зібрати web + sync у android/
npm run android:open      # Android Studio
```

Детально: **[docs/ANDROID.md](docs/ANDROID.md)** (JDK, SDK, debug/release APK, іконка, типові помилки).

Без магазину можна просто встановити PWA з GitHub Pages («Додати на головний екран»).

## Скрипти npm

Після `npm install`:

| Команда                       | Опис                                                                                                                                                 |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `npm run format`              | Prettier — запис усіх відповідних файлів                                                                                                             |
| `npm run format:check`        | Prettier — лише перевірка без змін                                                                                                                   |
| `npm run lint`                | ESLint                                                                                                                                               |
| `npm run lint:fix`            | ESLint з автовиправленням де можливо                                                                                                                 |
| `npm run check`               | **`format:check` + `lint`** через `scripts/check.mjs` (Node, без прив’язки до shell)                                                                 |
| `npm run verify:static`       | Перевіряє локальні посилання з `index.html`, `manifest.json`, CSS/JS string refs та синхронність PWA-кольорів                                        |
| `npm run typecheck`           | TypeScript **`tsc --noEmit`** — baseline перевірка типів без збірки й без emit (див. `tsconfig.json`, `js/types.d.ts`; `checkJs` глобально вимкнено) |
| `npm run test:smoke`          | Gameplay/storage/error-handler smoke-перевірки без test framework                                                                                    |
| `npm run release:check`       | Повний предрелізний gate: format, lint, typecheck, static verifier і smoke-тести                                                                     |
| `npm run build:pages`         | Готує `_site/` для GitHub Pages / Capacitor: `index.html`, `manifest.json`, `assets/`, `public/audio/` → `_site/audio/`, `css/`, `js/`               |
| `npm run android:prepare`     | `build:pages` + синхронізація web-асетів у `android/` (Capacitor)                                                                                    |
| `npm run android:open`        | Відкрити Gradle-проєкт у Android Studio                                                                                                              |
| `npm run android:run`         | prepare + `cap run android` (потрібен SDK + пристрій/емулятор)                                                                                       |
| `npm run cursor:audit`        | Допоміжний скрипт для локального аудиту з Cursor SDK                                                                                                 |
| `npm run cursor:audit:stream` | Те саме з потоковим виводом (`cursor-audit-local.mjs --stream`)                                                                                      |

Додаткові Node-перевірки gameplay/reliability (без test framework, лише stdlib):

```bash
node ./scripts/test-min-tile.mjs
node ./scripts/test-level-config.mjs
node ./scripts/test-storage-fallback.mjs
node ./scripts/test-error-handler-fallback.mjs
```

У Windows за бажанням можна користуватися **`format.ps1`** / **`lint.ps1`** поруч з npm-командами, або напряму **`node ./scripts/check.mjs`** (те саме, що `npm run check`, без залежності від cmd/npx у PATH).

## Endless progression

Ранні рівні (**1–40**) беруться з preset-таблиці без зміни балансу. Після останнього preset-рівня гра продовжує процедурно: ціль визначається через **`getLevelConfig(levelIndex)`** (0-based індекс) — детерміновано з номера рівня, без `Math.random()` і без прив’язки до платформи. У збереженні лишається **`currentLevel`**; ціль відновлюється після reload. Цілі — safe power-of-two для правил злиття; рівні 20, 50, 100, 200, 500+ працюють коректно після перезавантаження.

## Режими та дебаг

### Gated dev cheats tooling (`LN_CODES`)

Чит-панель і консольні команди — **не** частина звичайного production-релізу. Увімкнення **не** залежить лише від `?dev=1`, `?cheats=1` або `?debug=…` на публічному хості.

- **`window.LN_isDevToolsAllowed()`** — головний gate: `true` лише на **локальній** dev-середовищі (`localhost`, `127.0.0.1`, `::1`, `[::1]`, `file://`, `*.local`, private LAN `10.x` / `192.168.x` / `172.16–31.x`) **або** якщо збірка явно встановила **`window.LN_BUILD_FLAGS.cheatsEnabled === true`** (майбутній Android debug).
- API: **`window.LN_CODES`** (консольні «слова»), панель — **`window.LN_CODES.panel()`** або **Ctrl+Backquote** / **`Ctrl+`** після завантаження `js/system/dev/cheats.js`.
- На **GitHub Pages** ([демо](https://averixor.github.io/LostNumber/)) gated dev cheats tooling **вимкнено**; query-параметри самі по собі чити **не вмикають**.
- П’ять кліків по блоку «Ще» в About — лише коли gate дозволяє (`js/system/dev/dev-entry.js`).

Android debug (приклад у `index.html` перед іншими скриптами):

```html
<script>
  window.LN_BUILD_FLAGS = { cheatsEnabled: true };
</script>
```

### AppEnv / логи помилок

- **`?debug=1`** або **`?dev=1`** — дев-логи, панель **Ctrl+D** на десктопі (через `AppEnv`, окремо від читів).
- **`?debug=full`** — «повний» дебаг (більше контексту в помилках, розширена панель).
- **`?debug=0`** — примусово вимкнути дебаг навіть на `localhost`.
- У браузері:

```js
localStorage.setItem('lostnumber_debug', 'full');
```

Після цього перезавантаж сторінку. Альтернатива після завантаження: `LN_DEBUG.help()` у консолі.

Службові повідомлення в консолі з обробників помилок (`errorHandler.js` / `errorHandlerFallback.js`) у продакшні приглушені: вони з’являються лише коли **`AppEnv.isDev`** активний (див. `js/bootstrap/env.js`; конфіг `ErrorHandlerConfig.logToConsole` теж залежить від режиму дебагу).

На мобільних / у **легкому візуальному** режимі частина ефектів спрощується; підказка суми ланцюга може показуватися **кольором виділених клітинок** замість бульбашки.

## Структура репозиторію

Короткий огляд папок — у **[PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)**. Зокрема:

- **`index.html`** — точка входу, послідовне підключення скриптів.
- **`css/`** — змінні, сітка, UI, оверлеї, критичні екрани, режим низької продуктивності.
- **`js/core/`** — правила, `GameCore`, ланцюг, RNG.
- **`js/game/`** — стан, бонуси, колесо, досягнення, щоденні завдання, екран статистики.
- **`js/game/grid/`** — фізика (гравітація), рендер, анімації, заморозка.
- **`js/system/`** — платформа, сховище, звук, i18n, обробка помилок.
- **`js/ui/`** — екрани, меню, оверлеї, дебаг-панель.
- **`js/app/`** — `LostNumberGame` та логіка флоу, збережень, UI-подій.
- **`js/bootstrap/`** — `env.js` (режими середовища), `boot.js` (запуск).

Додаткові нотатки про етапи розвитку — у **`docs/PHASES.md`**.

## Ліцензія та внесок

Якщо ліцензія не зазначена в репозиторії окремо — уточни у власника проєкту перед комерційним використанням або форком.

Pull requests та issues вітаються після узгодження з правилами репозиторію (якщо вони з’являться).
