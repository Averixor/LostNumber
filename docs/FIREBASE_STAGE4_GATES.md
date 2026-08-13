# Stage 4 Firebase — hard gates (OWNER)

| Поле             | Значення                                                                                 |
| ---------------- | ---------------------------------------------------------------------------------------- |
| Статус runtime   | **Auth B2 (Sign-In only) у коді**; Cloud Save / 4B/4C **BLOCKED** до OWNER CT gates      |
| Kickoff docs     | Готово (цей файл + ADR / OWNER runbook / privacy delta)                                  |
| Offline-first    | Залишається; Google Sign-In optional; гра без акаунта                                    |
| `INTERNET` зараз | `true` (Auth-capable) у обох Android presets (`godot/export_presets.cfg`)                |
| Package          | `com.Averixor.Lost_Number` / `.dev` (новий listing; не старий `com.averixor.lostnumber`) |

> **Правило:** Stage 3 hygiene / repo closeout **не** замінює Closed testing.  
> Агент **не** відмічає OWNER-чекбокси з репо. Лише OWNER ставить `[x]` після факту.  
> **Порядок дій OWNER (walkable):** [`FIREBASE_STAGE4_SEQUENCE.md`](FIREBASE_STAGE4_SEQUENCE.md) — CT smoke → Phase 5 → privacy → Auth/Cloud approve → Console → SHA/region → **потім** цей файл `[x]` → bridge.

## Поточний факт Closed testing

| Поле                      | Значення                                                               | Джерело                   |
| ------------------------- | ---------------------------------------------------------------------- | ------------------------- |
| CT status                 | **NO-GO / BLOCKED** — потрібні JSON + новий AAB + Sign-In smoke        | STAGE1 / CT_SMOKE         |
| Release AAB (CT)          | **pending rebuild** після `android/firebase/prod/google-services.json` | STAGE1                    |
| Rejected local AAB        | `1463fd4c…` (без Firebase resources) — **не** upload                   | STAGE1                    |
| Legacy AAB (superseded)   | `398b83f3…` @ `2ef0fcd…` / old package — **не** upload                 | historical                |
| versionName / versionCode | `2.1.6` / `6`                                                          | SoT / presets             |
| Package (release / debug) | `com.Averixor.Lost_Number` / `com.Averixor.Lost_Number.dev`            | SoT / STAGE1              |
| **Негайний OWNER крок**   | Firebase JSON → rebuild → Auth QA → потім CT                           | AUTH_SIGNIN_QA / SEQUENCE |

Upload key fingerprints (звірити з Console): [`docs/PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md).

## OWNER checklist (усі ☐ — не чіпати з агента)

### Closed testing / якість

- [ ] Closed testing трек доступний тестерам + Play opt-in smoke пройдено
- [ ] Немає відкритих P0 / P1 з CT feedback
- [ ] Save / load / `.bak` recovery OK на пристрої
- [ ] Phase 5 device perf sign-off (немає помітних UI / grid регресій після довгої сесії)
- [ ] Фінальний AAB ↔ `main` SHA записаний і збігається з тим, що в Closed testing (оновити STAGE1 record якщо перезбірка)
- [ ] Console identity / blockers зрозумілі ([`PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md))

### Product / privacy approve

- [ ] Явне OWNER approve: **Google Auth** + **Cloud Save** (Phase 6)
- [ ] Privacy / Data safety Console forms match Auth B2 ([`FIREBASE_PRIVACY_DELTA.md`](FIREBASE_PRIVACY_DELTA.md); `INTERNET` уже true)

### Console / env (перед 4A)

- [ ] Firebase проєкти `lost-number-dev` / `lost-number-prod` створені ([`FIREBASE_OWNER_RUNBOOK.md`](FIREBASE_OWNER_RUNBOOK.md))
- [ ] Android apps: `com.Averixor.Lost_Number` + `.dev`; SHA-1/256 для debug / upload / Play App Signing зареєстровані
- [ ] Firestore region підтверджена OWNER (рекомендація kickoff: **`europe-west3`**)
- [ ] Budget alerts налаштовані; secrets layout без commit реальних `google-services.json`

## Runtime blocked (Cloud Save / 4B+)

Auth B2 (`LostNumberFirebase`, `AuthManager`, `INTERNET=true`) **вже в коді**. Нижче — що ще заборонено до OWNER flip gates для **Cloud Save**:

| Заборонено                              | Примітка                             |
| --------------------------------------- | ------------------------------------ |
| Cloud Save / Firestore runtime          | Stage 4B після CT GO + OWNER approve |
| `CloudSyncManager` / cloud conflict UI  | Після Cloud Save approve             |
| Commit реальних `google-services.json`  | Gitignored; лише example у репо      |
| Crashlytics / Analytics / Remote Config | Не вмикати «заодно»                  |
| 4C leaderboards                         | Окремо після Cloud Save sign-off     |

## Runtime workstreams (deferred — blocked)

Усі нижче **скасовані / заблоковані**, доки OWNER не закриє цей gates-файл. Не реалізовувати й не позначати completed.

| ID             | Зміст                                         | Наступна гілка (з плану)          |
| -------------- | --------------------------------------------- | --------------------------------- |
| **4A bridge**  | Kotlin plugin + GDScript bridge; без Cloud UI | `godot/firebase-android-bridge`   |
| **4A auth**    | AuthManager states/signals                    | `godot/firebase-auth-manager`     |
| **4A rules**   | Firestore rules + emulator tests              | `firebase/firestore-rules`        |
| **4B codec**   | Envelope / validation / checksum              | `godot/cloud-save-codec`          |
| **4B sync**    | CloudSyncManager, queue, retry, revisions     | `godot/cloud-save-sync`           |
| **4B UI**      | Settings Cloud panel + conflict dialog + i18n | `godot/cloud-conflict-ui`         |
| **4B privacy** | Privacy / Data safety / SoT / STAGE1 forms    | `docs/firebase-privacy-console`   |
| **4B QA**      | Device QA + `godot:verify:aab` + CT Firebase  | `godot/cloud-save-device-qa` + CT |
| **4C later**   | Leaderboards після Cloud Save sign-off        | `godot/firebase-leaderboards`     |

Повна послідовність PR: див. план Stage 4 / [`ROADMAP.md`](ROADMAP.md) § Етап 4.

## Після flip gates

1. OWNER: усі обовʼязкові ☐ → `[x]` у цьому файлі (окремий docs PR або commit).
2. Старт runtime: **`godot/firebase-android-bridge`** (лише інфраструктура).
3. Далі — послідовність 4A → 4B з плану; 4C окремо.

## Повʼязані документи

- **OWNER sequence (спочатку):** [`FIREBASE_STAGE4_SEQUENCE.md`](FIREBASE_STAGE4_SEQUENCE.md)
- ADR: [`docs/en/FIREBASE_ADR.md`](en/FIREBASE_ADR.md)
- OWNER Console: [`docs/FIREBASE_OWNER_RUNBOOK.md`](FIREBASE_OWNER_RUNBOOK.md)
- Privacy delta: [`docs/FIREBASE_PRIVACY_DELTA.md`](FIREBASE_PRIVACY_DELTA.md)
- Secrets example: [`android/firebase/`](../android/firebase/)
- Rules example: [`docs/firebase/firestore.rules.example`](firebase/firestore.rules.example)
