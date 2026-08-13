# Play Console recon — Lost Number

Дата оновлення: **2026-08-13**  
Listing: **`com.Averixor.Lost_Number`** (новий; не `com.averixor.lostnumber`)  
Ship version у git: **2.1.6 / versionCode 6** (`godot/export_presets.cfg`)  
CT status: **NO-GO** до Firebase JSON + нового AAB + Sign-In smoke — [`STAGE1_RELEASE_RECORD.md`](STAGE1_RELEASE_RECORD.md), [`CT_SMOKE_CHECKLIST.md`](CT_SMOKE_CHECKLIST.md)  
Локальний upload keystore: `android/keystore/lostnumber-upload-2026.jks`  
Alias: `lostnumber_upload`

## Локальні fingerprints (звірити з Console)

| Алгоритм    | Відбиток                                                                                          |
| ----------- | ------------------------------------------------------------------------------------------------- |
| **SHA-1**   | `43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3`                                     |
| **SHA-256** | `35:B0:4D:F7:D7:CE:62:48:94:F8:83:FF:77:BB:51:69:2F:9B:DB:3A:C5:44:22:AF:6A:EC:87:8A:C3:A4:E8:97` |

Play Console → Setup → App integrity → App signing → **Upload key certificate** (не App signing certificate).  
App signing (Google deployment): `37:FB:98:8C:A6:84:03:03:88:F0:5B:35:90:59:CD:87:6B:8C:C3:5E`.

## OWNER — обовʼязково заповнити в Console

| #   | Питання                                        | Відповідь (власник)                 |
| --- | ---------------------------------------------- | ----------------------------------- |
| 1   | Upload cert SHA збігається з таблицею вище?    | ☐ так / ☐ ні                        |
| 2   | Max versionCode у Console для цього listing    | ______                              |
| 3   | Identity verification                          | ☐ pending / ☐ approved / ☐ rejected |
| 4   | Closed testing track існує?                    | ☐ так / ☐ ні                        |
| 4b  | Назва трека / testers group                    | ______                              |
| 5   | Firebase apps + SHA зареєстровані для Sign-In? | ☐ так / ☐ ні                        |

**Якщо п.1 = ні** — **не вантажити** AAB.

## Рішення по versionCode

| Факт Console            | Дія                                     |
| ----------------------- | --------------------------------------- |
| Max VC у Console &lt; 6 | upload **6 / 2.1.6** OK                 |
| Max VC ≥ 6              | bump `export_presets` → max+1 + rebuild |

Не upload: `1463fd4c…`, `5c0530b0…`, `398b83f3…`.

## Автоматично перевірено (репо)

| Перевірка               | Результат                                             |
| ----------------------- | ----------------------------------------------------- |
| Privacy URL             | https://averixor.github.io/LostNumber/privacy.html    |
| Upload key fingerprints | OK (`43:93:42:63…`)                                   |
| Auth B2 у source        | OK (`LostNumberFirebase`, `INTERNET=true`)            |
| `release:check`         | FAIL без Firebase resources у AAB (очікувано до JSON) |

Далі: [`CLOSED_TESTING_RUNBOOK.md`](CLOSED_TESTING_RUNBOOK.md), [`AUTH_SIGNIN_QA.md`](AUTH_SIGNIN_QA.md).
