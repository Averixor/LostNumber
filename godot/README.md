# Lost Number — Godot 4 MVP

Offline puzzle port from the HTML/Capacitor build. Core gameplay only.

## Requirements

- Godot **4.3+**
- Portrait 420×920 (configured in `project.godot`)

## Open project

```bash
godot4 --path godot
```

Or import `godot/project.godot` from Godot Editor.

## MVP features

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

1. Import SFX from `../public/audio/sfx/`
2. Android export template + touch polish
3. Level complete overlay on save resume (pending transition)
