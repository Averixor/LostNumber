# Lost Number — Production Handoff (Ideal Build)

**Package:** `com.averixor.lostnumber`  
**Version:** `2.1.6` (versionCode `16`)  
**Audience:** Casual 3+, offline puzzle  
**Primary Android:** Godot 4.7 native (`build/android/lost-number.aab`)

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Google Play  ←  lost-number.aab (Godot)                │
├─────────────────────────────────────────────────────────┤
│  godot/          Boot→App shell, ScreenRouter, gameplay │
│  android/        Release keystore only (Godot signing)  │
│  store/          Play Console listing + graphics        │
│  privacy.html    Play Store privacy policy (static)   │
└─────────────────────────────────────────────────────────┘
```

| Layer           | Stack                            | Notes                                   |
| --------------- | -------------------------------- | --------------------------------------- |
| Gameplay (ship) | Godot 4.7 GDScript               | Boot→App→screens; back-stack navigation |
| Save            | `user://` JSON (Godot)           | Checksum + `.bak` rollback              |
| Network         | None                             | GDPR-friendly: no tracking, no PII      |
| Compliance      | `privacy.html`, Play Data Safety | Offline-only data                       |

---

## Clarifications (STEP0 answers)

| Question                    | Answer                                                              |
| --------------------------- | ------------------------------------------------------------------- |
| Save corruption / rollback? | Godot: SHA-256 envelope + `lost_number_save.bak.json` auto-recovery |
| RTO / RPO                   | Instant local resume; backup on every save; no cloud PITR           |
| SOC2 / HIPAA?               | N/A — consumer offline game; Play + privacy policy sufficient       |
| Cloud budget                | $0 runtime                                                          |
| Target package              | `com.averixor.lostnumber` (release), `.dev` suffix for debug        |

---

## Repository layout

```
LostNumber/                 ← canonical project (this repo)
├── godot/                  # Ship target for Play
├── android/                # Godot release keystore (gitignored secrets)
├── store/                  # Play listing assets
├── build/android/    # Prebuilt APK/AAB (local, gitignored)
├── docs/                   # All project documentation (see docs/README.md)
├── scripts/                # Build, verify, export
├── privacy.html            # Play Store privacy policy (static page)
├── docs/HANDOFF.txt        # Quick start
└── docs/archive/MERGE_NOTES.md  # Zip consolidation provenance (historical)
```

---

## Build & release

### Prerequisites

- Node.js ≥ 20.19
- Godot 4.7+ (4.7 tested)
- JDK 17+ at `~/Android/jbr` (snap Godot cannot use `/opt/...`)
- Android SDK at `~/Android/Sdk`

### Verify (CI-local)

```bash
npm ci
npm run release:ideal
```

Runs: format, lint, typecheck, tagline, Godot export config, repo smoke. Godot **rules + save** when `godot4` is on PATH (silently skipped otherwise). Does **not** run Godot smoke or i18n tests.

**Full pre-upload gate:** `npm run godot:verify:aab` or `./scripts/verify-godot-aab.sh` (runs `godot:test:all`, `release:check`, release export, AAB manifest checks).

### Godot runtime (primary)

Entry: **`Boot.tscn`** → **`App.tscn`** → screens via **`ScreenRouter`** autoload (back-stack, fade transitions, Android back in `App.gd`).

Sprint 1–2 visual parity (branch `godot-visual-parity`): ThemeTokens, global theme, `assets/ui/`, BackgroundLayer, NeonButton, MainMenu (dock + quick-row + icons), Stats/About screens, FeatureStubOverlay, legacy save plugin AAR, `bg_effects_enabled` in Settings. Tracker: `docs/archive/VISUAL_PORT_MAP.md` (historical).

### Godot → Play (primary)

```bash
npm run godot:import
npm run godot:android:release
# Upload: build/android/lost-number.aab
```

### Debug on device

```bash
npm run godot:android:debug
adb uninstall com.averixor.lostnumber.dev 2>/dev/null || true
adb install -r build/android/lost-number-debug.apk
```

---

## Save format (Godot)

```json
{
  "envelope_version": 1,
  "saved_at": "2026-07-01T11:00:00",
  "checksum": "<sha256 of data_json>",
  "data_json": "{ \"version\": 2, \"current_level\": 0, \"grid\": [...], ... }"
}
```

- Corrupt primary → load `.bak` → promote backup to primary
- Legacy flat `version: 2` saves still load (no envelope)
- Startup migration: `LegacySaveMigration` autoload + `Boot.gd` (file import + Android plugin when present)
- Settings **Import legacy save** button is currently a **stub** — shows `settings_import_legacy_none` only; does not invoke manual import
- Tests: `npm run godot:test:save`

---

## Play Console checklist

- [ ] Upload `lost-number.aab` (Godot 2.1.6)
- [ ] Privacy URL: `https://averixor.github.io/LostNumber/privacy.html`
- [ ] Data Safety: no collection, no sharing
- [ ] IARC: puzzle, no violence/gambling/IAP/ads
- [ ] Screenshots from real Godot build (replace menu drafts)
- [ ] Internal → Closed → Production rollout

---

## Roadmap (condensed)

| When    | What                                                                 |
| ------- | -------------------------------------------------------------------- |
| **Now** | Godot ship: gameplay + save + Android export; MainMenu web parity    |
| Next    | Chain-sum HUD, toasts, menu skin variants, achievements/daily polish |
| Q2 2026 | Play Games integration, wheel canvas animation polish                |
| Y3+     | Optional opt-in cloud save                                           |

---

## Pack for distribution

```bash
npm run pack:unified
# → dist/LostNumber-unified-YYYYMMDD.zip
```

Excludes: `node_modules`, keystores, `.godot`, generated `godot/android/`.

---

## Challenge / review notes

- **Kyber / mTLS / zero-trust network:** Not applicable — fully offline; save integrity = SHA-256 + backup, not encryption at rest (no secrets in save).
- **Single Android path:** Godot is the only Play ship target; Web/JS is **parity reference** for UI/i18n diff.
- **versionCode:** Increment on every Play upload (`godot/export_presets.cfg` preset `Android`).
