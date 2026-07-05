# Lost Number — Godot → Google Play

Godot 4 build is the **primary** Android ship target. Capacitor/WebView remains a legacy reference path.

## Quick start

```bash
# 1. Import project (first time)
npm run godot:import

# 2. Run tests
npm run godot:test:all

# 3. Play in editor (Boot → App → MainMenu)
godot4 --path godot
```

Entry flow: **`Boot.tscn`** (main_scene) → **`App.tscn`** → screens mounted by **`ScreenRouter`** autoload. Navigation uses back-stack (`push` / `go_back`); Android back handled in `App.gd`.

## Android build

Requirements: Godot 4.3+, JDK 17, Android SDK (API 35), `android/keystore.properties` for release.

```bash
chmod +x scripts/godot-android-export.sh

# Debug APK on phone
npm run godot:android:debug
adb install -r build/godot/android/lost-number-debug.apk

# Release AAB for Play Console
npm run godot:android:release
# → build/godot/android/lost-number.aab
```

Export templates are downloaded automatically on first build if missing.

## Play Console upload

| Field       | Value                                                          |
| ----------- | -------------------------------------------------------------- |
| Package     | `com.averixor.lostnumber`                                      |
| Version     | `2.1.4` (versionCode 14)                                       |
| AAB         | `build/godot/android/lost-number.aab`                          |
| Privacy URL | `https://averixor.github.io/LostNumber/privacy.html`           |
| Store texts | `godot/docs/store-listing/` or `store/PLAY_CONSOLE_LISTING.md` |

Full checklist: [docs/PLAY_STORE.md](../docs/PLAY_STORE.md) — same listing assets; only the build artifact path changes.

## What changed vs Capacitor

| Area        | Capacitor (legacy)              | Godot (ship)                                                           |
| ----------- | ------------------------------- | ---------------------------------------------------------------------- |
| Touch input | WebView + JS pointer events     | Native `_input` + path interpolation in `Board.gd`                     |
| Audio       | Web Audio API                   | `AudioStreamPlayer` in `AudioManager.gd`                               |
| Save        | `localStorage`                  | `user://lost_number_save.json` + legacy import (`LegacySaveMigration`) |
| Navigation  | `ScreenManager` + DOM screens   | `ScreenRouter` + back-stack, fade transitions                          |
| UI shell    | `#appBackground` + CSS          | `App.tscn` + `BackgroundLayer`, `NeonButton`, tokens                   |
| Package     | `android/app/build/outputs/...` | `build/godot/android/...`                                              |

## Current scope (Godot 2.1.4)

**Gameplay:** 5×8 grid, chain rules, merge/gravity/spawn, levels, XP, save (checksum + `.bak`), bonuses, wheel/daily/achievements logic.

**UI:** Boot splash, App shell, ScreenRouter (fade/slide), BackgroundLayer, NeonButton, GameHud, Tile/ChainLineLayer, wheel canvas, achievement/daily cards.

**Legacy save:** Capacitor/Web JSON → Godot via `LegacySaveMigration` (file + Settings import; Android plugin PARTIAL). See `godot/docs/LEGACY_SAVE_MIGRATION.md`.

**Pre-AAB gate:** `npm run godot:verify:aab` (tests + release:check + AAB export + artifact checks).

Visual parity still open: menu dock/quick-row, chain-sum HUD, stats screen — see `godot/docs/VISUAL_PORT_MAP.md`.

## Store graphics vs in-game assets

| Purpose              | Location                                                | In AAB?                                                                       |
| -------------------- | ------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Play Console listing | `store/` (repo root)                                    | No                                                                            |
| Godot store copies   | `godot/assets/store/`                                   | **No** — excluded via `exclude_filter=assets/store/*` in `export_presets.cfg` |
| In-game UI           | `godot/assets/ui/` (backgrounds, buttons, icons, tiles) | Yes — referenced from `.tscn`                                                 |

Do not reference `assets/store/*` from game scenes; use `assets/ui/` only.

## Touch fix

`Board.gd` samples cells along the finger path (`_collect_cells_along_pointer_path`) so low-FPS frames do not skip tiles. This is the Godot equivalent of the JS hard chain patch.
