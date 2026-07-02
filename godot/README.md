# Lost Number — Godot 4 MVP

Offline puzzle port from the HTML/Capacitor build. Core gameplay only.

## Requirements

- Godot **4.3+**
- Portrait 420×920 (configured in `project.godot`)

## Open project

First-time import (registers `class_name` globals):

```bash
godot4 --path godot --import --headless
```

Then open or run:

```bash
godot4 --path godot
```

## Tests

```bash
godot4 --path godot --headless --script res://scripts/tests/run_rules_tests.gd
```

Expected: `Rules tests passed`, exit code `0`.

- 5×8 grid, drag chain, rules validation
- Merge, gravity, spawn
- Level targets (64 → 128 → …), carry tile, XP
- Save/load (`user://`)
- Main menu, settings (sound/music)

## Structure

```
scripts/core/     Rules, BoardLogic, LevelManager, GameState
scripts/game/     Game, Board, Tile
scripts/managers/ SaveManager, SettingsManager, AudioManager (autoloads)
scenes/           MainMenu, Game, Settings
docs/             GAME_RULES.md, MIGRATION_FROM_JS.md
```

## Tests

```bash
godot4 --path godot --headless --script res://scripts/tests/run_rules_tests.gd -- --test-rules
```

## Next steps

1. Play Games / Firebase leaderboard HTTP wiring
2. Wheel canvas animation + neon icon UI
3. Web save import script
4. Real background art from `assets/images/`
