# Closed testing smoke — OWNER checklist

| Поле                | Значення                                                                |
| ------------------- | ----------------------------------------------------------------------- |
| Статус CT           | **PRE-UPLOAD READY** (2026-10-03) — потрібен Play upload + opt-in smoke |
| Docs / source       | `main` @ `cac9cfe` (+ локальний Auth-ready AAB rebuild)                 |
| Install джерело     | **Google Play** після opt-in (sideload лише для локального Auth QA)     |
| Package (release)   | **`com.Averixor.Lost_Number`**                                          |
| Firebase / INTERNET | prod JSON + oauth_client OK; AAB містить Firebase resources             |

Повний runbook: [`CLOSED_TESTING_RUNBOOK.md`](CLOSED_TESTING_RUNBOOK.md). Auth QA: [`AUTH_SIGNIN_QA.md`](AUTH_SIGNIN_QA.md). Recon: [`PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md).

---

## CT candidate

> Вантажити **лише AAB**. Debug APK і будь-який файл з cert SHA1 `00:D9:4E:BB…` — **reject**. Upload key має бути `43:93:42:63…`.
>
> **Заборонено upload:** AAB `1463fd4c…` (немає Firebase resources + старий bridge до P0) і legacy `5c0530b0…` / package `com.averixor.lostnumber`.
> Після додавання `android/firebase/prod/google-services.json` — **перезібрати** AAB і вписати **новий** SHA нижче.

```text
build/android/lost-number.aab
SHA-256: 93f72b58943f108de6197d1b7934f8f8713f482eebd81ca822cf6d560b423ad3
source:  local Auth-ready rebuild 2026-10-03; code on main @ cac9cfe
version: 2.1.6 / VC 6
package: com.Averixor.Lost_Number
cert SHA-1: 43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3
gates:   npm run release:check PASS; npm run godot:verify:aab PASS; keystore:info PASS
```

### Repo verification (агент — не замінює Console)

| Перевірка                        | Результат                                                        |
| -------------------------------- | ---------------------------------------------------------------- |
| Upload keystore SHA-1 / SHA-256  | **match** (2026-10-03)                                           |
| AAB upload cert SHA-1            | **match** `43:93:42:63…` (`godot:verify:aab`)                    |
| Firebase resources у AAB         | **PASS** (`google_app_id` + `default_web_client_id` + project)   |
| Console Upload key == локальний? | ☐ OWNER (App integrity → **Upload** key only)                    |
| Positive Google Sign-In smoke    | **PASS** sideload 2026-08-14; **Play CT install** ще не виконано |

Локальні fingerprints (звірити з Console **Upload key**):

| Алгоритм | Відбиток                                                                                          |
| -------- | ------------------------------------------------------------------------------------------------- |
| SHA-1    | `43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3`                                     |
| SHA-256  | `35:B0:4D:F7:D7:CE:62:48:94:F8:83:FF:77:BB:51:69:2F:9B:DB:3A:C5:44:22:AF:6A:EC:87:8A:C3:A4:E8:97` |

Якщо cert ≠ `43:93:42:63…`, немає Firebase resources, або Sign-In smoke FAIL → **не** вантажити AAB.

---

## Paste-чеклист (строго по порядку)

```text
Closed testing smoke — Lost Number 2.1.6 / VC6
package: com.Averixor.Lost_Number
AAB SHA-256: 93f72b58943f108de6197d1b7934f8f8713f482eebd81ca822cf6d560b423ad3

PRE-UPLOAD (обовʼязково):
[x] 0a. Upload key SHA локально == таблиця вище (Console — OWNER)
[x] 0b. AAB має google_app_id / default_web_client_id (release:check PASS 2026-10-03)
[ ] 0c. Device Auth smoke PASS на цьому білді (не firebase_not_configured)
[x] 0d. Файл = lost-number.aab (НЕ lost-number-debug.apk)
[x] 0e. SHA ≠ 1463fd4c… і ≠ 5c0530b0… (candidate 93f72b58…)

SMOKE:
[ ] 1. Upload AAB без signing error
[ ] 2. Play opt-in → Accept → Install з Google Play
[ ] 3. Boot — без зависання / ANR
[ ] 4. Main Menu працює
[ ] 5. Валідний merge
[ ] 6. Збереження прогресу
[ ] 7. Force-stop застосунку
[ ] 8. Повторний запуск
[ ] 9. Restore — той самий рівень / сітка / XP (не лише «відкрилось»)
[ ] 10. Android Back — без крашу
[ ] 11. Settings → Google Sign-In (optional) працює
[ ] 12. Записати GO або NO-GO нижче (P0/P1 → NO-GO)
```

---

## Результат (заповнює OWNER)

| Поле           | Значення                                                           |
| -------------- | ------------------------------------------------------------------ |
| Дата           | 2026-10-03                                                         |
| Пристрій       | ☐ після Play install                                               |
| AAB SHA-256    | `93f72b58943f108de6197d1b7934f8f8713f482eebd81ca822cf6d560b423ad3` |
| AAB source SHA | `main` @ `cac9cfe` (+ local Auth-ready AAB)                        |
| Upload SHA OK  | ☑ так (upload cert `43:93…`, `godot:verify:aab`)                   |
| Auth smoke OK  | ☐ Play CT / ☑ історичний sideload 2026-08-14                       |
| Вердикт        | **NO-GO** (Play CT upload + install smoke ще не виконані)          |
| P0 / P1        | OWNER: Console upload AAB `93f72b58…` → opt-in → smoke 1–11        |
| Нотатки        | Pre-upload gates PASS 2026-10-03; Play Android Publisher API N/A   |

### Після вердикту

| Вердикт   | Дія                                                                                            |
| --------- | ---------------------------------------------------------------------------------------------- |
| **GO**    | CT `pending` → `completed` у [`STAGE3_CLOSEOUT.md`](STAGE3_CLOSEOUT.md) + gates; далі Phase 5… |
| **NO-GO** | CT лишається `pending`; P0/P1 у нотатках; **не** flip Firebase Cloud Save gates                |

Скопіюй заповнену таблицю в PR `docs/ct-smoke-result` або встав у closeout / gates notes.
