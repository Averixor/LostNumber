# Play Console recon — Lost Number

Дата підготовки: 2026-08-04  
Локальний upload keystore: `android/keystore/lostnumber-upload-2026.jks`  
Alias: `lostnumber_upload`

## Локальні fingerprints (звірити з Console)

Отримано через `npm run keystore:info` (паролі не виводяться в git):

| Алгоритм    | Відбиток                                                                                          |
| ----------- | ------------------------------------------------------------------------------------------------- |
| **SHA-1**   | `43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3`                                     |
| **SHA-256** | `35:B0:4D:F7:D7:CE:62:48:94:F8:83:FF:77:BB:51:69:2F:9B:DB:3A:C5:44:22:AF:6A:EC:87:8A:C3:A4:E8:97` |

**Власник:** Play Console → Setup → App integrity → App signing → **Upload key certificate**.  
Якщо SHA не збігається — не завантажуйте AAB; потрібен правильний keystore або reset upload key.

Сертифікат: `CN=Averixor, OU=Lost Number, O=Averixor, L=Kyiv, ST=Kyiv, C=UA`  
Створено: 2026-07-23; дійсний до ~2053.

## Чеклист власника (заповнити вручну)

| #   | Питання                                                          | Відповідь (власник)                 |
| --- | ---------------------------------------------------------------- | ----------------------------------- |
| 1   | Upload cert SHA-1 у Console = таблиця вище?                      | ☐ так / ☐ ні                        |
| 2   | Чи є в App bundle explorer / Latest releases **versionCode 16**? | ☐ так / ☐ ні / ☐ ніколи не upload   |
| 3   | Identity verification (перевірка особи)                          | ☐ pending / ☐ approved / ☐ rejected |
| 4   | Max versionCode, який уже приймав Console                        | ______                              |
| 5   | Closed testing track створено?                                   | ☐ так / ☐ ні                        |

## Рішення по versionCode (після пункту 2)

| Факт Console                         | Дія в репо                                                                                                                   |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| VC16 ніколи не завантажувався        | можна було залишити 16; **у репо вже піднято до 17 / 2.1.7** для безпечного наступного upload (пропуск коду дозволений Play) |
| VC16 уже був (draft/rejected/active) | обов’язково **≥17** — виконано в `export_presets.cfg` + `package.json`                                                       |

## Privacy

- URL: https://averixor.github.io/LostNumber/privacy.html
- Перевірка 2026-08-04: **HTTP 200**

## Команди

```bash
npm run keystore:info
curl -sI https://averixor.github.io/LostNumber/privacy.html | head -5
```

Після заповнення таблиці власником — переходити до `docs/CLOSED_TESTING_RUNBOOK.md`.
