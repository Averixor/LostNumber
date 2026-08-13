# Firebase OWNER runbook (Console setup)

> Runtime код **не** стартує з цього документа. Спочатку пройти [`FIREBASE_STAGE4_SEQUENCE.md`](FIREBASE_STAGE4_SEQUENCE.md) (CT → Phase 5 → privacy → approve), потім Console/SHA з цього runbook, і лише тоді flip [`FIREBASE_STAGE4_GATES.md`](FIREBASE_STAGE4_GATES.md).  
> Kickoff фіксує **як** OWNER готує Console / SHA / secrets (кроки 5–6 sequence).

## Проєкти

| Env  | Firebase project id (ціль) | Призначення      |
| ---- | -------------------------- | ---------------- |
| Dev  | `lost-number-dev`          | Debug / internal |
| Prod | `lost-number-prod`         | Play / Closed CT |

Створює **лише OWNER** у [Firebase Console](https://console.firebase.google.com/).

## Android apps

| Package                        | Призначення       |
| ------------------------------ | ----------------- |
| `com.Averixor.Lost_Number`     | Release / Play    |
| `com.Averixor.Lost_Number.dev` | Debug / device QA |

Додати **обидва** пакети в кожен потрібний Firebase project (або чітко розділити: debug → dev project, release → prod).

## SHA сертифікати (не плутати типи)

Для Google Sign-In / App Check / Play Integrity потрібно зареєструвати **правильні** SHA-1 (і SHA-256 де вимагає Console):

| Тип                  | Звідки                                                     | Коли потрібен                     |
| -------------------- | ---------------------------------------------------------- | --------------------------------- |
| **Debug**            | Локальний debug keystore / Android Studio debug            | Sign-In на debug APK              |
| **Upload**           | Upload keystore (локально: див. `PLAY_CONSOLE_RECON.md`)   | Локально підписані release / AAB  |
| **Play App Signing** | Play Console → App integrity → App signing key certificate | Збірки, перепідписані Google Play |

Локальні **upload** fingerprints (звірити з Console):

| Алгоритм | Значення (з `docs/PLAY_CONSOLE_RECON.md`)                                                         |
| -------- | ------------------------------------------------------------------------------------------------- |
| SHA-1    | `43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3`                                     |
| SHA-256  | `35:B0:4D:F7:D7:CE:62:48:94:F8:83:FF:77:BB:51:69:2F:9B:DB:3A:C5:44:22:AF:6A:EC:87:8A:C3:A4:E8:97` |

CT AAB artifact: **`c85ee340…`** (`build/android/lost-number.aab`) — Auth-ready; CT ще потребує OWNER Sign-In smoke.  
**Не upload:** `1463fd4c…`, `398b83f3…`, `5c0530b0…` — [`STAGE1_RELEASE_RECORD.md`](STAGE1_RELEASE_RECORD.md).

## Auth

- Увімкнути **лише Google** (Identity providers).
- Не вмикати Anonymous / Email / Phone / Facebook / Apple для Stage 4 MVP.

## Firestore

| Параметр | Kickoff рекомендація                                                                                               |
| -------- | ------------------------------------------------------------------------------------------------------------------ |
| Region   | **`europe-west3`** (Frankfurt) — **OWNER підтверджує** перед створенням prod DB (регіон майже незмінний)           |
| Path     | `users/{uid}/save/current` (див. ADR)                                                                              |
| Rules    | Приклад у [`docs/firebase/firestore.rules.example`](firebase/firestore.rules.example); emulator checklist там само |

Не вмикати production writes без rules + emulator green у runtime PR `firebase/firestore-rules`.

## Budget / квоти

- Увімкнути **budget alerts** (Billing) для `lost-number-dev` і `lost-number-prod`.
- Стежити за Auth MAU / Firestore reads-writes після CT Firebase.

## Secrets layout (git)

Реальні файли **поза git** (див. `.gitignore`):

```text
android/firebase/dev/google-services.json
android/firebase/prod/google-services.json
```

У репозиторії:

| Шлях                                            | Зміст                          |
| ----------------------------------------------- | ------------------------------ |
| `android/firebase/google-services.example.json` | Підставна структура (fake ids) |
| `android/firebase/README.md`                    | Інструкція встановлення        |

### Приклад локального встановлення

```powershell
# Після завантаження з Firebase Console:
New-Item -ItemType Directory -Force -Path android/firebase/dev, android/firebase/prod | Out-Null
Copy-Item $env:USERPROFILE\Downloads\google-services.json android/firebase/dev/google-services.json
# prod аналогічно з prod-проєкту
```

CI (майбутні runtime PR): secrets для prod `google-services.json` — через GitHub Actions secrets / encrypted files, **не** в git history.

## App Check (пізніше)

- Задокументувати debug provider / Play Integrity у 4A docs.
- **Enforcement off** до окремого OWNER sign-off.

## Не вмикати «заодно»

Crashlytics, Google Analytics, Remote Config — **ні** у kickoff і не в перших Cloud Save PR без окремого рішення.

## Чеклист OWNER перед «go» на 4A

1. Повна послідовність: [`FIREBASE_STAGE4_SEQUENCE.md`](FIREBASE_STAGE4_SEQUENCE.md) (CT smoke першим).
2. Gates у [`FIREBASE_STAGE4_GATES.md`](FIREBASE_STAGE4_GATES.md) закриті (`[x]` — лише OWNER).
3. Dev + prod проєкти, обидва package names, SHA всіх трьох типів де застосовно.
4. Google Auth only; Firestore region підтверджена.
5. Budget alerts; локальні `google-services.json` на місці (gitignore).
6. Privacy delta прочитаний; готувати Data safety PR разом із `INTERNET=true`.
