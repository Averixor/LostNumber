# Game Rules (Lost Number)

Reference: `js/core/rules.js` — Godot implementation must match 1:1 (`scripts/core/Rules.gd`).

## Grid

- Size: **5 columns × 8 rows**
- Values: powers of two (2, 4, 8, …)
- Adjacency: **8 directions** (orthogonal + diagonal)

## Chain rules

While building a chain (minimum 2 cells):

1. **Same**: next value equals the previous value in the chain.
2. **Double**: next value equals `previous × 2`.
3. **Sum match**: current partial sum is a power of two, next value equals that sum, and `sum >= previous`.

## Finish rule

A chain can be committed when:

- Length ≥ 2
- Total sum is a power of two
- Total sum **>** first number in the chain

## After a valid chain

1. All selected cells except the **anchor** (last cell) are cleared.
2. Anchor receives the result tile:
   - If `sum >= level target` → result is **target** (level complete), surplus goes to XP.
   - Else → result is **sum**.
3. **Gravity** — tiles fall down per column.
4. **Spawn** — empty cells at top get new weighted random values.
5. If any cell equals **level target** → level complete overlay.
6. On next level: target ×2, previous target becomes **carry** tile on the new board.

## Level progression

### Initial levels (1–40)

The first **40** level configs are **algorithmically generated at init** via `_generate_manual_levels(40)` (`LevelManager.MANUAL_LEVEL_COUNT := 40`). There is no hand-authored preset table in the repo. Targets double each level starting at 64:

| Level    | Target       |
| -------- | ------------ |
| 1        | 64           |
| 2        | 128          |
| 3        | 256          |
| n (≤ 40) | 64 × 2^(n−1) |

Spawn weights and minimum tile values scale with level index.

### Endless procedural (index 40+)

From **zero-based index 40**, `get_level_config()` uses a separate procedural branch (`_procedural_target()`, `_build_level_numbers()`, `_generate_new_numbers()`):

- Target is deterministic from level index (no `Math.random()`).
- `current_level` in save drives resume; target is recomputed on load.
- High indices (50, 100, 200, 500+) are **not proven safe** until dedicated `LevelManager` tests and a cap-before-overflow fix land — see [AUDIT_MAIN_2026-07-10.md](../../docs/en/AUDIT_MAIN_2026-07-10.md).

Parity with `js/game/state.js` (`MANUAL_LEVEL_COUNT = 40`).

## XP (base by chain length)

| Length | XP  |
| ------ | --- |
| 2      | 4   |
| 3      | 8   |
| 4      | 12  |
| 5      | 18  |
| 6+     | 25  |

Surplus XP when `sum > target` on level complete.

## Meta features (implemented in Godot)

Core gameplay rules above are MVP; the following meta systems **are implemented** in Godot (visual polish varies — see `VISUAL_PORT_MAP.md`):

| Feature                               | Godot module                                                |
| ------------------------------------- | ----------------------------------------------------------- |
| Bonuses (shuffle, destroy, explosion) | `BonusManager.gd` + `GameHud`                               |
| Daily quests                          | `DailyQuestManager.gd`, `DailyQuests.tscn`                  |
| Wheel of fortune                      | `WheelManager.gd`, `Wheel.tscn` (canvas animation partial)  |
| Achievements                          | `Achievements.tscn`, save via `PlayerProgress`              |
| Stats / About                         | `Stats.tscn`, `About.tscn`                                  |
| Themes (dawn/dusk)                    | `ThemeManager.gd` (twilight in code, hidden from UI toggle) |
| i18n (UA / RU / EN)                   | `I18nManager.gd` — 285 keys per locale                      |

## Intentionally deferred

- Freeze tiles, pressure transfer
- Login, premium, tournaments, cloud save
- Ads, in-app purchases
- Play Games / Firebase leaderboard HTTP wiring (stub only — `LeaderboardService.gd`)
