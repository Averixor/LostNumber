# Stage 1 — Release record (Closed testing candidate)

Дата запису: **2026-08-04**  
Статус: **готово до OWNER upload** (Console credentials з репо недоступні)

## Git / версія

| Поле                                | Значення                                   |
| ----------------------------------- | ------------------------------------------ |
| AAB source branch                   | `main`                                     |
| AAB source commit SHA               | `2ef0fcdf2aaf5083cf79c88a41b989720e137b47` |
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
| Size    | **141352047** bytes (~135 MiB)                                     |
| SHA-256 | `398b83f33d79b878e71ca1262d6cfac2e0a981045d77299a5c0824c1dba848c4` |
| Built   | 2026-08-04 15:24:00 +0300 (під час `npm run godot:verify:aab`)     |

> Якщо AAB перезібрати — оновити SHA-256 і дату в цьому файлі перед upload.
>
> **Superseded CT candidates (не upload):** `a6db8b29` / `c9e315af…` (pre-adaptive) та проміжний `6aef26d6…` — замінені post-#64 rebuild з `main@2ef0fcd` (adaptive icon + Stage 3 merges + #69).

## Verifier

| Gate                               | Результат                                                                                                  |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `npm run godot:verify:aab`         | **OK** після fix quoting у `scripts/verify-godot-aab.sh` (tests + release:check + export + unzip gates)    |
| `godot:test:all` (у складі verify) | OK                                                                                                         |
| `release:check`                    | OK (вкл. Play Store screenshots RGB, no alpha)                                                             |
| Unzip gates                        | OK: no dev/cheat/DebugOverlay; `libgodot_android.so` arm64+x86_64; no `assets/store/`; no `scripts/tests/` |
| bundletool / aapt2 dump            | пропущено локально (`bundletool.jar` відсутній → warning); у CI gate fail якщо `CI=true` без jar           |

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
