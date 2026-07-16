# Android build artifacts (APK / AAB)

**Canonical output folder** for Godot Android packages. All release and debug builds write here only:

| Artifact | Command |
|----------|---------|
| `lost-number-debug.apk` | `npm run godot:android:debug` |
| `lost-number.aab` | `npm run godot:android:release` |

Install debug build on a connected device:

```bash
npm run godot:android:adb-install
# or: adb install -r build/android/lost-number-debug.apk
```

Signing keystore stays in `android/keystore/` (never commit). This folder is gitignored except this README.

Intermediate Gradle output under `godot/android/build/` is cleaned after each export.
