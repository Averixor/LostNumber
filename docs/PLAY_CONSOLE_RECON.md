# Play Console recon — Lost Number

Дата: 2026-08-04  
Ship version у git: **2.1.6 / versionCode 16** (не bump до факту Console)  
Локальний upload keystore: `android/keystore/lostnumber-upload-2026.jks`  
Alias: `lostnumber_upload`

## Локальні fingerprints (звірити з Console)

Отримано через `npm run keystore:info`:

| Алгоритм    | Відбиток                                                                                          |
| ----------- | ------------------------------------------------------------------------------------------------- |
| **SHA-1**   | `43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3`                                     |
| **SHA-256** | `35:B0:4D:F7:D7:CE:62:48:94:F8:83:FF:77:BB:51:69:2F:9B:DB:3A:C5:44:22:AF:6A:EC:87:8A:C3:A4:E8:97` |

Play Console → Setup → App integrity → App signing → **Upload key certificate**.

## Чеклист власника

| #   | Питання                                         | Відповідь                           |
| --- | ----------------------------------------------- | ----------------------------------- |
| 1   | Upload cert SHA збігається з таблицею?          | ☐ так / ☐ ні                        |
| 2   | Чи є **versionCode 16** серед uploaded bundles? | ☐ так / ☐ ні / ☐ ніколи             |
| 3   | Identity verification                           | ☐ pending / ☐ approved / ☐ rejected |
| 4   | Max versionCode у Console                       | ______                              |
| 5   | Closed testing track існує?                     | ☐ так / ☐ ні                        |

## Рішення по versionCode

| Факт Console          | Дія                                                  |
| --------------------- | ---------------------------------------------------- |
| VC16 ніколи не upload | залишити **16 / 2.1.6**                              |
| VC16 уже був          | окремий PR `godot/release-play-v17` → **17 / 2.1.7** |

До заповнення пункту 2 **не змінювати** `export_presets.cfg` / `package.json`.

## Privacy

- URL: [privacy.html](https://averixor.github.io/LostNumber/privacy.html)
- Перевірити `curl -sI` → очікується HTTP 200 (окремо підтвердити перед upload)

Далі: [`docs/CLOSED_TESTING_RUNBOOK.md`](CLOSED_TESTING_RUNBOOK.md), [`docs/ROADMAP.md`](ROADMAP.md).
