# Google Sign-In (B2) — device QA

Package: `com.Averixor.Lost_Number.dev` (debug) / `com.Averixor.Lost_Number` (release).  
Auth: Firebase Google Sign-In only. **No Cloud Save.**

## P0 runtime note (Godot 4.7)

`AuthManager` must detect Android plugin methods via `has_java_method()`, not `has_method()`.  
Do **not** upload AAB SHA `1463fd4c…` to Closed Testing.

## Current Auth-ready release AAB (2026-08-14)

| Field   | Value                                                              |
| ------- | ------------------------------------------------------------------ |
| Path    | `build/android/lost-number.aab`                                    |
| SHA-256 | `c85ee34032a0b0abfab78dbe4b50d2dd35e05fb14aa8d8a020c96104ee507d52` |
| Config  | `android/firebase/prod/google-services.json` (oauth_client type 3) |

Universal sideload APK (upload-signed): `build/android/lost-number-universal.apk` (local only).

## OWNER prep

### Release app (done if Console matches)

- Package `com.Averixor.Lost_Number`
- SHA-1: upload `43:93…`, Play App Signing `37:FB…`
- Web OAuth client present in `google-services.json`
- Auth → Google enabled

### Debug app (still needed for `.dev` APK)

1. Firebase Console → project **`lost-number`** (або `lost-number-dev`, якщо розділено) → Add Android app: `com.Averixor.Lost_Number.dev`
2. Register debug SHA-1: `3F:54:CA:7D:63:33:D0:B6:E7:5C:7A:97:52:02:0B:6E:F9:46:CD:35`  
   (SHA-256 debug: `C6:1D:F2:03:B2:16:8F:A1:A6:2E:6B:9E:78:2D:40:23:1E:78:33:AF:FF:54:4C:DA:35:E0:21:02:43:68:BA:47`)
3. Download JSON → `android/firebase/dev/google-services.json`
4. `npm run godot:android:debug`

## Build / install

```bash
npm run godot:android:release
# optional local install (phone must allow USB install):
# adb install -r build/android/lost-number-universal.apk
```

If `INSTALL_FAILED_USER_RESTRICTED`: phone Settings → Developer options → **Install via USB** / confirm dialog.

## Checklist

- [x] Cold start without blocking auth popup (prior QA)
- [x] Without JSON: `firebase_not_configured` (prior QA)
- [x] AAB has Firebase resources (`release:check` PASS)
- [x] Positive Sign-In with Google on device (release sideload, 2026-08-14)
- [x] Sign out → Guest (FirebaseAuth sign-out event; UI «Гість»)
- [ ] Offline play while signed in/out

### Device smoke record (2026-08-14)

| Field    | Value                                                                                   |
| -------- | --------------------------------------------------------------------------------------- |
| Device   | Xiaomi 23117RA68G (`emerald`)                                                           |
| Artifact | `lost-number-universal.apk` from AAB `c85ee340…`                                        |
| Package  | `com.Averixor.Lost_Number` VC6 / 2.1.6                                                  |
| Result   | **PASS** — Credential Manager → FirebaseAuth uid; Settings shows «Увійшли»; Sign-Out OK |
| Notes    | Install via USB required once; not Play CT install                                      |

## Out of scope

- Cloud sync / Analytics / Crashlytics / in-game admin
