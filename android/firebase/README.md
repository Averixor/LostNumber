# Android Firebase config (secrets)

Реальні `google-services.json` **не комітити**. У git лише цей README і `google-services.example.json` (підставні id **без** префікса `AIzaSy` — інакше GitHub Secret Scanning піднімає алерт).

## Layout

```text
android/firebase/
  README.md                          ← цей файл
  google-services.example.json       ← структура-зразок (fake)
  dev/google-services.json           ← gitignored (lost-number-dev / .dev package)
  prod/google-services.json          ← gitignored (lost-number-prod / release package)
```

## Install (локально)

```powershell
New-Item -ItemType Directory -Force -Path android/firebase/dev, android/firebase/prod | Out-Null
Copy-Item path\to\downloaded-dev\google-services.json android/firebase/dev/google-services.json
Copy-Item path\to\downloaded-prod\google-services.json android/firebase/prod/google-services.json
```

`git status` **не** повинен показувати ці файли для commit.

## Runtime wiring (B2 Auth)

- Plugin: `godot/android/plugins/LostNumberFirebase.gdap`
- Export (`scripts/godot-android-export.sh`) копіює `dev` (debug) або `prod` (release) json у `godot/android/build/google-services.json` і вмикає Gradle plugin `com.google.gms.google-services`.
- Без json збірка проходить, але Sign-In на девайсі повертає `firebase_not_configured`.

## Див. також

- [`docs/AUTH_SIGNIN_QA.md`](../../docs/AUTH_SIGNIN_QA.md)
- [`docs/FIREBASE_OWNER_RUNBOOK.md`](../../docs/FIREBASE_OWNER_RUNBOOK.md)
- [`docs/en/FIREBASE_ADR.md`](../../docs/en/FIREBASE_ADR.md)
