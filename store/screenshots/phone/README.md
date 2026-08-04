# Phone screenshots (portrait 1080×1920)

Play Console requires at least 2 phone screenshots.

## Current files

| File                    | Role               |
| ----------------------- | ------------------ |
| `01-menu-dark.png`      | Menu / branding    |
| `02-gothic-style.png`   | Gothic style board |
| `03-levels-bonuses.png` | Levels / bonuses   |
| `04-offline-calm.png`   | Offline / calm     |

These are **listing assets** for Closed testing. Before **Production**, replace with real **device** captures (Main Menu, Game, Settings) from an arm64 phone running the `2.1.7` build.

## Capture on device (preferred)

1. `npm run godot:android:debug` → install APK.
2. Open Menu / Game / Settings; system screenshot (portrait).
3. Crop/resize to **1080×1920** PNG; overwrite files above.
4. `npm run store:verify`.

## Headless engine capture (optional QA)

Script: `godot/scripts/tests/capture_game_visual.gd` via `scripts/run-godot-isolated.sh` at 420×920, then upscale with ImageMagick (`convert … -resize 1080x1920!`).  
Note: Flatpak Godot on some hosts may hang in headless capture — use device path if timeout.

See also: `docs/en/VISUAL_TARGET.md`, `docs/CLOSED_TESTING_RUNBOOK.md`.
