# Google Sign-In (B2) — device QA

Package: `com.Averixor.Lost_Number.dev` (debug) / `com.Averixor.Lost_Number` (release).  
Auth: Firebase Google Sign-In only. **No Cloud Save.**

## P0 runtime note (Godot 4.7)

`AuthManager` must detect Android plugin methods via `has_java_method()`, not `has_method()`.  
Builds that still use `has_method()` fail with `sign_in_unavailable` before Java/`isAvailable()` runs.  
Do **not** upload AAB SHA `1463fd4c…` to Closed Testing (same broken bridge).

## OWNER prep (required for real OAuth)

1. Firebase projects + Android apps for both package IDs (`lost-number-dev` / `lost-number-prod`, Google Auth only, no Analytics)
2. Register SHA-1/256: debug keystore, upload `43:93…`, Play App signing `37:FB…`
3. Auth provider: Google only
4. Place gitignored configs:
   - `android/firebase/dev/google-services.json`
   - `android/firebase/prod/google-services.json`
5. Rebuild plugin AAR if Java changed: `npm run godot:android:firebase-aar`
6. Rebuild debug + release after JSON lands — **AAB SHA will change**; only the new SHA is CT-eligible

## Build / install

```bash
npm run godot:android:firebase-aar   # if needed
npm run godot:android:debug
adb install -r build/android/lost-number-debug.apk
```

Export copies `android/firebase/dev/google-services.json` into `godot/android/build/` when present.

## Checklist

- [ ] Cold start → Main menu **without** account (no blocking auth popup)
- [ ] Settings → Account shows **Guest**
- [ ] Desktop/editor: Sign-In button disabled / «Android only»
- [ ] On device **without** `google-services.json`: toast `firebase_not_configured` (honest failure) — **not** `sign_in_unavailable`
- [ ] On device **with** config: Sign in with Google → picker → Settings shows display name/email
- [ ] Sign out → Guest again; local save still present
- [ ] Play a level offline while signed out and while signed in — progress still local only
- [ ] `privacy.html` mentions optional Google Sign-In + `INTERNET`
- [ ] Release presets: `permissions/internet=true`, `plugins/LostNumberFirebase=true`, `target_sdk=36`
- [ ] `npm run release:check` fails if AAB has plugin marker but no `google_app_id` / `default_web_client_id`

## Out of scope (do not test as shipped)

- Cloud sync / conflict dialog
- In-game admin roles
- Analytics / Crashlytics
