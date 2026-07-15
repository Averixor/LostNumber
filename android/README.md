# Android signing (Godot only)

This folder holds **release signing** for Godot Android exports. It is not a native app project.

- `keystore.properties` — local only (gitignored); see `docs/ANDROID_RELEASE_READINESS.md`
- `keystore/*.jks` — release keystore (gitignored)

Build and ship with `npm run godot:android:release` → `build/android/lost-number.aab`.
