# Migration from JS to Godot

Lost Number **2.0** — Godot 4 / GDScript. The HTML/Capacitor build remains a reference prototype.

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
- [ ] Full parity: bonuses, wheel, daily, achievements, i18n

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

Godot MVP uses a new JSON schema (`version: 1`), not compatible with `localStorage` `lostNumberSave` v2 from the web build. A one-time import script can be added later if needed.
