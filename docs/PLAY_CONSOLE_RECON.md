# Play Console recon — Lost Number

Дата оновлення: **2026-10-03**  
Listing: **`com.Averixor.Lost_Number`** (новий; не `com.averixor.lostnumber`)  
Ship version у git: **2.1.7 / versionCode 7** (`godot/export_presets.cfg`)  
CT status: **PRE-UPLOAD READY** (AAB `d10d3f2e…`, 2.1.7 / 7) — Play upload + smoke OWNER — [`STAGE1_RELEASE_RECORD.md`](STAGE1_RELEASE_RECORD.md), [`CT_SMOKE_CHECKLIST.md`](CT_SMOKE_CHECKLIST.md)  
Локальний upload keystore: `android/keystore/lostnumber-upload-2026.jks`  
Alias: `lostnumber_upload`  
**Перед upload:** max VC у новому listing був **5**; VC6 superseded. Кандидат = **7 / 2.1.7**. Якщо 7 вже був — bump до `max+1`.  
**Account deletion URL (після Pages 200):** `https://averixor.github.io/LostNumber/delete-account.html`

## Локальні fingerprints (звірити з Console)

| Алгоритм    | Відбиток                                                                                          |
| ----------- | ------------------------------------------------------------------------------------------------- |
| **SHA-1**   | `43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3`                                     |
| **SHA-256** | `35:B0:4D:F7:D7:CE:62:48:94:F8:83:FF:77:BB:51:69:2F:9B:DB:3A:C5:44:22:AF:6A:EC:87:8A:C3:A4:E8:97` |

Play Console → Setup → App integrity → App signing → **Upload key certificate** (не App signing certificate).  
App signing (Google deployment): `37:FB:98:8C:A6:84:03:03:88:F0:5B:35:90:59:CD:87:6B:8C:C3:5E`.

## OWNER — обовʼязково заповнити в Console

| #   | Питання                                                         | Відповідь (власник)                                |
| --- | --------------------------------------------------------------- | -------------------------------------------------- |
| 1   | Upload cert SHA збігається з таблицею вище?                     | ☐ так / ☐ ні                                       |
| 2   | Max versionCode у **новому** listing `com.Averixor.Lost_Number` | **5** (OWNER 2026-10-03; `5.aab` / 2.1.6 Internal) |
| 3   | Identity verification                                           | ☐ pending / ☐ approved / ☐ rejected                |
| 4   | Closed testing track існує?                                     | ☐ так / ☐ ні                                       |
| 4b  | Назва трека / testers group                                     | ______                                             |
| 5   | Firebase apps + SHA зареєстровані для Sign-In?                  | ☐ так / ☐ ні                                       |

**Якщо п.1 = ні** — **не вантажити** AAB.

## Рішення по versionCode

| Факт Console                        | Дія                                                |
| ----------------------------------- | -------------------------------------------------- |
| Max VC у **новому** listing ≤ **6** | upload **7 / 2.1.7** (VC6 `93f72b58…` superseded)  |
| Max VC у **новому** listing ≥ 7     | bump `versionName + versionCode` → max+1 + rebuild |
| Account deletion declaration        | URL `…/delete-account.html` після Pages 200        |

### Legacy listing (не CT target)

OWNER 2026-10-03: Play Console для **`com.averixor.lostnumber`** (opt-in URL `…/apps/test/com.averixor.lostnumber/14`) має max **versionCode 14** / `2.1.4` (targetSdk 35, без INTERNET/Auth). Це **інший** app listing — **не** вантажити туди поточний AAB **2.1.7 / VC7** (`com.Averixor.Lost_Number`).

Не upload: `1463fd4c…`, `5c0530b0…`, `398b83f3…`, legacy VC14 track.

## Автоматично перевірено (репо)

| Перевірка               | Результат                                                                      |
| ----------------------- | ------------------------------------------------------------------------------ |
| Privacy URL             | https://averixor.github.io/LostNumber/privacy.html                             |
| Upload key fingerprints | OK (`43:93:42:63…`)                                                            |
| Auth B2 у source        | OK (`LostNumberFirebase`, `INTERNET=true`)                                     |
| `release:check`         | **PASS** 2026-10-03 (Firebase resources у AAB)                                 |
| `godot:verify:aab`      | **PASS** 2026-10-03 (cert `43:93…`, VC6, targetSdk 36)                         |
| Candidate AAB SHA-256   | `d10d3f2ea8170e005a67e7201ca27e777ea70f2a319e71f7b1829f3de10b45c1` (2.1.7 / 7) |

Далі: [`CLOSED_TESTING_RUNBOOK.md`](CLOSED_TESTING_RUNBOOK.md), [`AUTH_SIGNIN_QA.md`](AUTH_SIGNIN_QA.md).
