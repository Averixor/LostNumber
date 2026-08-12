# Stage 1 — Release record (Closed testing candidate)

Дата запису: **2026-08-12**  
Статус: **готово до OWNER upload** — лише `lost-number.aab` з upload key SHA1 `43:93:42:63…` (не debug APK)

## Git / версія

| Поле                      | Значення                                   |
| ------------------------- | ------------------------------------------ |
| AAB source branch         | `main`                                     |
| AAB source commit SHA     | `8f1a7c2376bef44dfcb875339138ea5afd4f3729` |
| versionName               | **2.1.6**                                  |
| versionCode               | **16**                                     |
| Package (release)         | `com.averixor.lostnumber`                  |
| Package (device QA debug) | `com.averixor.lostnumber.dev`              |

**Version gate:** KEEP **16 / 2.1.6** до факту Console. Якщо VC16 уже uploaded → STOP і bump `17 / 2.1.7`. Див. [`PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md).

**Signing note (2026-08-12):** Play відхилив APK з SHA1 `00:D9:4E:BB…` (чужий keystore). Правильний upload key — нижче. Вантажити **тільки AAB** з цього record.

## AAB артефакт

| Поле       | Значення                                                           |
| ---------- | ------------------------------------------------------------------ |
| Path       | `build/android/lost-number.aab`                                    |
| Size       | **141355037** bytes (~135 MiB)                                     |
| SHA-256    | `5c0530b0028d105be01332698092080044e92dd95934224c283b1789d5481104` |
| Built      | 2026-08-12 18:19:35 +0300 (`npm run godot:verify:aab`)             |
| Cert SHA-1 | `43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3`      |

## Upload key fingerprints

| Алгоритм | Відбиток                                                                                          |
| -------- | ------------------------------------------------------------------------------------------------- |
| SHA-1    | `43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3`                                     |
| SHA-256  | `35:B0:4D:F7:D7:CE:62:48:94:F8:83:FF:77:BB:51:69:2F:9B:DB:3A:C5:44:22:AF:6A:EC:87:8A:C3:A4:E8:97` |

## Verifier

| Gate                              | Результат                                                                   |
| --------------------------------- | --------------------------------------------------------------------------- |
| `npm run godot:verify:aab`        | **OK** (tests + release:check + export + unzip + **upload-key SHA-1 gate**) |
| Upload-key SHA-1 gate             | **OK** match `43:93:42:63…`                                                 |
| `export_presets.cfg` after export | clean (no keystore passwords)                                               |
| bundletool / aapt2 dump           | пропущено локально (`bundletool.jar` відсутній → warning)                   |

## Historical (superseded — не upload)

| Candidate               | SHA-256 / note                           |
| ----------------------- | ---------------------------------------- |
| Rejected wrong-cert APK | cert SHA1 `00:D9:4E:BB…` — **не** upload |
| RC 2026-08-10           | AAB `727a4e74…` @ `67019bc…`             |
| Stage1 2026-08-04       | AAB `398b83f3…` @ `2ef0fcdf…`            |
| Local drift Aug 10      | AAB `d240b736…`                          |

## Owner upload

1. Play Console → App integrity → **Upload key** SHA == таблиця вище
2. Max versionCode: якщо ≥16 → bump VC17 перед upload
3. Upload **тільки** `build/android/lost-number.aab` (не `lost-number-debug.apk`)
4. Smoke: [`CT_SMOKE_CHECKLIST.md`](CT_SMOKE_CHECKLIST.md) / [`CLOSED_TESTING_RUNBOOK.md`](CLOSED_TESTING_RUNBOOK.md)
