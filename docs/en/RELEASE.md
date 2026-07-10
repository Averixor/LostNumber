---
language: en
title: Lost Number — Release Plans & Checklists
version: 2.1.6
last_updated: 2026-07-10
---

# Release Plans & Checklists

Primary release path: **Godot 4 Android AAB** → Google Play. Capacitor/Web remains a legacy fallback.

## Current release identity

| Field       | Release                               | Debug                                       |
| ----------- | ------------------------------------- | ------------------------------------------- |
| Package     | `com.averixor.lostnumber`             | `com.averixor.lostnumber.dev`               |
| versionName | `2.1.6`                               | `2.1.6-dev`                                 |
| versionCode | `16`                                  | `16`                                        |
| Format      | AAB                                   | APK                                         |
| Output      | `build/godot/android/lost-number.aab` | `build/godot/android/lost-number-debug.apk` |
| minSdk      | 24                                    | 24                                          |
| targetSdk   | 35                                    | 35                                          |
| ABI         | arm64-v8a, x86_64                     | arm64-v8a, x86_64                           |

**Next Play upload:** versionCode **17** (must exceed any previously uploaded code).

### Versioning rule (code ≥ 15)

`versionName = 2.1.(versionCode - 10)` — e.g. code `16` → `2.1.6`. Debug builds append `-dev`.

ABI note: `armeabi-v7a` intentionally excluded (~8k 32-bit-only devices in catalog).

## Prerequisites

| Tool             | Requirement                                               |
| ---------------- | --------------------------------------------------------- |
| Node.js          | ≥ 20.19                                                   |
| Godot            | 4.3+ (4.5 tested; `godot4` on PATH)                       |
| JDK              | 17 at `~/Android/jbr` (snap Godot cannot read `/opt/...`) |
| Android SDK      | `~/Android/Sdk` or `ANDROID_HOME`                         |
| Export templates | Auto-downloaded on first export script run                |

## Pre-release verification

### Full local gate (recommended)

```bash
npm ci
npm run release:ideal
```

Runs: format, lint, typecheck, static assets, smoke tests, Godot rules + save + smoke tests.

### Godot-specific

```bash
npm run godot:import
npm run godot:test:all
```

### Pre-upload AAB gate

```bash
npm run godot:verify:aab
```

Requires existing AAB at `build/godot/android/lost-number.aab`. Runs tests + release:check + AAB manifest validation.

**Do not commit** keystore fields that the export script may write into `export_presets.cfg` — `verify-godot-release.mjs` rejects them.

## Build commands

### Godot (primary)

```bash
npm run godot:import
npm run godot:android:debug     # test APK
npm run godot:android:release   # Play AAB
```

### Debug on device

```bash
npm run godot:android:debug
adb uninstall com.averixor.lostnumber.dev 2>/dev/null || true
adb install -r build/godot/android/lost-number-debug.apk
```

### Legacy Capacitor (secondary)

```bash
npm run release:check
npm run verify:android
npm run android:bundle
# → android/app/build/outputs/bundle/release/app-release.aab
```

Only one AAB per `versionCode` can be uploaded — prefer Godot.

## Signing (release)

Release export requires local files (gitignored):

1. **`android/keystore.properties`**

```properties
storeFile=keystore/your-release.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=your_key_alias
keyPassword=YOUR_KEY_PASSWORD
```

2. **Keystore** at `android/keystore/your-release.jks`

### Create keystore (one-time)

```bash
mkdir -p android/keystore
keytool -genkeypair -v \
  -keystore android/keystore/lostnumber-release.jks \
  -alias lostnumber_release \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass 'YOUR_STORE_PASSWORD' \
  -keypass 'YOUR_KEY_PASSWORD' \
  -dname "CN=Lost Number, OU=Mobile, O=Averixor, L=Local, ST=Local, C=UA"
```

**Never commit** `.jks` files or `keystore.properties` with real passwords.

## Export filters

AAB excludes non-runtime assets:

- `assets/store/*` — Play listing graphics
- `assets/icons/neon/*` — unused duplicate icon set

In-game graphics: `godot/assets/ui/` only.

## Icons

| Asset           | Path                                |
| --------------- | ----------------------------------- |
| Launcher (1024) | `godot/assets/icons/icon-1024.png`  |
| Project icon    | `godot/icon.svg` / `godot/icon.png` |
| Adaptive icons  | Not configured (optional for Play)  |

## Google Play Console checklist

- [ ] Upload `lost-number.aab` (Godot 2.1.6, versionCode 16+)
- [ ] Privacy URL: `https://averixor.github.io/LostNumber/privacy.html`
- [ ] Data Safety: no collection, no sharing
- [ ] IARC: puzzle, no violence/gambling/IAP/ads
- [ ] Screenshots from **real Godot build** (replace menu drafts)
- [ ] Listing copy: `store/PLAY_CONSOLE_LISTING.md` / `godot/docs/PLAY_CONSOLE_LISTING.md`
- [ ] Rollout: Internal → Closed → Production

## On-device QA checklist

| Area          | Verify                                                  |
| ------------- | ------------------------------------------------------- |
| Boot          | Splash, preload, fade to MainMenu                       |
| Gameplay      | Chain drag, merge, gravity, level complete              |
| Save          | Resume after kill; corrupt primary recovers from `.bak` |
| Legacy import | Settings → Import legacy save (upgrade from Capacitor)  |
| Navigation    | Back-stack on all screens; Android hardware back        |
| Themes        | Dawn/dusk toggle; background cycle on MainMenu          |
| i18n          | UA/RU/EN switch without missing keys                    |
| Audio         | SFX + music; mute in settings                           |
| Low effects   | Particles off; fade-only transitions                    |
| Performance   | Stable FPS on mid-range Android after extended play     |

Detailed QA doc: `docs/ANDROID_QA.md`.

## Testing matrix

| Command                                     | Scope                                          |
| ------------------------------------------- | ---------------------------------------------- |
| `npm run godot:test:all`                    | Rules, save, smoke (autoloads, scenes compile) |
| `npm run godot:test:save`                   | Checksum + backup recovery                     |
| `npm run godot:test:i18n`                   | 285 keys × 3 locales                           |
| `timeout 15 godot4 --path godot --headless` | Boot → App → MainMenu, no script errors        |

## Troubleshooting

| Error                                 | Fix                                           |
| ------------------------------------- | --------------------------------------------- |
| `Missing android/keystore.properties` | Create file + keystore (see above)            |
| `Keystore not found`                  | Check `storeFile` path relative to `android/` |
| Export templates missing              | Re-run export script (auto-download)          |
| JDK / SDK not found                   | Set `JAVA_HOME`, `ANDROID_HOME`               |

## Distribution pack

```bash
npm run pack:unified
# → dist/LostNumber-unified-YYYYMMDD.zip
```

Excludes: `node_modules`, keystores, `.godot`, generated `godot/android/`.

## Roadmap (release-adjacent)

| When    | What                                                                 |
| ------- | -------------------------------------------------------------------- |
| **Now** | Godot ship: gameplay + save + Android export; MainMenu web parity    |
| Next    | Chain-sum HUD, toasts, menu skin variants, achievements/daily polish |
| Q2 2026 | Play Games integration, wheel canvas animation polish                |
| Y3+     | Optional opt-in cloud save                                           |

Phase 6 Firebase (auth, Firestore) is **blocked** until Phase 5 performance is closed — see `docs/PHASES.md`.
