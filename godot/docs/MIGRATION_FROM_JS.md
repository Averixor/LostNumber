# Migration from JS to Godot

Lost Number **2.1.4** — Godot 4 / GDScript. The HTML/Capacitor build remains a reference prototype.

## Architecture map

| JS (vanilla)                              | Godot MVP                                   |
| ----------------------------------------- | ------------------------------------------- |
| `js/core/rules.js`                        | `scripts/core/Rules.gd`                     |
| `js/game/GameCore.js` + `grid-physics.js` | `scripts/core/BoardLogic.gd`                |
| `js/game/state.js` (levels/spawn)         | `scripts/core/LevelManager.gd`              |
| `js/game/state.js` (session)              | `scripts/core/GameState.gd`                 |
| `js/app/persistence/save-load.js`         | `scripts/managers/SaveManager.gd`           |
| `GridManager` + grid render               | `scripts/game/Board.gd` + `Tile.gd`         |
| `LostNumberGame`                          | `scripts/game/Game.gd` + `scenes/Game.tscn` |
| `js/system/platform/audio.js`             | `scripts/managers/AudioManager.gd` (stub)   |
| `menu.js`                                 | `scenes/MainMenu.tscn`                      |

## Parity checklist (MVP)

- [x] `Rules.gd` — chain validation 1:1 with `rules.js`
- [x] 5×8 grid generation (weighted spawn, min tile by level)
- [x] Drag chain (8-neighbor, backtrack one step)
- [x] Merge + gravity + spawn
- [x] Level target / complete / carry
- [x] XP base by chain length
- [x] Save/load with checksum envelope + `.bak` recovery (`SaveManager.gd`)
- [x] Save chaos tests (`npm run godot:test:save`)
- [x] Import SFX from `public/audio/sfx/` and music
- [x] Drag chain with path interpolation (Android low-FPS fix)
- [x] AudioManager (SFX pool + music)
- [x] Android export preset + `scripts/godot-android-export.sh`
- [x] Bonuses (shuffle, destroy, explosion) — `BonusManager.gd` + HUD
- [x] Daily quests — `DailyQuestManager.gd` + `DailyQuests.tscn`
- [x] Wheel — `WheelManager.gd` + `Wheel.tscn` (logic; no canvas animation yet)
- [x] Achievements UI — `Achievements.tscn` + save via `PlayerProgress`
- [x] i18n UA/RU/EN — `I18nManager.gd` autoload
- [x] Themes dawn/dusk tokens — `ThemeManager.gd` (colors; art backgrounds deferred)
- [x] Leaderboard stub — `LeaderboardService.gd` + offline queue in save
- [x] Tile merge pulse — `Tile.gd` tween
- [ ] Full neon icon UI parity with JS
- [ ] Wheel canvas animation
- [ ] Freeze bonus + pressure transfer
- [ ] Web save import (`localStorage` v2 → Godot)
- [ ] Play Games / Firebase leaderboard HTTP wiring

## Intentionally deferred

See `GAME_RULES.md` — bonuses, wheel, daily, achievements, i18n, themes, monetization.

## Running

```bash
# once per clone / after adding new class_name scripts
godot4 --path godot --import --headless

godot4 --path godot

godot4 --path godot --headless --script res://scripts/tests/run_rules_tests.gd
```

## Save format

Godot MVP uses its own JSON schema (`version: 2` inside an `envelope_version: 1` wrapper with `data_json` + `checksum`), not compatible with `localStorage` `lostNumberSave` v2 from the web build. A one-time import script can be added later if needed.
