# Android release readiness (Godot)

Checklist before `npm run godot:android:release`.

## Runtime entry (`project.godot`)

| Setting      | Value                                                                            |
| ------------ | -------------------------------------------------------------------------------- |
| `main_scene` | `res://scenes/Boot.tscn`                                                         |
| Flow         | Boot (splash/preload) → `App.tscn` (shell) → screens via `ScreenRouter` autoload |

App shell persists `BackgroundLayer` and overlay layers; individual screens mount under `ScreenRoot`. See `godot/README.md`.

## Export preset (`export_presets.cfg`)

| Field       | Release (`preset.0`)                  | Debug (`preset.1`)                          |
| ----------- | ------------------------------------- | ------------------------------------------- |
| Package     | `com.averixor.lostnumber`             | `com.averixor.lostnumber.dev`               |
| versionCode | `16`                                  | `16`                                        |
| versionName | `2.1.6`                               | `2.1.6-dev`                                 |
| Format      | AAB (`export_format=1`)               | APK                                         |
| minSdk      | 24                                    | 24                                          |
| targetSdk   | 35                                    | 35                                          |
| ABI         | arm64-v8a, x86_64                     | arm64-v8a, x86_64                           |
| Output      | `build/android/lost-number.aab` | `build/android/lost-number-debug.apk` |

### Versioning

Current: `versionName 2.1.6` / `versionCode 16`. **Every new upload needs a versionCode greater than any previously uploaded** — next release: code `17`.

> `versionName` is a human-readable label (free-form). `versionCode` is the integer Play compares — just increment it by 1 each upload.
>
> **Naming rule (code ≥ 15):** `versionName = 2.1.(versionCode - 10)` — e.g. code `15` → `2.1.5`, code `16` → `2.1.6`. Debug builds append `-dev`.

ABI note: only `arm64-v8a` + `x86_64` are shipped. Dropping `armeabi-v7a` excludes 32-bit-only devices (~8k in the device catalog) — intentional.

## Icons

- Launcher: `godot/assets/icons/icon-1024.png` (referenced in export preset)
- Project icon: `godot/icon.svg`
- Adaptive icons: not configured yet (optional for Play)

## Signing (release only)

Release export requires:

1. **`android/keystore.properties`** (gitignored — local only):

```properties
storeFile=keystore/your-release.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=your_key_alias
keyPassword=YOUR_KEY_PASSWORD
```

2. **Keystore file** at `android/keystore/your-release.jks`

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

Then create `android/keystore.properties` following the pattern above with matching paths and passwords.

**Never commit** `.jks` or `keystore.properties` with real passwords.

## Prerequisites

- Godot 4.3+ (`godot4` on PATH)
- Android SDK: `~/Android/Sdk` (or `ANDROID_HOME`)
- JDK 17: `~/Android/jbr` (snap Godot cannot read `/opt/...`)
- Export templates (script auto-downloads on first build)

## Commands

```bash
npm run godot:import
npm run godot:test:all
npm run godot:android:debug    # test APK
npm run godot:android:release  # Play AAB
npm run godot:verify:aab       # full pre-upload gate (tests + release:check + AAB checks)
```

## Export filters

- `exclude_filter=assets/store/*,assets/icons/neon/*` — Play listing art and unused neon icon set stay out of the AAB.
- In-game graphics live under `godot/assets/ui/` only.

## Recent UI fixes (commits `bd9a026`, `457e31a` + локальні правки)

- SkinPreview + `ImagePickerHelper.gd` (custom background picker; не MobileImagePicker)
- Global backgrounds: `ThemeManager.get_background_texture_path()` → `BackgroundLayer` / `LnUi.current_background_path()`
- Settings: scroll layout, **Back** pinned at bottom; theme toggle cycles dawn/dusk only (`UI_CYCLE_THEMES`; twilight hidden)
- DailyQuests: scroll + Back at bottom; card layout refresh (`DailyQuestCard.tscn`)
- Game HUD: bonus/crown visuals; tile crown rendering
- i18n: **285** keys per locale (uk/ru/en)

Pre-upload gate: `npm run godot:verify:aab` (tests + release:check + AAB manifest). Requires existing AAB at `build/android/lost-number.aab`. **Не комітити** keystore-поля, які export-скрипт може дописати в `export_presets.cfg` — `verify-godot-release.mjs` їх відхиляє.

## If release fails

| Error                                 | Fix                                                       |
| ------------------------------------- | --------------------------------------------------------- |
| `Missing android/keystore.properties` | Create file + keystore (see above)                        |
| `Keystore not found`                  | Check `storeFile` path relative to `android/`             |
| Export templates missing              | Re-run export script (auto-download)                      |
| JDK / SDK not found                   | Set `JAVA_HOME`, `ANDROID_HOME` in shell or export script |
