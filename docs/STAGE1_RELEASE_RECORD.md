# Stage 1 — Release record (Closed testing candidate)

Дата запису: **2026-08-04**  
Статус: **готово до OWNER upload** (Console credentials з репо недоступні)

## Git / версія

| Поле                                | Значення                                   |
| ----------------------------------- | ------------------------------------------ |
| AAB source branch                   | `main`                                     |
| AAB source commit SHA               | `a6db8b2939f1379eeca057f53ae7987d77ce954a` |
| Repo baseline main HEAD (після #58) | `f2d69ddb08413c7f0746f5aff1bfb8d2dd32614d` |
| versionName                         | **2.1.6**                                  |
| versionCode                         | **16**                                     |
| Package (release)                   | `com.averixor.lostnumber`                  |
| Package (device QA debug)           | `com.averixor.lostnumber.dev`              |

**Version gate:** KEEP **16 / 2.1.6**. Немає факту Console, що VC16 уже uploaded → bump PR `godot/release-play-v17` **не** створювався. Див. [`PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md).

## AAB артефакт

| Поле    | Значення                                                           |
| ------- | ------------------------------------------------------------------ |
| Path    | `build/android/lost-number.aab`                                    |
| Size    | **141349967** bytes (~135 MiB)                                     |
| SHA-256 | `6aef26d6ee02ef54162e4f97758ce42c0b0a66ed488100c6334fe743b6f7b52b` |
| Built   | 2026-08-04 12:24:58 +0300 (під час `npm run godot:verify:aab`)     |

> Якщо AAB перезібрати — оновити SHA-256 і дату в цьому файлі перед upload.

## Verifier

| Gate                               | Результат                                                                                                                |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `npm run godot:verify:aab`         | **OK** (exit 0)                                                                                                          |
| `godot:test:all` (у складі verify) | OK                                                                                                                       |
| `release:check`                    | OK (вкл. Play Store screenshots RGB, no alpha)                                                                           |
| Unzip gates                        | OK: no dev/cheat/DebugOverlay; `libgodot_android.so` arm64+x86_64; no `assets/store/`; no `scripts/tests/`               |
| bundletool / aapt2 dump            | пропущено (`bundletool.jar` відсутній) — versionCode підтверджено `export_presets.cfg` + `release:check` (VC 16 / 2.1.6) |

## Screenshots (Stage 1)

| Файл                                          | Статус                                                            |
| --------------------------------------------- | ----------------------------------------------------------------- |
| `store/screenshots/phone/01-menu-dark.png`    | **Реальний** phone (меню uk) 1080×1920 RGB                        |
| `store/screenshots/phone/02-gothic-style.png` | **Реальний** phone (геймплей) 1080×1920 RGB                       |
| `03` / `04`                                   | Promo drafts (достатньо для Stage1 ≥2; Stage2 → Settings + Wheel) |

## Device QA

Див. таблицю GO/NO-GO у [`ANDROID_QA.md`](ANDROID_QA.md).

## Owner upload

Див. [`CLOSED_TESTING_RUNBOOK.md`](CLOSED_TESTING_RUNBOOK.md) + handoff у кінці runbook. Upload **лише власник Console**.
