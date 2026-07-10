# Lost Number — Production Handoff (Ideal Build)

**Package:** `com.averixor.lostnumber`  
**Version:** `2.1.6` (versionCode `16`)  
**Audience:** Casual 3+, offline puzzle  
**Primary Android:** Godot 4.5 native (`build/godot/android/lost-number.aab`)  
**Secondary:** Capacitor 7 WebView (legacy web parity, `npm run android:bundle`)

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Google Play  ←  lost-number.aab (Godot, recommended)   │
├─────────────────────────────────────────────────────────┤
│  godot/          Boot→App shell, ScreenRouter, gameplay │
│  js/ + _site/    Web reference (visual parity source)   │
│  android/        Capacitor shell (legacy WebView)       │
│  assets/         Neon UI, icons, backgrounds (UA/RU/EN) │
│  store/          Play Console listing + graphics          │
└─────────────────────────────────────────────────────────┘
```

| Layer           | Stack                                        | Notes                                   |
| --------------- | -------------------------------------------- | --------------------------------------- |
| Gameplay (ship) | Godot 4.5 GDScript                           | Boot→App→screens; back-stack navigation |
| Web reference   | Vanilla JS + Capacitor 7                     | Visual/UI/i18n source; legacy Android   |
| Save            | `user://` JSON (Godot), `localStorage` (web) | Checksum + `.bak` rollback (Godot)      |
| Network         | None                                         | GDPR-friendly: no tracking, no PII      |
| Compliance      | `privacy.html`, Play Data Safety             | Offline-only data                       |

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
├── android/                # Capacitor (legacy)
├── js/, css/, index.html   # Web game
├── assets/, public/audio/  # Shared media
├── store/                  # Play listing assets
├── build/godot/android/    # Prebuilt APK/AAB (local, gitignored)
├── docs/                   # ANDROID.md, PLAY_STORE.md
├── godot/docs/             # GAME_RULES.md, PLAY_STORE_GODOT.md
├── scripts/                # Build, verify, export
├── privacy.html
├── HANDOFF.txt             # Quick start
└── MERGE_NOTES.md          # Zip consolidation provenance
```

---

## Build & release

### Prerequisites

- Node.js ≥ 20.19
- Godot 4.3+ (4.5 tested)
- JDK 17+ at `~/Android/jbr` (snap Godot cannot use `/opt/...`)
- Android SDK at `~/Android/Sdk`

### Verify (CI-local)

```bash
npm ci
npm run release:ideal
```

Runs: format, lint, typecheck, static assets, smoke tests, Godot rules + save + smoke tests.

### Godot runtime (primary)

Entry: **`Boot.tscn`** → **`App.tscn`** → screens via **`ScreenRouter`** autoload (back-stack, fade transitions, Android back in `App.gd`).

Sprint 1–2 visual parity (branch `godot-visual-parity`): ThemeTokens, global theme, `assets/ui/`, BackgroundLayer, NeonButton, MainMenu (dock + quick-row + icons), Stats/About screens, FeatureStubOverlay, legacy save plugin AAR, `bg_effects_enabled` in Settings. Tracker: `godot/docs/VISUAL_PORT_MAP.md`.

### Godot → Play (primary)

```bash
npm run godot:import
npm run godot:android:release
# Upload: build/godot/android/lost-number.aab
```

### Capacitor (legacy web APK/AAB)

```bash
npm run android:bundle
# android/app/build/outputs/bundle/release/app-release.aab
```

### Debug on device

```bash
npm run godot:android:debug
adb uninstall com.averixor.lostnumber.dev 2>/dev/null || true
adb install -r build/godot/android/lost-number-debug.apk
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
- **Dual stack risk:** Godot is ship target; Capacitor/Web is visual reference only — do not treat WebView AAB as primary.
- **versionCode:** Increment on every Play upload (`godot/export_presets.cfg` preset `Android`).
