# Stage 4 Firebase — hard gates (OWNER)

| Поле             | Значення                                                    |
| ---------------- | ----------------------------------------------------------- |
| Статус runtime   | **BLOCKED** — не починати 4A / 4B / 4C код                  |
| Kickoff docs     | Готово (цей файл + ADR / OWNER runbook / privacy delta)     |
| Offline-first    | Залишається; Firebase **optional** після go                 |
| `INTERNET` зараз | `false` в обох Android presets (`godot/export_presets.cfg`) |

> **Правило:** Stage 3 hygiene / repo closeout **не** замінює Closed testing.  
> Агент **не** відмічає OWNER-чекбокси з репо. Лише OWNER ставить `[x]` після факту.  
> **Порядок дій OWNER (walkable):** [`FIREBASE_STAGE4_SEQUENCE.md`](FIREBASE_STAGE4_SEQUENCE.md) — CT smoke → Phase 5 → privacy → Auth/Cloud approve → Console → SHA/region → **потім** цей файл `[x]` → bridge.

## Поточний факт Closed testing

| Поле                      | Значення                                                                  | Джерело                    |
| ------------------------- | ------------------------------------------------------------------------- | -------------------------- |
| CT status                 | **`pending`** (Play opt-in / device smoke **не** виконано з репо)         | `docs/STAGE3_CLOSEOUT.md`  |
| Release AAB source commit | `2ef0fcdf2aaf5083cf79c88a41b989720e137b47`                                | STAGE1 / STAGE3            |
| Release AAB SHA-256       | `398b83f33d79b878e71ca1262d6cfac2e0a981045d77299a5c0824c1dba848c4`        | STAGE1 / STAGE3            |
| versionName / versionCode | `2.1.6` / `16`                                                            | STAGE1                     |
| Package (release / debug) | `com.averixor.lostnumber` / `com.averixor.lostnumber.dev`                 | SoT / STAGE1               |
| Docs sequence on main     | PR **#72** MERGED — `docs/FIREBASE_STAGE4_SEQUENCE.md` walkable path      | git                        |
| main HEAD (docs)          | `de01730b295acf7f8dce2850d8d3121fb843aa27` (merge #72; **не** AAB source) | git                        |
| **Негайний OWNER крок**   | **CT smoke** — [`CT_SMOKE_CHECKLIST.md`](CT_SMOKE_CHECKLIST.md)           | SEQUENCE §1 / CT checklist |

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
- [ ] Privacy review виконаний ([`FIREBASE_PRIVACY_DELTA.md`](FIREBASE_PRIVACY_DELTA.md) + оновлення policy/Data safety у хвилі з `INTERNET=true`)

### Console / env (перед 4A)

- [ ] Firebase проєкти `lost-number-dev` / `lost-number-prod` створені ([`FIREBASE_OWNER_RUNBOOK.md`](FIREBASE_OWNER_RUNBOOK.md))
- [ ] Android apps: `com.averixor.lostnumber` + `.dev`; SHA-1/256 для debug / upload / Play App Signing зареєстровані
- [ ] Firestore region підтверджена OWNER (рекомендація kickoff: **`europe-west3`**)
- [ ] Budget alerts налаштовані; secrets layout без commit реальних `google-services.json`

## Runtime blocked

Поки будь-який чекбокс вище ☐:

| Заборонено                                    | Примітка                                 |
| --------------------------------------------- | ---------------------------------------- |
| Firebase SDK у Godot / Gradle                 | Немає в kickoff                          |
| Kotlin plugin `LostNumberFirebase`            | Гілка `godot/firebase-android-bridge`    |
| `AuthManager` / `CloudSyncManager` / Cloud UI | Після bridge                             |
| `permissions/internet=true` у export presets  | Лише Firebase-capable PR + privacy хвиля |
| Commit реальних `google-services.json`        | Gitignored; лише example у репо          |
| Crashlytics / Analytics / Remote Config       | Не вмикати «заодно»                      |
| 4C leaderboards                               | Окремо після Cloud Save sign-off         |

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
