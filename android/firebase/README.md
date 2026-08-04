# Android Firebase config (secrets)

Реальні `google-services.json` **не комітити**. У git лише цей README і `google-services.example.json` (підставні id).

## Layout

```text
android/firebase/
  README.md                          ← цей файл
  google-services.example.json       ← структура-зразок (fake)
  dev/google-services.json           ← gitignored (з Firebase Console, lost-number-dev)
  prod/google-services.json          ← gitignored (з Firebase Console, lost-number-prod)
```

## Install (локально)

1. Firebase Console → Project settings → Your apps → Download `google-services.json`.
2. Покласти файл:

```powershell
New-Item -ItemType Directory -Force -Path android/firebase/dev, android/firebase/prod | Out-Null
Copy-Item path\to\downloaded-dev\google-services.json android/firebase/dev/google-services.json
Copy-Item path\to\downloaded-prod\google-services.json android/firebase/prod/google-services.json
```

3. Переконатися, що `git status` **не** показує ці файли як untracked для commit (мають бути в `.gitignore`).

## Runtime wiring

Підключення Gradle / Godot plugin — **лише** після OWNER flip у [`docs/FIREBASE_STAGE4_GATES.md`](../../docs/FIREBASE_STAGE4_GATES.md), гілка `godot/firebase-android-bridge`. Цей kickoff **не** додає Firebase SDK.

## Див. також

- [`docs/FIREBASE_OWNER_RUNBOOK.md`](../../docs/FIREBASE_OWNER_RUNBOOK.md)
- [`docs/en/FIREBASE_ADR.md`](../../docs/en/FIREBASE_ADR.md)
