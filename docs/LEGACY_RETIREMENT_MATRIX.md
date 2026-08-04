# Legacy retirement matrix (Stage 3)

## KEEP / ARCHIVE / REMOVE — safe legacy actions

Legacy in this project is anything kept only to allow users upgrading from old builds (Web/JS/Capacitor) to load or import old saves into the Godot-native save format.

Security rule: in this PR we do not introduce any code deletion. `REMOVE` is documented only for items that were already removed from the repo (or exist only as historical `docs/archive/` content).

| Legacy object | Status | Why it is legacy | KEEP/ARCHIVE verification | Next step (if something changes) |
|---|---|---|---|---|
| `godot/scripts/managers/LegacySaveMigration.gd` | KEEP | Startup file-based migration from old Capacitor/Web exports into `user://lost_number_save.json` | `npm run godot:test:save` (if available) and Godot smoke that covers minimal legacy save import | If legacy JSON shapes change: extend mapping, add a test vector (do not break old ones) |
| `godot/android/plugins/LostNumberMigrationPlugin/` + `LostNumberMigration.gdap` | KEEP | Android-side migration helper for older saves (file + heuristics) | Export presets include plugin; device import flow works: Settings -> Import legacy save | Only extend scanning if it is still needed; keep the fallback order intact |
| `docs/LEGACY_SAVE_MIGRATION.md` | KEEP | Source of truth for migration artifacts and on-device test procedure | `npm run release:check` (format drift) | Keep this doc aligned with file paths and plugin scan order |
| `settings_import_legacy_stub` (i18n key) + Settings stub logic | KEEP | Honest UX stub (button exists) without mutating saves (until full import UX is shipped) | Verify `Settings` button shows the stub text and does not write to save on tap | When full import UX lands, replace stub key and document migration behavior |
| Android WebView heuristic scanning (`leveldb/*.ldb` string search) | KEEP | Best-effort recovery for WebView-based old saves (can be fragile per WebView versions) | Validate on at least 1 device / WebView version: manual legacy import finds or safely reports missing data | If it starts producing wrong mappings: disable only that heuristic, keep rest |
| `docs/archive/*` (historical migration docs) | ARCHIVE | Historical context only; not the active implementation contract | Only doc link checks (release:check) | Keep as read-only history; no new instructions here |
| Web/JS/Capacitor runtime stack (build/runtime code) | REMOVE (already removed) | Primary ship path is Godot 4 Android AAB; Web/JS/Capacitor stack deleted July 2026 | Ensure active ship path is Godot-only (`docs/ANDROID.md`) and legacy import still works for old saves | If anything legacy-related reappears: move it to KEEP instead of reintroducing runtime |

## Safety checklist (for any future changes)

1. No `REMOVE` of anything that is still imported/used by Godot/Android export.
2. Keep legacy import order consistent: native save -> legacy files -> Android plugin -> game.
3. Update this matrix only together with a real behavioral change (docs-only PR is allowed if it corrects documentation drift).

