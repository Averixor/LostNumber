# Stage 1 — Release record (Closed testing candidate)

Дата запису: **2026-08-04**  
Статус: **готово до OWNER upload** (Console credentials з репо недоступні)

## Git / версія

| Поле                      | Значення                                   |
| ------------------------- | ------------------------------------------ |
| Branch                    | `main`                                     |
| Commit SHA                | `a6db8b2939f1379eeca057f53ae7987d77ce954a` |
| versionName               | **2.1.6**                                  |
| versionCode               | **16**                                     |
| Package (release)         | `com.averixor.lostnumber`                  |
| Package (device QA debug) | `com.averixor.lostnumber.dev`              |

**Version gate:** KEEP **16 / 2.1.6**. Немає факту Console, що VC16 уже uploaded → bump PR `godot/release-play-v17` **не** створювався. Див. [`PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md).

## AAB артефакт

| Поле    | Значення                                                           |
| ------- | ------------------------------------------------------------------ |
| Path    | `build/android/lost-number.aab`                                    |
| Size    | **142491081** bytes (~136 MiB)                                     |
| SHA-256 | `c9e315afcf27aacc19a5d69b823d8e035da8c07cca8f9bbbcedb6617e5321be6` |
| Built   | 2026-08-04 08:54:52 +0300 (під час `npm run godot:verify:aab`)     |

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
