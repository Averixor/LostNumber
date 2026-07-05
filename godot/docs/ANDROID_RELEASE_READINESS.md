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
| versionCode | `14`                                  | `14`                                        |
| versionName | `2.1.4`                               | `2.1.4-dev`                                 |
| Format      | AAB (`export_format=1`)               | APK                                         |
| minSdk      | 24                                    | 24                                          |
| targetSdk   | 35                                    | 35                                          |
| ABI         | arm64-v8a, x86_64                     | arm64-v8a, x86_64                           |
| Output      | `build/godot/android/lost-number.aab` | `build/godot/android/lost-number-debug.apk` |

### Versioning

Current: `versionName 2.1.4` / `versionCode 14`. The Capacitor app (`android/app/build.gradle`) shares the same package id and the same values, so only one bundle with a given versionCode can live in Play (currently Godot). **Every new upload needs a versionCode greater than any previously uploaded** — next release: code `15`.

> `versionName` is a human-readable label (free-form). `versionCode` is the integer Play compares — just increment it by 1 each upload.

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

## If release fails

| Error                                 | Fix                                                       |
| ------------------------------------- | --------------------------------------------------------- |
| `Missing android/keystore.properties` | Create file + keystore (see above)                        |
| `Keystore not found`                  | Check `storeFile` path relative to `android/`             |
| Export templates missing              | Re-run export script (auto-download)                      |
| JDK / SDK not found                   | Set `JAVA_HOME`, `ANDROID_HOME` in shell or export script |
