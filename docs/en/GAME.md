---
language: en
title: Lost Number — Game Design & Mechanics
version: 2.1.6
last_updated: 2026-07-10
---

# Lost Number — Game Design & Mechanics

Lost Number is an offline 2D number-chain puzzle for casual players (3+). The player connects adjacent tiles on a grid to build valid chains, merge them into higher powers of two, and reach level targets to progress.

**Reference implementation:** Godot 4 (`godot/scripts/core/Rules.gd`) must match `js/core/rules.js` 1:1.

## Goal

Build chains of tiles whose **total sum is a power of two** and exceeds the first tile in the chain. When the sum meets or exceeds the **level target**, the level completes. Progression doubles the target each level (64 → 128 → 256 → …).

## Grid

| Property    | Value                                    |
| ----------- | ---------------------------------------- |
| Size        | **5 columns × 8 rows**                   |
| Tile values | Powers of two (2, 4, 8, 16, …)           |
| Adjacency   | **8 directions** (orthogonal + diagonal) |

## Chain building rules

While dragging a chain (minimum 2 cells), each new tile must satisfy **one** of:

1. **Same** — next value equals the previous value in the chain.
2. **Double** — next value equals `previous × 2`.
3. **Sum match** — current partial sum is a power of two, the next value equals that sum, and `sum >= previous`.

The player can **backtrack one step** while dragging (remove the last tile from the chain).

## Finish rule

A chain can be committed when:

- Length ≥ 2
- Total sum is a power of two
- Total sum **>** first number in the chain

## After a valid chain

1. All selected cells except the **anchor** (last cell) are cleared.
2. The anchor receives the result tile:
   - If `sum >= level target` → result is the **target** (level complete); surplus converts to XP.
   - Otherwise → result is **sum**.
3. **Gravity** — tiles fall down per column.
4. **Spawn** — empty cells at the top receive new weighted-random values.
5. If any cell equals the **level target** → level-complete overlay.
6. On the next level: target ×2; the previous target becomes a **carry** tile on the new board.

## Level progression

### Initial levels (1–40)

The first **40** level configs are **algorithmically generated at init** via `_generate_manual_levels(40)` (`LevelManager.MANUAL_LEVEL_COUNT := 40` in `godot/scripts/core/LevelManager.gd`). Targets double each level:

| Level    | Target       |
| -------- | ------------ |
| 1        | 64           |
| 2        | 128          |
| 3        | 256          |
| n (≤ 40) | 64 × 2^(n−1) |

Spawn weights and minimum tile values scale with level (`LevelManager.gd`).

### Endless procedural (index 40+)

From zero-based index 40, `get_level_config()` uses a separate procedural branch — deterministic from level index (no random). `current_level` in save drives resume. High levels (50, 100, 500+) are **not proven safe** until dedicated tests land — see [AUDIT_MAIN_2026-07-10.md](./AUDIT_MAIN_2026-07-10.md).

## XP system

Base XP by chain length:

| Chain length | XP  |
| ------------ | --- |
| 2            | 4   |
| 3            | 8   |
| 4            | 12  |
| 5            | 18  |
| 6+           | 25  |

Additional **surplus XP** is awarded when `sum > target` on level completion.

## Controls

| Platform         | Input                                                                               |
| ---------------- | ----------------------------------------------------------------------------------- |
| Touch (Android)  | Drag across adjacent tiles to build a chain; release to commit if valid             |
| Desktop / editor | Mouse drag equivalent to touch                                                      |
| Navigation       | Android **Back** handled by `App.gd` → `ScreenRouter.go_back()`                     |
| Menus            | `ScreenRouter.push()` / `go_back()` — no direct `change_scene_to_file` from screens |

Low-FPS Android devices use path interpolation during drag to keep chain selection responsive.

## Meta features (beyond core MVP)

Implemented in Godot with varying visual polish:

| Feature                               | Status                                                      |
| ------------------------------------- | ----------------------------------------------------------- |
| Bonuses (shuffle, destroy, explosion) | Logic + HUD — `BonusManager.gd`                             |
| Daily quests                          | Logic + screen — `DailyQuestManager.gd`, `DailyQuests.tscn` |
| Wheel of fortune                      | Logic — `WheelManager.gd`; canvas animation partial         |
| Achievements                          | Save via `PlayerProgress`; UI partial                       |
| Stats / About                         | Minimal screens with back-stack navigation                  |
| Themes (dawn/dusk)                    | `ThemeManager.gd`; twilight in code, hidden from UI toggle  |
| i18n (UA / RU / EN)                   | 285 keys per locale — `I18nManager.gd`                      |

## Not in scope (deferred)

- Freeze tiles, pressure transfer
- Login, premium, tournaments, cloud save
- Ads, in-app purchases
- Play Games / Firebase leaderboard HTTP wiring (stub only)

## Audio feedback

Semantic events in `AudioManager.gd`: `button_click`, `tile_select`, `chain_valid`, `level_complete`, `wheel_spin`, and others. Assets imported from `public/audio/` into `godot/assets/audio/`.
