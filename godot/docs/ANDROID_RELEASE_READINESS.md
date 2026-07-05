# Android release readiness (Godot MVP)

Checklist before `npm run godot:android:release`.

## Export preset (`export_presets.cfg`)

| Field       | Release (`preset.0`)                  | Debug (`preset.1`)                          |
| ----------- | ------------------------------------- | ------------------------------------------- |
| Package     | `com.averixor.lostnumber`             | `com.averixor.lostnumber.dev`               |
| versionCode | `10`                                  | `10`                                        |
| versionName | `2.0.1`                               | `2.0.0-dev`                                 |
| Format      | AAB (`export_format=1`)               | APK                                         |
| minSdk      | 24                                    | 24                                          |
| targetSdk   | 35                                    | 35                                          |
| ABI         | arm64-v8a                             | arm64-v8a                                   |
| Output      | `build/godot/android/lost-number.aab` | `build/godot/android/lost-number-debug.apk` |

Increment **versionCode** on every Play upload. The Capacitor app (`android/app/build.gradle`) shares the same package id — the Godot versionCode must always be **greater than the last versionCode ever uploaded to Play** (Capacitor or Godot), otherwise Play rejects the AAB.

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
```

## If release fails

| Error                                 | Fix                                                       |
| ------------------------------------- | --------------------------------------------------------- |
| `Missing android/keystore.properties` | Create file + keystore (see above)                        |
| `Keystore not found`                  | Check `storeFile` path relative to `android/`             |
| Export templates missing              | Re-run export script (auto-download)                      |
| JDK / SDK not found                   | Set `JAVA_HOME`, `ANDROID_HOME` in shell or export script |
