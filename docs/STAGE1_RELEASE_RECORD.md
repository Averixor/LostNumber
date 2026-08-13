# Stage 1 — Release record (новий Play listing + Auth B2)

Дата запису: **2026-08-14**  
Статус: **Auth-ready AAB локально** — CT ще потребує OWNER Sign-In smoke + Play upload  
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

**Signing note:** Upload key — лише `43:93:42:63…`. Вантажити **тільки AAB**.

## Signing

| Роль                            | SHA-1                                                         |
| ------------------------------- | ------------------------------------------------------------- |
| App signing (Google deployment) | `37:FB:98:8C:A6:84:03:03:88:F0:5B:35:90:59:CD:87:6B:8C:C3:5E` |
| Upload (локальний JKS / AAB)    | `43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3` |
| Debug keystore (device QA)      | `3F:54:CA:7D:63:33:D0:B6:E7:5C:7A:97:52:02:0B:6E:F9:46:CD:35` |

## Upload key fingerprints

| Алгоритм | Відбиток                                                                                          |
| -------- | ------------------------------------------------------------------------------------------------- |
| SHA-1    | `43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3`                                     |
| SHA-256  | `35:B0:4D:F7:D7:CE:62:48:94:F8:83:FF:77:BB:51:69:2F:9B:DB:3A:C5:44:22:AF:6A:EC:87:8A:C3:A4:E8:97` |

## AAB артефакт (Auth-ready candidate)

| Поле        | Значення                                                           |
| ----------- | ------------------------------------------------------------------ |
| Path        | `build/android/lost-number.aab`                                    |
| SHA-256     | `c85ee34032a0b0abfab78dbe4b50d2dd35e05fb14aa8d8a020c96104ee507d52` |
| Package     | `com.Averixor.Lost_Number`                                         |
| versionCode | **6**                                                              |
| Built       | 2026-08-14 (prod `google-services.json` + oauth_client type 3)     |
| Firebase    | `google_app_id` / `default_web_client_id` / project — **present**  |
| CT status   | **READY for OWNER smoke** після USB/Play install + Sign-In QA      |

## Verifier

| Gate                      | Результат (2026-08-14)              |
| ------------------------- | ----------------------------------- |
| `npm run release:check`   | **PASS** з Firebase resources у AAB |
| Upload-key SHA-1          | `43:93:42:63…`                      |
| Firebase resource strings | PASS                                |

## Owner upload notes

1. `android/firebase/prod/google-services.json` — на місці (gitignored); Web OAuth client OK.
2. Для debug: створити Android app `com.Averixor.Lost_Number.dev` + SHA debug `3F:54:CA:7D…` → `android/firebase/dev/google-services.json`.
3. Device QA: [`AUTH_SIGNIN_QA.md`](AUTH_SIGNIN_QA.md).
4. USB install може вимагати підтвердження на телефоні (`INSTALL_FAILED_USER_RESTRICTED`).
5. Старий `com.averixor.lostnumber` — інший listing.

## Historical (superseded — не upload)

| Candidate               | SHA-256 / note                                           |
| ----------------------- | -------------------------------------------------------- |
| Auth B2 без JSON        | AAB `1463fd4c…` — **не** CT                              |
| Pre-oauth empty client  | rebuild до `c85ee340…`                                   |
| Legacy listing VC16     | AAB `5c0530b0…` @ `8f1a7c2…` / `com.averixor.lostnumber` |
| Rejected wrong-cert APK | cert SHA1 `00:D9:4E:BB…` — **не** upload                 |

## Owner upload

1. Play Console → Upload key SHA == таблиця вище
2. Upload **`c85ee340…`** `lost-number.aab` (або новіший після наступної перезбірки)
3. Smoke: [`CT_SMOKE_CHECKLIST.md`](CT_SMOKE_CHECKLIST.md)
