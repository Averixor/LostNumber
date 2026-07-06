# Lost Number — Godot 4 (primary Android)

Native Godot port — **ship target for Google Play**. Capacitor/Web (`js/`, `index.html`) remains the visual reference and legacy build path.

## Requirements

- Godot **4.3+** (4.5 tested)
- Portrait 420×920 (`project.godot`)
- Node.js ≥ 20.19 for npm scripts

## Entry flow

```
Boot.tscn (main_scene)
  → preload + fade
  → App.tscn (shell: BackgroundLayer, ScreenRoot, overlays)
  → MainMenu via ScreenRouter (autoload)
```

Screens mount under `App/ScreenRoot`. Navigation: `ScreenRouter.push()` / `go_back()` with back-stack and fade transitions (`ScreenTransition.tscn`). Android back is handled in `App.gd`. Screens do not call `change_scene_to_file` directly (fallback only when App shell is not mounted, e.g. F6).

## Open / import

First-time import (registers `class_name` globals):

```bash
npm run godot:import
# or: godot4 --path godot --import --headless
```

Run in editor:

```bash
godot4 --path godot
```

## Tests

```bash
npm run godot:test:all
```

Includes rules, save (checksum + `.bak`), and smoke (autoloads, scenes, scripts compile).

Headless boot check (Boot → App → MainMenu, no script errors):

```bash
timeout 15 godot4 --path godot --headless
```

## Android

```bash
npm run godot:android:debug     # build/godot/android/lost-number-debug.apk
npm run godot:android:release   # build/godot/android/lost-number.aab
```

Version: `2.1.4` / versionCode `14` (`export_presets.cfg`). Details: `godot/docs/ANDROID_RELEASE_READINESS.md`, `godot/docs/PLAY_STORE_GODOT.md`. Legacy save: `godot/docs/LEGACY_SAVE_MIGRATION.md` (file import + `LostNumberMigration` Android plugin AAR).

## Structure

```
project.godot          main_scene → Boot.tscn; autoloads incl. ScreenRouter
scenes/
  Boot.tscn            splash / preload → App
  App.tscn             shell (BackgroundLayer, ScreenRoot, OverlayRoot)
  MainMenu.tscn        … Game, Settings, SkinPreview, Stats, About, Achievements, DailyQuests, Wheel
  components/          BackgroundLayer, NeonButton, MenuDockButton, MenuQuickChip, FeatureStubOverlay, ScreenTransition
scripts/
  App.gd               registers ScreenRouter, Android back
  core/                Rules, BoardLogic, GameState, …
  game/                Game, Board, Tile, ChainLineLayer, BonusManager
  ui/                  GameHud, SkinPreview, ImagePickerHelper, WheelCanvas, AchievementCard, DailyQuestCard, …
  assets/i18n/         uk.json, ru.json, en.json — 285 keys each (from js/system/i18n/i18n.js)
  managers/            SaveManager, SettingsManager, AudioManager, ThemeManager, I18nManager, …
  ui/                  ScreenRouter, Boot, MainMenu, ThemeTokens, …
  meta/                WheelManager, DailyQuestManager
themes/
  lost_number_theme.tres   global GUI theme (tokens-based)
  title_gradient.gdshader  menu/boot title gradient
assets/
  ui/backgrounds/{dark,light}/   menu art (from web assets/)
  ui/icons/                      neon SVG (UI copy; neon/ excluded from AAB export)
  audio/{music,sfx}/             mp3 via git LFS
docs/
  VISUAL_PORT_MAP.md     Web → Godot visual parity tracker
  MIGRATION_FROM_JS.md   logic port map
  GAME_RULES.md
```

## Visual foundation (Sprint 1)

- `ThemeTokens.gd` + `lost_number_theme.tscn` — colors/radii from web CSS
- `BackgroundLayer` — theme art, dim overlay, optional particles (`SettingsManager.bg_effects_enabled`)
- `NeonButton` — primary / secondary / ghost (no default grey Godot buttons on MainMenu)
- MainMenu: gradient title, primary actions, quick-row chips, bottom dock, SVG icons, feature stubs, bg cycle (tagline double-tap; theme toggle dawn/dusk only — twilight hidden in UI)
- Settings → SkinPreview: custom background via `ImagePickerHelper.gd`; Back button pinned at bottom
- Stats / About screens; legacy save plugin (`android/plugins/LostNumberMigrationPlugin/`)

Next visual work: `godot/docs/VISUAL_PORT_MAP.md` (chain-sum HUD, toasts, menu skin variants).
