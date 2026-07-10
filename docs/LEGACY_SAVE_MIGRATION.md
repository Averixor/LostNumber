# Legacy save migration (Capacitor → Godot)

## Startup order

1. Godot native save (`user://lost_number_save.json` via `SaveManager`)
2. Legacy file `user://legacy_capacitor_save.json` or `user://imported_save.json`
3. Android plugin `LostNumberMigration.exportLegacySave()` (files dir, shared_prefs, WebView LevelDB heuristic)
4. New game

## File import (desktop / manual)

1. Export JSON from Capacitor Web (`localStorage` key **`lostNumberSave`**) or copy an old flat save.
2. Place as `legacy_capacitor_save.json` in Godot `user://`, **or** use **Settings → Import legacy save** (desktop file picker).
3. On success the file is renamed to `*.imported` so it is not imported twice.

## Android plugin

Location: `godot/android/plugins/LostNumberMigrationPlugin/` (Java/AAR sources). Godot discovers the plugin via **`godot/android/plugins/LostNumberMigration.gdap`** — `.gdap` files must sit directly in `android/plugins/`, not in a subdirectory (Godot 4.5 export only lists top-level `*.gdap`).

| Artifact                                | Purpose                         |
| --------------------------------------- | ------------------------------- |
| `../LostNumberMigration.gdap`           | Godot export registration       |
| `LostNumberMigrationPlugin-release.aar` | Built plugin binary (see below) |
| `build-aar.sh`                          | Rebuild AAR after Java changes  |

The AAR manifest must declare v2 plugin metadata (`org.godotengine.plugin.v2.LostNumberMigration` → `com.averixor.lostnumber.LostNumberMigrationPlugin`) so `Engine.has_singleton("LostNumberMigration")` is true at runtime.

### What the plugin scans (in order)

1. `files/lostnumber_legacy_export.json` (cached export / manual adb push)
2. `files/legacy_capacitor_save.json`, `files/imported_save.json`, `files/lostNumberSave.json`
3. `shared_prefs/*.xml` — Capacitor `@capacitor/preferences` or mirrored keys containing `lostNumberSave`
4. `app_webview/**/Local Storage/leveldb/*.ldb` — best-effort string search for `lostNumberSave` JSON (fragile; may fail on some WebView versions)

On success, JSON is cached to `files/lostnumber_legacy_export.json` and returned to GDScript.

### Build the AAR

Prerequisites: Godot Android export template present (`godot/android/build/libs/release/godot-lib.template_release.aar`), JDK 17, Android SDK.

```bash
# After at least one Godot Android import/export:
npm run godot:import
bash godot/android/plugins/LostNumberMigrationPlugin/build-aar.sh
```

Or manually:

```bash
godot/android/build/gradlew -p godot/android/plugins/LostNumberMigrationPlugin assembleRelease
cp godot/android/plugins/LostNumberMigrationPlugin/build/outputs/aar/*-release.aar \
   godot/android/plugins/LostNumberMigrationPlugin/LostNumberMigrationPlugin-release.aar
```

Enable in export: `export_presets.cfg` → `plugins/LostNumberMigration=true` on both Android presets (Godot stores one boolean per plugin name, not `plugins/enabled=PackedStringArray(...)`).

### Test on device

**Option A — adb push (always works, no old app required):**

```bash
adb push my-save.json /data/data/com.averixor.lostnumber/files/lostnumber_legacy_export.json
# Launch app → startup migration OR Settings → Import legacy save
```

**Option B — upgrade from Capacitor build:**

Install old Capacitor APK with existing save, then install Godot APK/AAB **without clearing data**. Tap **Settings → Import legacy save** (calls plugin first, then `user://` files).

**Option C — dev package:**

Same paths under `/data/data/com.averixor.lostnumber.dev/files/`.

### GDScript API

- Autoload `LegacySaveMigration` calls plugin on startup when no Godot save exists.
- `try_manual_import()` — Settings button: plugin → `user://imported_save.json` → `user://legacy_capacitor_save.json`.
- `Engine.has_singleton("LostNumberMigration")` is `true` when AAR is bundled in the export.

## Field mapping (JS v2 → Godot)

| JS (Capacitor)      | Godot                                            |
| ------------------- | ------------------------------------------------ |
| `currentLevel`      | `current_level`                                  |
| `xpMultiplier`      | `xp_multiplier`                                  |
| `bonusInventory`    | `bonus_inventory`                                |
| `pendingTransition` | `pending_transition`                             |
| `wheelSpinsToday`   | `wheel_spins_today`                              |
| `lastWheelDay`      | `last_wheel_day`                                 |
| `grid` v2 cells     | flat int grid                                    |
| `stats`             | `progress.stats`                                 |
| `achievements`      | `progress.achievements` (camelCase → snake_case) |

Godot flat saves (snake_case, `version: 2`) import without remapping.

## JS reference

Web save key: `localStorage.lostNumberSave` (`js/system/platform/storage.js` / `js/app/persistence/save-load.js`).
