# Lost Number — Godot → Google Play

Godot 4 build replaces the Capacitor/WebView Android path. Native input fixes chain lag on phones.

## Quick start

```bash
# 1. Import project (first time)
godot4 --path godot --import --headless

# 2. Run tests
godot4 --path godot --headless --script res://scripts/tests/run_rules_tests.gd

# 3. Play in editor
godot4 --path godot
```

## Android build

Requirements: Godot 4.3+, JDK 17, Android SDK (API 35), `android/keystore.properties` for release.

```bash
chmod +x scripts/godot-android-export.sh

# Debug APK on phone
./scripts/godot-android-export.sh debug
adb install -r build/godot/android/lost-number-debug.apk

# Release AAB for Play Console
./scripts/godot-android-export.sh release
# → build/godot/android/lost-number.aab
```

Export templates are downloaded automatically on first build if missing.

## Play Console upload

| Field       | Value                                                          |
| ----------- | -------------------------------------------------------------- |
| Package     | `com.averixor.lostnumber`                                      |
| Version     | `2.0.0` (versionCode 2)                                        |
| AAB         | `build/godot/android/lost-number.aab`                          |
| Privacy URL | `https://averixor.github.io/LostNumber/privacy.html`           |
| Store texts | `godot/docs/store-listing/` or `store/PLAY_CONSOLE_LISTING.md` |

Full checklist: [docs/PLAY_STORE.md](../docs/PLAY_STORE.md) — same listing assets; only the build artifact path changes.

## What changed vs Capacitor

| Area        | Capacitor (1.x)                 | Godot (2.0)                                        |
| ----------- | ------------------------------- | -------------------------------------------------- |
| Touch input | WebView + JS pointer events     | Native `_input` + path interpolation in `Board.gd` |
| Audio       | Web Audio API                   | `AudioStreamPlayer` in `AudioManager.gd`           |
| Save        | `localStorage`                  | `user://lost_number_save.json`                     |
| Package     | `android/app/build/outputs/...` | `build/godot/android/...`                          |

## MVP scope (Godot 2.0)

Included: 5×8 grid, chain rules, merge/gravity/spawn, levels, XP, save, menu, settings, sound/music, Android back button.

Deferred (same as `godot/docs/GAME_RULES.md`): bonuses, wheel, daily quests, achievements UI, i18n, themes.

## Touch fix

`Board.gd` samples cells along the finger path (`_collect_cells_along_pointer_path`) so low-FPS frames do not skip tiles. This is the Godot equivalent of the JS hard chain patch.
