# Visual Port Map — Web → Godot

Карта переносу візуалу з еталонної Capacitor/Web-версії (корінь репозиторію) у Godot 4.5.
Web-версія — **parity reference** для UI/UX, кольорів, ассетів та i18n (не єдине джерело
істини). Прийняття визначають PO, затверджені Godot-скріншоти та фактична Godot-реалізація.
Статус **DONE** означає візуальну відповідність parity reference, а не автоматичну згоду PO.

Статуси:

- **TODO** — у Godot ще нічого немає або є тільки логіка без візуалу.
- **PARTIAL** — сцена/скрипт існує (MVP), але візуал не відповідає web-еталону.
- **DONE** — перенесено і візуально відповідає web-версії.

## Екрани

| Web source                                         | Godot target                                | Scene       | Status  |
| -------------------------------------------------- | ------------------------------------------- | ----------- | ------- |
| `index.html` `#mainMenuScreen` + `css/ui.css`      | `godot/scenes/MainMenu.tscn`                | MainMenu    | DONE    |
| `index.html` `#gameScreen` (HUD, goal-box, xp)     | `godot/scenes/Game.tscn` + `GameHud.tscn`   | Game        | PARTIAL |
| `index.html` `#settingsScreen`                     | `godot/scenes/Settings.tscn`                | Settings    | PARTIAL |
| Settings → custom background preview               | `godot/scenes/SkinPreview.tscn`             | SkinPreview | PARTIAL |
| `index.html` `#aboutScreen`                        | `godot/scenes/About.tscn`                   | About       | DONE    |
| `index.html` `#achievementsScreen`                 | `godot/scenes/Achievements.tscn`            | Achievement | PARTIAL |
| `index.html` `#statsScreen`                        | `godot/scenes/Stats.tscn`                   | Stats       | DONE    |
| `index.html` `#dailyQuestsScreen`                  | `godot/scenes/DailyQuests.tscn`             | DailyQuests | PARTIAL |
| `index.html` `.wheel-overlay` + `css/overlays.css` | `godot/scenes/Wheel.tscn`                   | Wheel       | PARTIAL |
| `index.html` `#appSplash` + `css/critical.css`     | `godot/scenes/Boot.tscn`                    | Boot        | DONE    |
| app shell + переходи між екранами                  | `godot/scenes/App.tscn` + `ScreenRouter.gd` | App         | DONE    |

Примітки:

- MainMenu: web parity — gradient title, primary Play/Continue, quick-row chips (Settings,
  Stats, About) **DONE**, bottom dock (Premium/Tournaments/Achievements/Daily/Bonuses) **DONE**,
  SVG icons **DONE**, FeatureStubOverlay for premium/tournaments/bonuses **DONE**,
  tagline double-tap → `ThemeManager.cycle_background()`, staggered fade+slide entrance.
- Settings: scroll + **Back** pinned at bottom (offset −72 px on Scroll); theme toggle cycles **dawn/dusk only** (`ThemeManager.UI_CYCLE_THEMES`; twilight in code but hidden from UI); skin picker → `SkinPreview` via `ImagePickerHelper.gd` (not MobileImagePicker).
- SkinPreview: full-screen preview of custom/user background; pick/apply/cancel; reached from Settings.
- DailyQuests: scroll list + **Back** at bottom (same layout as Settings); card layout in `DailyQuestCard.tscn`.
- Game/Achievements — MVP; chain-sum HUD і preview bubble — **PARTIAL** (логіка в `GameHud.gd` / `Board.gd`; візуальна прийняття pending).
- Stats/About — мінімальні екрани з back-stack навігацією.
- Boot: фон з токенів, glow-шар під логотипом (`LnUi.wire_logo_glow`), ProgressBar,
  неонова пульсація (AnimationPlayer), реальний прогрів (SaveManager + preload App), fade у App.
- Навігація: `ScreenRouter` (autoload) з back-stack (push/pop/go_back),
  fade-переходи через `components/ScreenTransition.tscn`; Android back
  обробляє `App.gd` (NOTIFICATION_WM_GO_BACK_REQUEST → go_back()).

## Поле, плитки, ланцюг

| Web source                                        | Godot target                        | Scene      | Status  |
| ------------------------------------------------- | ----------------------------------- | ---------- | ------- |
| `css/grid.css` `.grid` (5×8, radius 14, panel)    | `godot/scripts/game/Board.gd`       | Game/Board | PARTIAL |
| `css/grid.css` `.cell` (radius 9, тіні)           | `godot/scenes/components/Tile.tscn` | Tile       | DONE    |
| `css/grid.css` `.cell[data-number]` палітра 2…2M  | `godot/scripts/ui/ThemeTokens.gd`   | Tile       | PARTIAL |
| `css/grid.css` selected/valid/invalid стани       | `godot/scripts/game/Tile.gd`        | Tile       | PARTIAL |
| `css/grid.css` анімації pop/bubbleOut/carryIn     | Godot tween в `Tile.gd`             | Tile       | PARTIAL |
| `css/grid.css` `.cell.frozen` + `.freeze-counter` | `godot/scripts/game/Board.gd`       | Tile       | PARTIAL |
| `css/ui.css` `.chain-sum-hud` (+valid/invalid)    | `GameHud.gd` / `GameHud.tscn`       | Game       | PARTIAL |
| `css/ui.css` `.preview-bubble`                    | `Board.gd` PreviewBubble            | Game       | PARTIAL |

Примітки:

- `Tile.tscn` + `Tile.gd`: ThemeTokens палітра, chain highlight, carry badge, pop tween.
- `ChainLineLayer.tscn`: 3-pass neon glow для ланцюга.
- `GameHud.tscn`: top bar, XP bar, target panel, bonus row з іконками; active/available bonus glow.
- Навігація: `ScreenRouter` з back-stack; slide+fade через `ScreenTransition` (low effects → fade only).
- i18n: `godot/assets/i18n/{uk,ru,en}.json` з `js/system/i18n/i18n.js`, fallback uk→ru→en.
- Audio: семантичні події в `AudioManager` (`button_click`, `tile_select`, `wheel_spin`, …).

## Тема, кольори, фони

| Web source                                     | Godot target                                   | Scene        | Status  |
| ---------------------------------------------- | ---------------------------------------------- | ------------ | ------- |
| `css/variables.css` (dawn/dusk токени)         | `godot/scripts/ui/ThemeTokens.gd`              | Global Theme | DONE    |
| `css/base.css` + `css/ui.css` (radius, шрифти) | `godot/themes/lost_number_theme.tres`          | Global Theme | DONE    |
| `css/ui.css` `.main-menu` skin-токени          | `godot/scripts/ui/ThemeTokens.gd`              | MainMenu     | DONE    |
| `assets/images/dark/menu-bg-*.png` (6 шт.)     | `godot/assets/ui/backgrounds/dark/`            | MainMenu     | DONE    |
| `assets/images/light/bg-light-*.png` (6 шт.)   | `godot/assets/ui/backgrounds/light/`           | MainMenu     | DONE    |
| `js/system/platform/background.js` (ротація)   | `godot/scripts/managers/ThemeManager.gd`       | Global Theme | DONE    |
| `css/background.css` (фон + overlay)           | `godot/scenes/components/BackgroundLayer.tscn` | App          | DONE    |
| `css/ui.css` `.menu-btn` / `.primary` / ghost  | `godot/scenes/components/NeonButton.tscn`      | Components   | DONE    |
| `css/low-performance.css`                      | `SettingsManager.bg_effects_enabled`           | Settings     | DONE    |
| `css/critical.css` (error screen, спінер)      | Godot error handling / Boot                    | Boot         | PARTIAL |

Примітки:

- `ThemeManager.gd`: `THEMES` = dawn/dusk/twilight; user-facing toggle uses **`UI_CYCLE_THEMES` = dawn/dusk only** (twilight hidden until art ships). `background_index` (6 PNG per bucket), `cycle_background()` (MainMenu tagline double-tap). Menu skin tokens (titleFrame arc/diamond, chip shapes) — TODO.
- Global background path: `ThemeManager.get_background_texture_path()` → `LnUi.current_background_path()`; `BackgroundLayer` (App shell) and per-screen fallbacks read from there.
- `BackgroundLayer`: арт з `assets/ui/backgrounds/{dark,light,twilight}/`, dim-overlay,
  неонове свічення, повільні частинки. Частинки будуються тільки якщо
  `bg_effects_enabled` (перемикач у Settings, low effects mode).
- `css/critical.css`: спінер/лоадер закрито Boot-екраном; error screen — TODO.

## Store graphics vs in-game assets

| Призначення          | Шлях                   | У AAB?                                                          |
| -------------------- | ---------------------- | --------------------------------------------------------------- |
| Play Console listing | `store/` (корінь репо) | Ні                                                              |
| Godot store copies   | `godot/assets/store/`  | **Ні** — `exclude_filter=assets/store/*` у `export_presets.cfg` |
| In-game UI           | `godot/assets/ui/`     | Так — підключено з `.tscn`                                      |

Не посилайся на `assets/store/*` з ігрових сцен; тільки `assets/ui/`.

## Legacy save migration

| Web source                      | Godot target                                         | Status |
| ------------------------------- | ---------------------------------------------------- | ------ |
| `localStorage` `lostNumberSave` | `LegacySaveMigration.gd` + Android plugin + Settings | DONE   |

Деталі: `godot/docs/LEGACY_SAVE_MIGRATION.md`.

## Іконки та аудіо

| Web source                                      | Godot target                            | Scene        | Status |
| ----------------------------------------------- | --------------------------------------- | ------------ | ------ |
| `assets/icons/neon/icons/*.svg` (41 шт.)        | `godot/assets/ui/icons/neon/`           | UI           | DONE   |
| `assets/icons/neon/sprite/lostnumber-icons.svg` | — (у Godot окремі SVG)                  | UI           | —      |
| `js/ui/icons.js` (мапінг icon → slot)           | MenuDock, GameHud, MainMenu, back btns  | UI           | DONE   |
| `public/audio/music/*.mp3` (5 треків)           | `godot/assets/audio/music/`             | AudioManager | DONE   |
| `public/audio/sfx/*.mp3` (8 звуків)             | `godot/assets/audio/sfx/`               | AudioManager | DONE   |
| `js/system/platform/audio.js`                   | `scripts/managers/AudioManager.gd`      | AudioManager | DONE   |
| `assets/icons/icon.png`, `icon-1024.png`        | `godot/icon.png`, `godot/icon-1024.png` | Export       | DONE   |

Примітки:

- Аудіо вже розкладено по `music/` та `sfx/` — шляхи в `AudioManager.gd` актуальні.
- Канонічне дерево neon-іконок: `godot/assets/ui/icons/neon/`; legacy fallback для crown —
  `godot/assets/ui/icons/tile-crown.png`.
- Копія `godot/assets/icons/neon/` видалена; AAB exclude_filter лишається для `assets/store/*`.
- Store-графіка (`assets/store/*`) лишається виключеною з експорту; не дублювати в `assets/ui/store/`.

## Оверлеї, модалки, тости

| Web source                                       | Godot target                       | Scene | Status  |
| ------------------------------------------------ | ---------------------------------- | ----- | ------- |
| `css/overlays.css` `.victory-overlay`            | компонент VictoryOverlay           | Game  | TODO    |
| `css/overlays.css` `.level-overlay`              | компонент LevelOverlay             | Game  | PARTIAL |
| `css/overlays.css` `.wheel-overlay` + `wheel.js` | `godot/scenes/Wheel.tscn`          | Wheel | PARTIAL |
| `css/overlays.css` `.confirm-overlay`            | компонент ConfirmDialog            | UI    | TODO    |
| `css/ui.css` `.system-toast`                     | компонент Toast                    | UI    | TODO    |
| `index.html` feature-stub dialog                 | `FeatureStubOverlay.tscn`          | UI    | DONE    |
| fade між екранами (ScreenRouter)                 | `components/ScreenTransition.tscn` | App   | DONE    |

Примітки:

- Wheel: canvas spin animation (`WheelCanvas.gd`), result modal з dim + scale-in.
  Web arrow/highlight polish — PARTIAL.
- Компоненти складати в `godot/scenes/components/`.

## Механіки з візуальною частиною

| Web source                                    | Godot target                      | Scene       | Status  |
| --------------------------------------------- | --------------------------------- | ----------- | ------- |
| `js/game/mechanics/bonuses.js` (кнопки HUD)   | `GameHud.gd` + `BonusManager.gd`  | Game        | DONE    |
| `js/game/mechanics/wheel.js`                  | `scripts/meta/WheelManager.gd`    | Wheel       | PARTIAL |
| `js/game/meta/achievements.js` (grid-картки)  | `scripts/ui/Achievements.gd`      | Achievement | PARTIAL |
| `js/game/meta/daily.js` (список квестів)      | `scripts/ui/DailyQuests.gd`       | DailyQuests | PARTIAL |
| `js/app/ui/i18n-theme.js` + `js/system/i18n/` | `scripts/managers/I18nManager.gd` | I18n        | PARTIAL |
| `js/game/grid/grid-animations.js`             | Godot tween/AnimationPlayer       | Game        | PARTIAL |

Примітки:

- I18nManager: UA/RU/EN JSON по **285 ключів** (`godot/assets/i18n/{uk,ru,en}.json`); тести `npm run godot:test:i18n`. Деякі web-only рядки (тости, confirm) ще TODO.
