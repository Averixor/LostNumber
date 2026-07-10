# Migration from JS to Godot

Lost Number **2.1.6** — Godot 4.5 / GDScript. The HTML/Capacitor build remains a **visual reference** and legacy Android path — not the primary Play upload target.

Canonical decisions: `docs/en/SOURCE_OF_TRUTH.md`. Visual port status: `godot/docs/VISUAL_PORT_MAP.md`.

## Architecture map

| JS (vanilla)                              | Godot                                                    |
| ----------------------------------------- | -------------------------------------------------------- |
| `js/core/rules.js`                        | `scripts/core/Rules.gd`                                  |
| `js/game/GameCore.js` + `grid-physics.js` | `scripts/core/BoardLogic.gd`                             |
| `js/game/state.js` (levels/spawn)         | `scripts/core/LevelManager.gd`                           |
| `js/game/state.js` (session)              | `scripts/core/GameState.gd`                              |
| `js/app/persistence/save-load.js`         | `scripts/managers/SaveManager.gd`                        |
| `GridManager` + grid render               | `scripts/game/Board.gd` + `Tile.gd`                      |
| `LostNumberGame`                          | `scripts/game/Game.gd` + `scenes/Game.tscn`              |
| `js/system/platform/audio.js`             | `scripts/managers/AudioManager.gd`                       |
| `menu.js`                                 | `scenes/MainMenu.tscn`                                   |
| App shell + navigation                    | `scenes/App.tscn` + `ScreenRouter.gd` (autoload)         |
| `js/system/i18n/i18n.js`                  | `scripts/managers/I18nManager.gd` + `assets/i18n/*.json` |
| `js/system/platform/background.js`        | `scripts/managers/ThemeManager.gd`                       |
| Capacitor save (`localStorage`)           | `LegacySaveMigration.gd` + Android plugin                |

## Parity checklist

### Core gameplay — done

- [x] `Rules.gd` — chain validation 1:1 with `rules.js`
- [x] 5×8 grid generation (weighted spawn, min tile by level)
- [x] Drag chain (8-neighbor, backtrack one step)
- [x] Merge + gravity + spawn
- [x] Level target / complete / carry
- [x] **40 preset levels + procedural endless** (`MANUAL_LEVEL_COUNT := 40`)
- [x] XP base by chain length
- [x] Save/load with checksum envelope + `.bak` recovery (`SaveManager.gd`)
- [x] Save chaos tests (`npm run godot:test:save`)
- [x] Import SFX from `public/audio/sfx/` and music
- [x] Drag chain with path interpolation (Android low-FPS fix)
- [x] AudioManager (SFX pool + music)
- [x] Android export preset + `scripts/godot-android-export.sh`

### Meta / platform — done

- [x] Bonuses (shuffle, destroy, explosion) — `BonusManager.gd` + HUD
- [x] Daily quests — `DailyQuestManager.gd` + `DailyQuests.tscn`
- [x] Wheel — `WheelManager.gd` + `Wheel.tscn` (logic done; canvas animation partial)
- [x] Achievements UI — `Achievements.tscn` + save via `PlayerProgress`
- [x] i18n UA/RU/EN — 285 keys — `I18nManager.gd`
- [x] Themes dawn/dusk tokens + menu backgrounds — `ThemeManager.gd`, `assets/ui/backgrounds/`
- [x] Leaderboard stub — `LeaderboardService.gd` + offline queue in save
- [x] Tile merge pulse — `Tile.gd` tween
- [x] **Legacy save import** — `LegacySaveMigration.gd` + Android `LostNumberMigration` plugin + Settings → Import
- [x] Boot → App shell, `ScreenRouter` back-stack + transitions
- [x] Dark Neon Fantasy visual foundation (`ThemeTokens`, `LnUi`, `NeonButton`, `BackgroundLayer`)

### Remaining (visual / deferred)

Aligned with `VISUAL_PORT_MAP.md`:

- [ ] Full neon icon UI polish (most icons ported)
- [ ] Wheel canvas animation (`WheelCanvas.gd` partial)
- [ ] Chain-sum HUD + preview bubble (Game screen)
- [ ] Victory overlay, confirm dialog, toast
- [ ] Menu skin variants (titleFrame arc/diamond, chip shapes)
- [ ] Achievements / Daily visual polish (card layouts partial)
- [ ] Freeze bonus + pressure transfer (deferred from rules)
- [ ] Play Games / Firebase leaderboard HTTP wiring (stub only)

## Intentionally deferred

Per `GAME_RULES.md` and product scope:

- Freeze tiles, pressure transfer
- Monetization (ads, IAP, premium, tournaments)
- Cloud save (Phase 6 Firebase — not started; see `docs/PHASES.md`)
- Network features requiring backend budget

## Running

```bash
# once per clone / after adding new class_name scripts
npm run godot:import

godot4 --path godot

npm run godot:test:all
```

## Save format

Godot uses its own JSON schema (`version: 2` inside `envelope_version: 1` with `data_json` + SHA-256 `checksum`). It is **not** byte-compatible with web `localStorage.lostNumberSave` v2.

One-time import is **done**: `LegacySaveMigration.gd` (startup + Settings → Import) and the `LostNumberMigration` Android plugin. Details: `godot/docs/LEGACY_SAVE_MIGRATION.md`, `docs/en/DECISIONS.md`.
