# Game Rules (Lost Number MVP)

Reference: `js/core/rules.js` — Godot implementation must match 1:1.

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

## Levels (MVP)

| Level | Target |
|-------|--------|
| 1     | 64     |
| 2     | 128    |
| 3     | 256    |
| n     | 64 × 2^(n-1) |

## XP (base by chain length)

| Length | XP |
|--------|-----|
| 2      | 4  |
| 3      | 8  |
| 4      | 12 |
| 5      | 18 |
| 6+     | 25 |

Surplus XP when `sum > target` on level complete.

## Not in MVP

- Freeze tiles, pressure transfer, shuffle/destroy/explosion bonuses
- Daily quests, achievements, wheel, themes
- Login, premium, tournaments, cloud save, ads, IAP
