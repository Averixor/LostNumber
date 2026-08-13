# Lost Number — повний технічний аудит 360° (Google Play)

> **Dated audit (2026-08-04) — historical.** Current identity: `com.Averixor.Lost_Number` / VC **6** / Auth B2 — [`docs/en/SOURCE_OF_TRUTH.md`](en/SOURCE_OF_TRUTH.md), [`STAGE1_RELEASE_RECORD.md`](STAGE1_RELEASE_RECORD.md). Do not treat VC16 / old package lines below as live ship contract.

| Поле                 | Значення                                                                                                         |
| -------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Репозиторій          | https://github.com/Averixor/LostNumber                                                                           |
| Дата аудиту          | 2026-08-04 (наратив оновлено під roadmap v1.1)                                                                   |
| Первинний зріз       | `21a627b` (тодішній tip feature-гілки; **не** активна feature зараз)                                             |
| Інтеграція gothic UI | PR #48 → merge `1feda649` (2026-08-02) у `main`                                                                  |
| Перед релізом        | Повторно звірити з актуальним `main` HEAD; збирати AAB лише з зафіксованого SHA                                  |
| Версія в git (тоді)  | `2.1.6` / **versionCode 16** (legacy snapshot)                                                                   |
| Engine               | Godot **4.7.1** (`4.7.1.stable.flathub.a13da4feb` локально; CI pin `4.7.1.stable.official.a13da4feb`)            |
| Суміжні артефакти    | `docs/ROADMAP.md`, `docs/ANDROID_RELEASE_READINESS.md`, `docs/en/SOURCE_OF_TRUTH.md`, `docs/en/VISUAL_TARGET.md` |

> Аудит початково виконано на `21a627b`; зміни PR #48 інтегровані в `main` через `1feda649`. VC16 у цьому документі — **історичний** зріз, не поточний SoT.

---

## 1. Executive Summary & Project Overview

### 1.1 Що це за продукт

**Lost Number** — офлайн 2D-головоломка з об’єднанням чисел на сітці (chain / merge / XP / рівні), порт з веб/JS-стеку на **Godot 4.7** як єдиний production runtime. Мета дистрибуції — **Google Play** через **Android App Bundle (`.aab`)**, не APK як основний релізний артефакт.

Цільовий UX-фрейм:

| Параметр          | Значення                              | Джерело                                        |
| ----------------- | ------------------------------------- | ---------------------------------------------- |
| Viewport          | **420×920** (portrait)                | `godot/project.godot` `window/size/viewport_*` |
| Orientation       | portrait (`handheld/orientation=1`)   | `project.godot`                                |
| Stretch           | `canvas_items`                        | `project.godot`                                |
| Visual north star | gothic / stone-metal UI, не flat neon | `docs/en/VISUAL_TARGET.md`                     |

### 1.2 Стек

| Шар            | Технологія                                                        | Роль                                                                 |
| -------------- | ----------------------------------------------------------------- | -------------------------------------------------------------------- |
| Gameplay       | Godot 4.7 GDScript + Control UI                                   | Boot → App → ScreenRouter, гра, i18n, сейви                          |
| Tooling        | Node.js ≥20.19, npm scripts                                       | format/lint/typecheck, release gates, store verify, Cursor audit SDK |
| Android export | Godot Gradle build (`use_gradle_build=true`), JDK 17, Android SDK | AAB release / APK debug                                              |
| Signing        | локальний upload keystore (`android/keystore*.jks`, gitignored)   | підпис upload key для Play App Signing                               |
| CI             | GitHub Actions                                                    | `release:check` + **Godot tests 4.7.1** на push/PR `main`            |
| Privacy        | `privacy.html` → GitHub Pages                                     | URL для Play Console                                                 |

### 1.3 Ідентичність релізу (перевірено в `export_presets.cfg`)

| Поле               | Release (`preset.0`)                            | Debug (`preset.1`)                    |
| ------------------ | ----------------------------------------------- | ------------------------------------- |
| Package            | `com.averixor.lostnumber`                       | `com.averixor.lostnumber.dev`         |
| versionName        | `2.1.6`                                         | `2.1.6-dev`                           |
| versionCode        | **16**                                          | **16**                                |
| Format             | AAB (`export_format=1`)                         | APK                                   |
| minSdk / targetSdk | 24 / **35**                                     | 24 / 35                               |
| ABI                | **arm64-v8a**, **x86_64** (`armeabi-v7a=false`) | те саме                               |
| Output             | `build/android/lost-number.aab`                 | `build/android/lost-number-debug.apk` |
| Exclude            | `assets/store/*,scripts/tests/*`                | те саме                               |

Правило версіонування (документоване): для code ≥ 15 → `versionName = 2.1.(versionCode - 10)`. Документація каже, що **наступний upload має бути versionCode 17**, якщо 16 уже колись завантажували в Console.

### 1.4 Поточний статус (аудит-машина, 2026-08-04)

| Область                              | Статус              | Факт                                                                                  |
| ------------------------------------ | ------------------- | ------------------------------------------------------------------------------------- |
| Код / Godot ship                     | ✅ сильний          | Boot→App, 8 autoloads, headless тести, CI Godot suite                                 |
| Документація                         | ✅ висока щільність | SOURCE_OF_TRUTH, VISUAL_TARGET, ANDROID_RELEASE_READINESS, PLAY_STORE                 |
| npm / CI baseline                    | ✅                  | `release:check` + `godot:test:all` у CI                                               |
| Upload keystore                      | ✅ **локально є**   | `android/keystore/lostnumber-upload-2026.jks` + `keystore.properties` (gitignored)    |
| Signed AAB                           | ✅ **локально є**   | `build/android/lost-number.aab` (~142 MB, 2026-07-27)                                 |
| Debug APK                            | ✅                  | `build/android/lost-number-debug.apk` (~252 MB)                                       |
| Unified source ZIP                   | ✅                  | `dist/LostNumber-unified-20260719.zip` (pack з `git archive`)                         |
| Play Console upload / Closed testing | ❓ / ⚠️             | не підтверджено з git; identity verification блокує Production (`docs/PLAY_STORE.md`) |
| Активна гілка                        | ⚠️ feature          | `godot/fix-gothic-chrome-readability` (не обов’язково = `main`)                       |

**Вердикт executive:** інфраструктура та локальний Android release path **суттєво зріліші**, ніж у липневому handoff (тоді не було keystore/AAB). Блокер змістився з «немає підпису взагалі» на **операційний Play Console цикл**: узгодження versionCode з історією upload, Closed testing, IARC/Data safety, identity, якість in-app скріншотів, синхронізація docs із CI.

---

## 2. Architecture & Directory Structure Analysis

### 2.1 Карта репозиторію (фактична SoC)

```text
LostNumber/
├── godot/                 # Єдиний runtime продукту (сцени, GDScript, assets, android plugin)
├── android/               # ТІЛЬКИ secrets signing (keystore + properties) — не app module
├── build/android/         # Локальні артефакти AAB/APK (gitignore, README tracked)
├── store/                 # Play listing graphics + тексти-довідники
├── scripts/               # npm-оркестрація: export, verify, pack, smoke, store
├── docs/                  # SoT, architecture, Play, QA, phases
├── privacy.html           # Privacy policy source
├── .github/workflows/     # ci.yml + pages.yml
├── package.json           # Tooling monorepo entry (не Capacitor app)
└── dist/                  # Unified handoff ZIP (gitignore)
```

Оцінка **separation of concerns**:

| Концерн                             | Де живе                                              | Оцінка                                            |
| ----------------------------------- | ---------------------------------------------------- | ------------------------------------------------- |
| Ігрова логіка / UI                  | `godot/scripts`, `godot/scenes`                      | ✅ чисто відокремлено від npm                     |
| Автотести Godot                     | `godot/scripts/tests/*.gd` + `run-godot-isolated.sh` | ✅ headless, ізольований user-dir                 |
| Release/signing secrets             | `android/keystore*` (gitignored)                     | ✅ правильний периметр                            |
| Play marketing                      | `store/` + `docs/store-listing/`                     | ✅ не всередині gameplay PCK (exclude_filter)     |
| Repo quality gates                  | Node scripts + ESLint/Prettier/tsc                   | ✅ для tooling/docs, не для GDScript lint у CI    |
| Legacy Capacitor/Android Gradle app | відсутній як ship path                               | ✅ Godot Gradle export замість старого app module |

Важливо: каталог `android/` **не** є класичним Android Studio проєктом застосунку. Це **keystore vault** для `scripts/godot-android-export.sh`. Збірка Gradle генерується/використовується через Godot export templates і шляхи на кшталт `godot/android/build/` (частково в `.gitignore` з винятками для wrapper).

### 2.2 Godot runtime architecture

**Entry:** `main_scene = Boot.tscn` → preload → `App.tscn` (shell з `BackgroundLayer`, `ScreenRoot`, overlays) → навігація через autoload `ScreenRouter`.

**Autoloads** (`project.godot`):

| Autoload            | Файл                     | Відповідальність                     |
| ------------------- | ------------------------ | ------------------------------------ |
| SaveManager         | `SaveManager.gd`         | `user://` envelope, checksum, `.bak` |
| SettingsManager     | `SettingsManager.gd`     | prefs, locale, ефекти                |
| AudioManager        | `AudioManager.gd`        | SFX/music                            |
| I18nManager         | `I18nManager.gd`         | uk/ru/en JSON                        |
| ThemeManager        | `VisualThemeManager.gd`  | dawn/dusk/twilight, фони             |
| LeaderboardService  | `LeaderboardService.gd`  | offline stub                         |
| ScreenRouter        | `ScreenRouter.gd`        | back-stack, transitions              |
| LegacySaveMigration | `LegacySaveMigration.gd` | Capacitor → Godot import             |

Екрани (за архітектурним доком): MainMenu, Game, Settings, Achievements, DailyQuests, Wheel, Stats, About, SkinPreview.

Мережі **немає** — offline-first; Firebase/cloud — Phase 6, не стартовано (`docs/PHASES.md`).

### 2.3 Якість документації

| Документ                                | Роль                                           | Оцінка                                                                                                  |
| --------------------------------------- | ---------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `docs/en/SOURCE_OF_TRUTH.md`            | Канонічні рішення PO, версії, індекс доків     | ✅ відмінно; **застарілий рядок про CI** («godot:test:all local only») — зараз CI має job `godot-tests` |
| `docs/en/VISUAL_TARGET.md`              | Візуальний acceptance (mockups, chrome, wheel) | ✅ сильний product/design SoT                                                                           |
| `docs/ANDROID_RELEASE_READINESS.md`     | Checklist перед `godot:android:release`        | ✅ практичний, актуальні пресети/ABI/signing                                                            |
| `docs/PLAY_STORE.md`                    | Console listing, privacy, forms                | ✅ операційний                                                                                          |
| `docs/en/ARCHITECTURE.md`               | Шар / autoloads / layout                       | ✅; CI description теж трохи застаріла                                                                  |
| `docs/ANDROID_QA.md`                    | Device QA                                      | ⚠️ короткий (≈19 рядків) — варто розширити під Closed testing                                           |
| `docs/HANDOFF.txt` / `HANDOFF-IDEAL.md` | Handoff                                        | ✅                                                                                                      |
| Повне ТЗ `docs/TZ_PLAY_RELEASE.md`      | —                                              | ❌ **відсутнє в дереві** (було згенеровано в сесії, не закомічено)                                      |

**Висновок по docs:** документація вище середнього для інді/Godot-проєктів; головний ризик — **drift** між SOURCE_OF_TRUTH і реальним CI / наявністю keystore+AAB.

---

## 3. Build System, Automation & CI/CD Review

### 3.1 Екосистема npm-скриптів (карта)

| Група         | Скрипти                                                                         | Призначення                                                                          |
| ------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| Quality       | `format*`, `lint*`, `typecheck`, `check`, `verify:tagline`, `test`/`test:smoke` | Tooling hygiene + layout smoke                                                       |
| Release gates | `release:check`, `release:ideal`                                                | Композитний pre-merge / ideal gate                                                   |
| Godot         | `godot:import`, `godot:test*` , `godot:test:all`, `godot:test:perf`             | Import + headless suite (rules/levels/save/smoke/i18n/visual)                        |
| Android       | `godot:android:debug/release/install/adb-install/log/...`                       | Export + device ops                                                                  |
| AAB gate      | `godot:verify:aab`                                                              | `godot:test:all` + `release:check` + **перезбірка release** + unzip checks           |
| Store         | `store:prepare`, `store:verify`                                                 | Іконки / listing assets                                                              |
| Pack          | `pack:unified`                                                                  | Handoff ZIP з **committed HEAD** (`git archive`), denylist, REQUIRED_PATHS, manifest |
| Meta          | `all:*`, `cursor:audit*`                                                        | Оркестрація / SDK audit                                                              |
| Privacy       | `privacy:package`                                                               | Артефакт для Pages                                                                   |
| Keystore      | `keystore:info`                                                                 | SHA fingerprints без витоку паролів у git                                            |

`release:check` (`scripts/release-check.mjs`) послідовно: Prettier → ESLint → tsc → tagline → `verify-godot-release.mjs` → `verify-play-store.mjs` → smoke-tests.

### 3.2 Підхід до тест-автоматизації

- **Ізоляція:** `scripts/run-godot-isolated.sh` запускає `godot4 --path godot --headless` з окремим середовищем (уникає забруднення editor `.godot`).
- **Шари тестів:**
  - Node smoke: наявність ключових шляхів проєкту (`scripts/smoke-tests.mjs`).
  - GDScript headless: rules, LevelManager, save, smoke, i18n, visual skins.
  - Perf (окремо): `godot:test:perf` з `--resolution 420x920` і JSON у `build/qa/`.
- **Регресія аудіо:** visual runner має cleanup `AudioManager.stop_music()` (історичний ObjectDB leak при mount App shell) — важливо для чистих exit logs.
- **CI pin:** Godot **4.7.1** з SHA-256 архіву; assert точного `--version` string.

Сильні сторони: детермінізм версії Godot у CI; покриття не лише rules, а й i18n/visual.  
Прогалини: немає UI screenshot golden tests у CI; perf не в `godot:test:all`; немає автоматичного `godot:verify:aab` у GitHub Actions (потрібні secrets keystore — свідомо локальний gate).

### 3.3 CI/CD (`.github/workflows`)

#### `ci.yml`

| Job             | Що робить                                             | Оцінка                                               |
| --------------- | ----------------------------------------------------- | ---------------------------------------------------- |
| `release-check` | `npm ci` + `npm run release:check` на Node 24         | ✅ базовий quality gate                              |
| `godot-tests`   | Install pinned Godot 4.7.1 + `npm run godot:test:all` | ✅ **критично важливо** — раніше цього не було в SoT |

Checkout з `lfs: true` — правильно, якщо великі assets у LFS.

#### `pages.yml`

Деплой **лише** privacy-host на GitHub Pages після push `main`. URL: `https://averixor.github.io/LostNumber/privacy.html`.

#### Відсутні / свідомі прогалини CI

| Gap                                                                     | Ризик                                                 | Рекомендація                                                                                                        |
| ----------------------------------------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Немає збірки AAB у CI                                                   | Не ловить поломку export templates / Gradle на runner | Опційно: night job з **GitHub encrypted secrets** для upload key (висока складність/безпека) або self-hosted runner |
| Немає `store:verify` окремим обов’язковим job (входить у release:check) | Низький                                               | Залишити в `release:check`                                                                                          |
| Feature branches без required checks на GitHub settings                 | Процесний                                             | Увімкнути branch protection: обидва jobs required                                                                   |
| Документація каже «Godot tests local only»                              | Drift                                                 | Оновити SOURCE_OF_TRUTH / ARCHITECTURE                                                                              |

### 3.4 Pack / provenance

`scripts/pack-unified.sh`:

1. Відмова при dirty tree.
2. `git archive` → staging.
3. Видалення denylist (`*.bak`, `*.broken`, `*.import`, soft-gothic, тощо).
4. `PACKAGE-MANIFEST.txt` (SHA, branch, UTC, version).
5. ZIP + `unzip -t` + вбудований denylist + **REQUIRED_PATHS** (project, export presets, App.tscn, HANDOFF, MERGE_NOTES, migration plugin AAR, store icon/feature graphic).

Це закриває історичну проблему «zip -r живої директорії» з `.project`/`.gradle`/plugin builds.

---

## 4. Production Readiness & Release Compliance (Google Play)

### 4.1 Android release configuration

| Вимога Play / інженерна             | Стан у репо                                                          |
| ----------------------------------- | -------------------------------------------------------------------- |
| targetSdk 35                        | ✅                                                                   |
| AAB (не APK) для upload             | ✅ preset + локальний `lost-number.aab`                              |
| Підпис upload key                   | ✅ локально (`lostnumber-upload-2026.jks`)                           |
| Secrets не в git                    | ✅ `.gitignore`: `android/keystore/`, `*.jks`, `keystore.properties` |
| Виключення тестів/store з бінарника | ✅ `exclude_filter` + `verify-godot-aab.sh` checks                   |
| Migration plugin                    | ✅ `LostNumberMigrationPlugin-release.aar` у REQUIRED_PATHS          |
| Adaptive icons                      | ⚠️ порожні поля в preset (optional)                                  |
| 32-bit ABI                          | ❌ свідомо вимкнено (`armeabi-v7a=false`) — ~8k пристроїв            |

`godot:verify:aab` перевіряє: відсутність `dev|cheat|DebugOverlay` у listing zip; наявність `libgodot_android.so`; відсутність `assets/store/` і `scripts/tests/`; розмір; далі — логіка скрипта (bundletool за наявності).

### 4.2 Версіонування vs Console

| Сценарій                                   | Дія                                                                                                                                |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| VC16 **ніколи** не upload                  | можна залишити 16 / 2.1.6 для першого upload                                                                                       |
| VC16 уже в Console (навіть draft/rejected) | **обов’язково** bump → **17** / **2.1.7** у `export_presets.cfg` + sync docs/`package.json`                                        |
| Документація зараз                         | ANDROID_RELEASE_READINESS / SOURCE_OF_TRUTH пишуть «next = 17» — трактувати як **очікування**, доки власник не підтвердить Console |

### 4.3 Store compliance assets

| Актив                         | Шлях                                                     | Статус                                                                                                 |
| ----------------------------- | -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| High-res icon 512             | `store/play-high-res-icon-512.png`                       | ✅                                                                                                     |
| Feature graphic 1024×500      | `store/feature-graphic-1024x500.png`                     | ✅                                                                                                     |
| Phone screenshots (≥2)        | `store/screenshots/phone/01…04-*.png`                    | ⚠️ 4 файли є; `PLAY_STORE.md` / README все ще кажуть **чернетки з фонів**, не фінальні in-app captures |
| Listing copy UK/EN/RU         | `docs/store-listing/*` + `store/PLAY_CONSOLE_LISTING.md` | ✅                                                                                                     |
| Privacy URL                   | Pages + `privacy.html`                                   | ✅ стратегія готова                                                                                    |
| IARC / Data safety / Audience | таблиці в `docs/PLAY_STORE.md`                           | 📋 треба заповнити **в Console**                                                                       |
| Ads / IAP                     | No (offline puzzle)                                      | ✅ спрощує Data safety                                                                                 |

### 4.4 Play Console blockers (поза git)

1. **Identity verification** — Production заблокований до завершення (`docs/PLAY_STORE.md`).
2. **Closed testing track** — потрібен upload AAB + testers + release notes.
3. **Узгодження upload certificate** з локальним `lostnumber-upload-2026.jks` (`npm run keystore:info` → порівняти SHA з Console App signing).
4. Чи був upload VC16 — **невідомо з репо**.

### 4.5 Локальна готовність vs «здано в Play»

| Критерій                      | Локально                                           | Play                  |
| ----------------------------- | -------------------------------------------------- | --------------------- |
| Signed AAB існує              | ✅                                                 | ❓ uploaded?          |
| Keystore узгоджений з Console | ❓ треба звірити fingerprints                      | —                     |
| Listing graphics uploaded     | матеріали готові                                   | ❓                    |
| Device QA formal sign-off     | debug APK є                                        | ❓ по `ANDROID_QA.md` |
| `godot:verify:aab` last green | не зафіксовано в цьому аудиті як прогон 2026-08-04 | —                     |

---

## 5. Potential Risks, Bottlenecks & Security Evaluation

### 5.1 Security practices

| Практика                                                          | Оцінка                                                                                        |
| ----------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `.jks` / `keystore.properties` у `.gitignore`                     | ✅                                                                                            |
| Каталог `android/keystore/` ігнорується                           | ✅ (у т.ч. `.pem` через ігнор директорії)                                                     |
| Export script може тимчасово писати паролі в `export_presets.cfg` | ⚠️ мітиговано `verify-godot-release.mjs` (відхиляє commit) — ризик людської помилки лишається |
| AAB/APK у `build/android/*` gitignored                            | ✅                                                                                            |
| Немає мережевих API ключів у грі                                  | ✅ offline                                                                                    |
| `@cursor/sdk` + `CURSOR_API_KEY` для audit                        | ⚠️ лише local tooling; не комітити ключ                                                       |
| `docs/PLAY_STORE.md` містить контакт email                        | інформаційний; ок для public listing                                                          |

**Рекомендація безпеки:** після кожного `godot:android:release` завжди `git status` / `git diff godot/export_presets.cfg` — переконатися, що паролі не staged.

### 5.2 Технічні ризики Godot 4.7 + Android

| Ризик                               | Деталі в цьому репо                                                                                     | Severity     |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------- | ------------ |
| Export templates / JDK / SDK path   | Документовано snap Godot + `~/Android/jbr`; крихко на нових машинах                                     | Medium       |
| Розмір AAB/APK                      | ~142 MB AAB / ~252 MB debug — великий для casual puzzle; перевірити asset compression / import settings | Medium       |
| Immersive + notch / gesture nav     | `screen/immersive_mode=true` — потрібен device QA на сучасних телефонах                                 | Medium       |
| Audio / Autoload lifecycle у тестах | вже був leak ambient у visual tests — фікс є, моніторити регресії                                       | Low–Med      |
| LevelManager overflow / `pow(2,n)`  | згадано в історичних аудитах — medium gameplay debt                                                     | Medium       |
| Legacy Import UI stub               | Settings Import показує stub — очікування користувачів Capacitor                                        | Low–Med      |
| Відсутність armeabi-v7a             | свідомий tradeoff                                                                                       | Low (бізнес) |
| Flathub vs official Godot binary    | Локально flathub, CI official — майже той самий hash `a13da4feb`, але різниця channel                   | Low          |

### 5.3 Bottlenecks процесу

1. **Play Console — single owner gate** (identity, upload key policy, forms).
2. **Немає CI AAB** — регресії export ловляться лише локально.
3. **Feature branch UI work** (`fix-gothic-chrome-readability`) може роз’їхатися з `main`, з якого вже зібраний AAB 2026-07-27.
4. **Скріншоти** — блокер сприйняття якості лістингу, не блокер збірки.
5. **Dirty tree** блокує `pack:unified` — правильно, але сповільнює handoff під час активної розробки.

### 5.4 Dependencies risk

| Dependency                                             | Ризик                                                                                    |
| ------------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| Godot 4.7.1 pin у CI                                   | ✅ добре; оновлення minor потребує оновлення SHA + templates                             |
| Node 24 у CI / engines ≥20.19                          | ✅                                                                                       |
| ESLint 10 / Prettier 3.9 / TS 5.9                      | Low                                                                                      |
| `@cursor/sdk`                                          | не впливає на ship binary                                                                |
| undici override для `@connectrpc/connect-node`         | tooling-only                                                                             |
| Android Gradle через Godot                             | transitive AGP/SDK — класичний мобільний supply-chain; тримати templates в sync з engine |
| GitHub Actions pin commit SHAs для checkout/setup-node | ✅ гарна практика в `ci.yml`                                                             |

### 5.5 Tracked junk (борг репозиторію)

Досі в git (виключені з unified ZIP denylist):

- `godot/icon.svg.broken`
- `godot/scenes/Boot.tscn.bak`
- `godot/project.godot.soft-gothic-*`, `GothicUiStyler.gd.soft-gothic-*`
- `project.godot.soft-gothic-*` (root)
- `icon-1024.png.import`

Не блокує Play upload бінарника, але псує гігієну репо й плутає новачків.

---

## 6. Actionable Recommendations & Next Steps

### 6.1 High priority

| #   | Дія                                                            | Навіщо                                                                                                        | Як виміряти                                |
| --- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| H1  | **Play Console recon**                                         | App signing upload cert SHA vs `npm run keystore:info`; max versionCode; чи є VC16                            | Записати 3 факти в handoff note            |
| H2  | **Version bump decision**                                      | Якщо VC16 уже був — `export_presets.cfg` → code **17**, name **2.1.7**, sync `package.json` + SOURCE_OF_TRUTH | Diff + `release:check`                     |
| H3  | **Пересобрати AAB з цільової гілки** (`main` або merge UI-fix) | Поточний AAB від 2026-07-27 може не містити chrome fixes з `21a627b`                                          | Новий mtime AAB + `godot:verify:aab` green |
| H4  | **`npm run godot:verify:aab` на release-машині**               | Єдиний канонічний pre-upload gate                                                                             | Exit 0; логи зберегти                      |
| H5  | **Closed testing upload**                                      | Реальний шлях у Play                                                                                          | Track має AAB + release notes              |
| H6  | **Звірити upload key**                                         | Інакше Console відхилить підпис                                                                               | SHA-1/256 match                            |

### 6.2 Medium priority

| #   | Дія                                                                                                   | Навіщо                      |
| --- | ----------------------------------------------------------------------------------------------------- | --------------------------- |
| M1  | In-app phone screenshots (меню/гра/налаштування) замість promo drafts                                 | Compliance + conversion     |
| M2  | Заповнити IARC, Data safety, Target audience в Console за `docs/PLAY_STORE.md`                        | Review readiness            |
| M3  | Розширити `docs/ANDROID_QA.md` (12+ сценаріїв: back stack, audio pause, save/load, locale, immersive) | Formal QA sign-off          |
| M4  | Оновити SOURCE_OF_TRUTH / ARCHITECTURE: CI тепер ганяє `godot:test:all`                               | Doc drift                   |
| M5  | Закомітити канонічне ТЗ (`docs/TZ_PLAY_RELEASE.md` або цей аудит як SoT)                              | Онбординг                   |
| M6  | Device QA на arm64 телефоні debug/release-derived APK                                                 | Перед відкритим тестуванням |
| M7  | Перевірити розмір AAB / texture import (чи можна стиснути без втрати VISUAL_TARGET)                   | Store download UX           |

### 6.3 Low priority

| #   | Дія                                                                                                   | Навіщо                   |
| --- | ----------------------------------------------------------------------------------------------------- | ------------------------ |
| L1  | Cleanup PR: видалити tracked `.bak` / `.broken` / soft-gothic / stray `.import` після пошуку посилань | Гігієна                  |
| L2  | Adaptive launcher icons у export preset                                                               | Play polish              |
| L3  | Опційний CI secret-based AAB smoke (або self-hosted)                                                  | Catch export regressions |
| L4  | Branch protection: required `release-check` + `godot-tests`                                           | Процес                   |
| L5  | Розглянути `armeabi-v7a` лише якщо аналітика покаже втрати                                            | Coverage                 |
| L6  | Phase 6 Firebase — не починати до стабільного Play Closed testing                                     | Scope control            |

### 6.4 Рекомендований порядок виконання (операційний)

```text
H1 Console recon
 → H6 keystore SHA match
 → H2 versionCode decision
 → merge UI branch to main (якщо потрібно)
 → H3 rebuild AAB
 → H4 godot:verify:aab
 → M6 device QA
 → M2 Console forms + M1 screenshots
 → H5 Closed testing
 → (пізніше) identity → Production
 → L1 junk cleanup
```

### 6.5 Definition of Done для «робочого Play-проєкту»

- [ ] `godot:verify:aab` green на машині з keystore
- [ ] AAB versionCode узгоджений з Console; targetSdk 35; not debuggable
- [ ] Upload certificate fingerprints збігаються з Console
- [ ] Closed testing містить reviewable release
- [ ] Listing: icon, feature graphic, ≥2 адекватних phone screenshots, UK/EN/RU тексти
- [ ] IARC + Data safety submitted
- [ ] Privacy URL HTTP 200
- [ ] Device QA без P0/P1
- [ ] Production — лише після identity verification

---

## Додаток A — Швидкі команди

```bash
npm ci
npm run release:check
npm run godot:test:all
npm run keystore:info
npm run godot:android:release
npm run godot:verify:aab
npm run pack:unified   # потребує clean git tree
```

## Додаток B — Пов’язані матеріали

- `docs/ANDROID_RELEASE_READINESS.md`
- `docs/PLAY_STORE.md`
- `docs/en/SOURCE_OF_TRUTH.md`
- `docs/en/VISUAL_TARGET.md`
- `docs/en/ARCHITECTURE.md`
- Canvas: `canvases/lost-number-play-release-audit.canvas.tsx`

---

_Кінець аудиту 360°. Статус Play Console upload/identity — підтверджує власник акаунта, не git._
