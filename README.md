# LostNumber

Panta mēn ta gignōskomena arithmon echontikai panta ga man

**Primary ship target:** Godot 4.5 Android AAB → Google Play (`2.1.6` / versionCode `16`, package `com.averixor.lostnumber`).  
**Web / Capacitor** (`js/`, `index.html`, `android/`) — візуальний еталон і legacy-шлях, **не** основний upload у Play.

Канонічні рішення: **[docs/en/SOURCE_OF_TRUTH.md](docs/en/SOURCE_OF_TRUTH.md)**. English docs: **[docs/en/README.md](docs/en/README.md)**.

## Godot (primary — Android / Play)

Нативна збірка Godot 4.5 — **основний** шлях релізу.

```bash
npm install
npm run godot:import              # перший раз після clone
npm run godot:test:all            # rules + save + smoke + i18n (285 ключів)
npm run godot:android:release     # → build/godot/android/lost-number.aab
```

- Точка входу: **`Boot.tscn` → `App.tscn` → `ScreenRouter`** (autoload)
- Збереження: `user://` envelope v1 + SHA-256 + `.bak`; legacy import — `LegacySaveMigration`
- Рівні: **40 algorithmically generated** initial configs + procedural branch from index 40+ (`LevelManager.gd`)
- Детально: **[godot/README.md](godot/README.md)**, **[HANDOFF-IDEAL.md](HANDOFF-IDEAL.md)**, `godot/docs/ANDROID_RELEASE_READINESS.md`

## Швидкий старт (web — reference / legacy)

Збірка не потрібна — звичайні HTML/CSS/JS без модулів і без бандлера (`<script>` без `type="module"`). Використовуй для візуального паритету та legacy Capacitor, не як primary Play path.

1. Клонуй репозиторій.
2. Відкрий `index.html` у браузері або підніми локальний статичний сервер.

```bash
npx serve .
```

Інтерфейс локалізовано українською, російською та англійською. Типовий розмір сітки — 5×8; ціль на рівні зростає разом із прогресом.

## Брендинг та графіка

**Фони головного меню** (чистий арт без UI; HTML/CSS — окремий шар):

- `assets/images/dark/menu-bg-1.png` … `menu-bg-6.png` — тёмна тема (dusk)
- `assets/images/light/bg-light-01.png` … `bg-light-06.png` — світла тема (dawn)

Логіка: `js/system/platform/background.js` (`BackgroundRotator`). Окремий вибір фону для dawn/dusk у `localStorage` (`lostNumberBackground`, гілки `dawn` / `dusk`, `selectedLightBackground` / `selectedDarkBackground`). При зміні теми в налаштуваннях фон перемикається автоматично.

**Neon-іконки UI** (замість emoji в меню, HUD, досягненнях):

- `js/ui/icons.js` — `LostNumberIcons` (`data-ln-icon`, `applyAll`)
- `css/lostnumber-icons.css` — розміри та стилі слотів
- `assets/icons/neon/icons/*.svg` — набір SVG-іконок

**PWA / launcher іконки:**

- `assets/icons/icon.png` — 512×512 (PWA, favicon, браузер)
- `assets/icons/icon-1024.png` — 1024×1024 (Android adaptive icon, PWA maskable)

Android mipmap: `python3 scripts/generate-android-icons.py` (джерело — `icon-1024.png`).

Назва застосунку на пристрої: **Lost Number** (`capacitor.config.json`, `android/.../strings.xml`).

Колір оболонки PWA / `theme-color`: **`#1b1028`**.

## PWA та публічний демо

Живий демо / privacy на GitHub Pages: <https://averixor.github.io/LostNumber/> — **працює лише після public repo + увімкнення Pages** (зараз private → 404). Обхід: `npm run privacy:package` → Netlify Drop — див. [docs/GITHUB_PAGES.md](docs/GITHUB_PAGES.md).

Деплой: **`ci.yml`** — `release:check` на кожному push (**Godot-тести `godot:test:all` — лише локально**, CI їх не запускає); **`pages.yml`** — деплой `_site/` лише коли Pages увімкнено (на private repo без Pages run завершується без деплою — див. [docs/GITHUB_PAGES.md](docs/GITHUB_PAGES.md)).

## Android — Capacitor (legacy WebView)

**Secondary path.** Для Play завантажуй Godot AAB (`npm run godot:android:release`). Capacitor 7 — той самий web-код у WebView-обгортці; залишено для legacy save testing і візуального diff.

```bash
npm install
npm run android:prepare   # зібрати web + sync у android/
npm run android:open      # Android Studio
```

Детально: **[docs/ANDROID.md](docs/ANDROID.md)**. Play Console: **[docs/PLAY_STORE.md](docs/PLAY_STORE.md)**. Навігатор: **[docs/README.md](docs/README.md)**.

Без магазину можна встановити PWA з GitHub Pages («Додати на головний екран»).

## Звук і збереження

- **Аудіо:** `public/audio/` → `_site/audio/`; менеджер — `js/system/platform/audio.js`. Детально: **[docs/AUDIO.md](docs/AUDIO.md)**.
- **Збереження партії:** `localStorage` ключ `lostNumberSave`; «Продовжити» активна при наявності збереження; автозбереження при виході з ігрового екрана та згортанні застосунку.
- **Меню:** кнопки з єдиним шаблоном [іконка 32px | текст]; Android «Назад» — гра → меню → вихід (`js/app/navigation/back-navigation.js`).

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
| `npm run test`                | Те саме, що `test:smoke` — швидкі gameplay/storage smoke-тести                                                                                       |
| `npm run test:smoke`          | Gameplay/storage/error-handler smoke-перевірки без test framework                                                                                    |
| `npm run release:check`       | Повний предрелізний gate: format, lint, typecheck, static verifier і smoke-тести                                                                     |
| `npm run verify:android`      | Release security + перевірка `_site` перед Android bundle                                                                                            |
| `npm run build:pages`         | Готує `_site/` для GitHub Pages / Capacitor: `index.html`, `manifest.json`, `privacy.html`, `assets/`, `css/`, `js/`                                 |
| `npm run android:prepare`     | `build:pages` + синхронізація web-асетів у `android/` (Capacitor)                                                                                    |
| `npm run android:sync`        | Те саме, що `android:prepare`                                                                                                                        |
| `npm run android:release`     | Підписаний release APK                                                                                                                               |
| `npm run android:bundle`      | Підписаний release AAB для Google Play                                                                                                               |
| `npm run store:prepare`       | Графіка Play Console у `store/` + оновлення mipmap                                                                                                   |
| `npm run android:open`        | Відкрити Gradle-проєкт у Android Studio                                                                                                              |
| `npm run android:run`         | prepare + `cap run android` (потрібен SDK + пристрій/емулятор)                                                                                       |
| `npm run cursor:audit`        | Допоміжний скрипт для локального аудиту з Cursor SDK                                                                                                 |
| `npm run cursor:audit:stream` | Те саме з потоковим виводом (`cursor-audit-local.mjs --stream`)                                                                                      |

**Godot (primary Android ship target):**

| Команда                         | Опис                                                                    |
| ------------------------------- | ----------------------------------------------------------------------- |
| `npm run godot:import`          | Headless import Godot-проєкту (`godot4 --path godot --import`)          |
| `npm run godot:test:all`        | Rules + save + smoke + i18n тести (285 ключів uk/ru/en)                 |
| `npm run godot:android:debug`   | Debug APK → `build/godot/android/lost-number-debug.apk`                 |
| `npm run godot:android:release` | Release AAB → `build/godot/android/lost-number.aab` (потрібен keystore) |
| `npm run godot:verify:aab`      | Pre-upload gate: тести + release:check + перевірка AAB                  |

Детально: **[godot/README.md](godot/README.md)**, `godot/docs/ANDROID_RELEASE_READINESS.md`.

Додаткові Node-перевірки gameplay/reliability (без test framework, лише stdlib):

```bash
node ./scripts/test-min-tile.mjs
node ./scripts/test-level-config.mjs
node ./scripts/test-storage-fallback.mjs
node ./scripts/test-error-handler-fallback.mjs
node ./scripts/test-grid-dom-sync.mjs
node ./scripts/test-android-assets.mjs   # build:pages + cap sync + перевірка assets
```

У Windows за бажанням можна користуватися **`format.ps1`** / **`lint.ps1`** поруч з npm-командами, або напряму **`node ./scripts/check.mjs`** (те саме, що `npm run check`, без залежності від cmd/npx у PATH).

## Endless progression

Ранні рівні (**1–40**) — конфігурації, **алгоритмічно згенеровані при ініціалізації** (`_generate_manual_levels(40)`, `LevelManager.MANUAL_LEVEL_COUNT := 40`). З індексу 40 — окрема процедурна гілка через `get_level_config(levelIndex)` (детерміновано). У збереженні — `current_level`; ціль відновлюється після reload. Безпека високих рівнів (50+) — див. [AUDIT_MAIN_2026-07-10.md](docs/en/AUDIT_MAIN_2026-07-10.md).

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

Короткий огляд тека — у **[PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)**. Зокрема:

- **`index.html`** — точка входу, послідовне підключення скриптів.
- **`css/`** — змінні, сітка, UI, оверлеї, критичні екрани, режим низької продуктивності.
- **`js/core/`** — правила, `GameCore`, ланцюг, RNG.
- **`js/game/`** — стан, бонуси, колесо, досягнення, щоденні завдання, екран статистики.
- **`js/game/grid/`** — фізика (гравітація), рендер, анімації, замороження.
- **`js/system/`** — платформа, сховище, звук, i18n, обробка помилок.
- **`js/ui/`** — екрани, меню, оверлеї, дебаг-панель.
- **`js/app/`** — `LostNumberGame` та логіка флоу, збережень, UI-подій.
- **`js/bootstrap/`** — `env.js`, `boot.js`, `capacitor-bridge.js` (запуск, native).
- **`js/app/navigation/`** — Android «Назад», навігація між екранами.

Додаткові нотатки: **[docs/README.md](docs/README.md)** (навігатор), **`docs/PHASES.md`**, **`docs/AUDIO.md`**, **`docs/ANDROID.md`**.

## Ліцензія та внесок

Якщо ліцензія не зазначена в репозиторії окремо — уточни у власника проєкту перед комерційним використанням або форком.

Pull requests та issues вітаються після узгодження з правилами репозиторію (якщо вони з’являться).
