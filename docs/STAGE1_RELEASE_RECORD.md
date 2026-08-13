# Stage 1 — Release record (новий Play listing + Auth B2)

Дата запису: **2026-08-13**  
Статус: **Auth-capable source; CT NO-GO** до `google-services.json` + нового AAB + Sign-In smoke  
Listing: **`com.Averixor.Lost_Number`**

## Git / версія

| Поле              | Значення                                      |
| ----------------- | --------------------------------------------- |
| Package (release) | **`com.Averixor.Lost_Number`**                |
| Package (debug)   | **`com.Averixor.Lost_Number.dev`**            |
| versionName       | **2.1.6**                                     |
| versionCode       | **6**                                         |
| Upload keystore   | `android/keystore/lostnumber-upload-2026.jks` |
| Auth              | Google Sign-In via `LostNumberFirebase`       |
| Cloud Save        | **ні** (наступний PR)                         |
| targetSdk         | **36**                                        |

**Version gate:** VC **1–5** могли вже бути в Console → поточний код **6**. Далі: VC ≥ попереднього + 1.

**Signing note:** Play відхиляє APK/AAB з чужим cert (`00:D9:4E:BB…`). Upload key — лише `43:93:42:63…`. Вантажити **тільки AAB**.

## Signing

| Роль                            | SHA-1                                                         |
| ------------------------------- | ------------------------------------------------------------- |
| App signing (Google deployment) | `37:FB:98:8C:A6:84:03:03:88:F0:5B:35:90:59:CD:87:6B:8C:C3:5E` |
| Upload (локальний JKS / AAB)    | `43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3` |

## Upload key fingerprints

| Алгоритм | Відбиток                                                                                          |
| -------- | ------------------------------------------------------------------------------------------------- |
| SHA-1    | `43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3`                                     |
| SHA-256  | `35:B0:4D:F7:D7:CE:62:48:94:F8:83:FF:77:BB:51:69:2F:9B:DB:3A:C5:44:22:AF:6A:EC:87:8A:C3:A4:E8:97` |

## AAB артефакт (поточний локальний — **не** CT)

| Поле        | Значення                                                           |
| ----------- | ------------------------------------------------------------------ |
| Path        | `build/android/lost-number.aab`                                    |
| SHA-256     | `1463fd4ccc164c569bbc3fde220bdb57ffe8e50e50d29397a81e1cafc615c111` |
| Package     | `com.Averixor.Lost_Number`                                         |
| versionCode | **6**                                                              |
| Built       | 2026-08-13 (Auth B2 bridge; **без** prod `google-services.json`)   |
| CT status   | **REJECT** — немає Firebase resources; потрібен rebuild після JSON |

## Verifier

| Gate                      | Очікування                                                                |
| ------------------------- | ------------------------------------------------------------------------- |
| `npm run release:check`   | FAIL без Firebase resources у AAB (навмисно)                              |
| Upload-key SHA-1 gate     | AAB cert має бути `43:93:42:63…` (`godot:verify:aab`)                     |
| Firebase resource strings | `google_app_id` + `default_web_client_id` + project id обовʼязкові для CT |

## Owner upload notes

1. Покласти gitignored `android/firebase/dev|prod/google-services.json`.
2. Перезібрати debug + release → **новий** AAB SHA (не `1463fd4c…`).
3. Device QA: [`AUTH_SIGNIN_QA.md`](AUTH_SIGNIN_QA.md) — positive Sign-In smoke.
4. Privacy / Data safety: optional Google Sign-In (`privacy.html`).
5. Старий `com.averixor.lostnumber` на девайсі — **інший** listing; не оновить новий.

## Historical (superseded — не upload)

| Candidate               | SHA-256 / note                                           |
| ----------------------- | -------------------------------------------------------- |
| Auth B2 без JSON        | AAB `1463fd4c…` — **не** CT                              |
| Legacy listing VC16     | AAB `5c0530b0…` @ `8f1a7c2…` / `com.averixor.lostnumber` |
| Rejected wrong-cert APK | cert SHA1 `00:D9:4E:BB…` — **не** upload                 |
| RC 2026-08-10           | AAB `727a4e74…` @ `67019bc…`                             |
| Stage1 2026-08-04       | AAB `398b83f3…` @ `2ef0fcdf…`                            |

## Owner upload (після нового AAB)

1. Play Console → App integrity → **Upload key** SHA == таблиця вище
2. Upload **тільки** новий `build/android/lost-number.aab`
3. Smoke: [`CT_SMOKE_CHECKLIST.md`](CT_SMOKE_CHECKLIST.md) / [`CLOSED_TESTING_RUNBOOK.md`](CLOSED_TESTING_RUNBOOK.md)
