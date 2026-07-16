---
language: en
title: Lost Number — Godot 4 Migration Plan
version: 2.1.6
last_updated: 2026-07-10
---

# Godot 4 Migration Plan

Lost Number **2.1.6** ships on **Godot 4.7** / GDScript only. The former browser/JS prototype has been removed from the repo; the table below is kept as a historical migration map.

## Architecture map

| JavaScript (vanilla)                      | Godot                                                    |
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

## Completed (parity checklist)

| Area                                                                                           | Status  |
| ---------------------------------------------------------------------------------------------- | ------- |
| `Rules.gd` — chain validation 1:1 with `rules.js`                                              | Done    |
| 5×8 grid (weighted spawn, min tile by level)                                                   | Done    |
| Drag chain (8-neighbor, backtrack one step)                                                    | Done    |
| Merge + gravity + spawn                                                                        | Done    |
| Level target / complete / carry                                                                | Done    |
| 40 algorithmically generated initial configs + procedural branch from index 40+                | Done    |
| XP base by chain length                                                                        | Done    |
| Save/load with checksum envelope + `.bak` recovery                                             | Done    |
| Save chaos tests (`npm run godot:test:save`)                                                   | Done    |
| SFX and music import                                                                           | Done    |
| Drag path interpolation (Android low-FPS fix)                                                  | Done    |
| `AudioManager` (SFX pool + music)                                                              | Done    |
| Android export preset + `scripts/godot-android-export.sh`                                      | Done    |
| Bonuses (shuffle, destroy, explosion)                                                          | Done    |
| Daily quests                                                                                   | Done    |
| Wheel (logic; canvas animation partial)                                                        | Partial |
| Achievements UI + save via `PlayerProgress`                                                    | Done    |
| i18n UA/RU/EN (285 keys)                                                                       | Done    |
| Themes dawn/dusk tokens                                                                        | Done    |
| Leaderboard stub + offline queue in save                                                       | Done    |
| Tile merge pulse tween                                                                         | Done    |
| Legacy save migration (file + Android plugin)                                                  | Done    |
| **Dark Neon Fantasy** visual redesign (`ThemeTokens`, `LnUi`, `NeonButton`, `BackgroundLayer`) | Done    |
| MainMenu web parity (dock, quick-row, SVG icons, FeatureStubOverlay)                           | Done    |
| Boot splash with real preload (`SaveManager` + App)                                            | Done    |
| `ScreenRouter` back-stack + fade transitions                                                   | Done    |

## Remaining work

| Item                                                     | Priority | Notes                                                                   |
| -------------------------------------------------------- | -------- | ----------------------------------------------------------------------- |
| Full neon icon UI parity with JS                         | Medium   | Most icons ported; polish gaps remain                                   |
| Wheel canvas animation                                   | Medium   | `WheelCanvas.gd` partial; web arrow/highlight polish                    |
| Chain-sum HUD + preview bubble                           | Medium   | Logic in `GameHud.gd` / `Board.gd` — PARTIAL; visual acceptance pending |
| Freeze bonus + pressure transfer                         | Low      | Deferred from MVP rules                                                 |
| Victory overlay, confirm dialog, toast                   | Medium   | Web `overlays.css` equivalents                                          |
| Menu skin variants (titleFrame arc/diamond, chip shapes) | Low      | Tokens TODO in `ThemeManager`                                           |
| Achievements / Daily visual polish                       | Medium   | Card layouts partial                                                    |
| Play Games / Firebase leaderboard HTTP                   | Low      | Stub only; offline queue exists                                         |
| Twilight theme art                                       | Low      | In code; hidden from UI until art ships                                 |

## Intentionally deferred

Per `GAME_RULES.md` and product scope:

- Monetization (ads, IAP, premium, tournaments)
- Cloud save (Phase 6 Firebase — not started; see `docs/PHASES.md`)
- Network features requiring backend budget

## What can be removed or demoted

| Path                                                  | Recommendation                                                             |
| ----------------------------------------------------- | -------------------------------------------------------------------------- |
| `js/`, `css/`, `index.html`                           | **Removed** from repo (July 2026); see `docs/archive/` for historical maps |
| `android/` (Capacitor)                                | **Removed** — only `android/keystore/` remains for Godot signing           |
| `godot/assets/icons/neon/` (duplicate tree)           | **Removed** — canonical icons at `godot/assets/ui/icons/neon/`             |
| `assets/store/*` in AAB                               | **Excluded** via `export_presets.cfg` `exclude_filter`                     |
| Floating background numbers (`createFloatingNumbers`) | **Removed** from product (Phase 5.6)                                       |

Do **not** treat `docs/archive/` migration maps as current ship requirements — use `docs/en/VISUAL_TARGET.md` for acceptance.

## Running Godot

```bash
# Once per clone / after adding new class_name scripts
godot4 --path godot --import --headless

# Editor
godot4 --path godot

# Tests
npm run godot:test:all
godot4 --path godot --headless --script res://scripts/tests/run_rules_tests.gd
```

## Save format note

Godot uses its own JSON schema (`version: 2` inside an `envelope_version: 1` wrapper with `data_json` + SHA-256 `checksum`). It is **not** byte-compatible with web `localStorage.lostNumberSave` v2. One-time import is handled by `LegacySaveMigration.gd` and the `LostNumberMigration` Android plugin — see [DECISIONS.md](./DECISIONS.md) and `docs/LEGACY_SAVE_MIGRATION.md`.

## Visual port tracker

Detailed screen-by-screen status: `docs/archive/VISUAL_PORT_MAP.md` (historical).
