# Stage 1 — Release record (Closed testing candidate)

Дата запису: **2026-08-10**  
Статус: **готово до OWNER pre-upload checks** — **не** upload без підтвердження max versionCode у Play Console

## Git / версія

| Поле                       | Значення                                   |
| -------------------------- | ------------------------------------------ |
| AAB source branch          | `release/play-v16`                         |
| AAB base (origin/main)     | `b8c2040d017786c1428f4aa814b5d1f556e1dd81` |
| AAB source commit SHA      |                                            |
| versionName                | **2.1.6**                                  |
| versionCode                | **16**                                     |
| Package (release)          | `com.averixor.lostnumber`                  |
| Package (device QA debug)  | `com.averixor.lostnumber.dev`              |
| Worktree (build host path) | `/home/averixor/Desktop/LostNumber-rc`     |

**Version gate:** KEEP **16 / 2.1.6** — Console max versionCode **не** підтверджено OWNER. Якщо VC16 уже uploaded → STOP і bump `17 / 2.1.7` на `release/play-v17`. Див. [`PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md).

**RC contents (vs `origin/main`):**

- `godot/scripts/ui/MainMenu.gd` — new-game confirmation fit/style
- `godot/assets/i18n/{en,ru,uk}.json` — shorter `start_new_game_confirm`
- `godot/scripts/tests/run_smoke_tests.gd` — viewport fit asserts
- `docs/CT_SMOKE_CHECKLIST.md` — fence fix + new candidate block

**Excluded from this RC:** logo PNG, `gothic_crystal.tres` (залишені в dirty tree / patches на `fix/undici-dependabot-alerts`).

## AAB артефакт

| Поле    | Значення                                                             |
| ------- | -------------------------------------------------------------------- |
| Path    | `/home/averixor/Desktop/LostNumber-rc/build/android/lost-number.aab` |
| Size    | **141353544** bytes (~135 MiB)                                       |
| SHA-256 | `727a4e747ef9a25144c07788bb617e7081ce2c5d2d4bb2a5c8ca971ecef24e67`   |
| Built   | 2026-08-10 22:02:58 +0300 (`npm run godot:verify:aab`)               |

### Debug APK (device QA, не Play)

| Поле    | Значення                                                                   |
| ------- | -------------------------------------------------------------------------- |
| Path    | `/home/averixor/Desktop/LostNumber-rc/build/android/lost-number-debug.apk` |
| SHA-256 | `f2ff4e18651961a01b1e9db14b4cf1f1ee801c5833c58a0bf05024605455da03`         |
| Built   | 2026-08-10 22:01 +0300                                                     |

## Upload key fingerprints

| Алгоритм | Відбиток                                                                                          |
| -------- | ------------------------------------------------------------------------------------------------- |
| SHA-1    | `43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3`                                     |
| SHA-256  | `35:B0:4D:F7:D7:CE:62:48:94:F8:83:FF:77:BB:51:69:2F:9B:DB:3A:C5:44:22:AF:6A:EC:87:8A:C3:A4:E8:97` |

## Verifier

| Gate                               | Результат                                                                                                  |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `npm run godot:verify:aab`         | **OK** (tests + release:check + export + unzip gates)                                                      |
| `godot:test:all` (у складі verify) | OK                                                                                                         |
| `release:check`                    | OK (Prettier fixed on RC docs/i18n)                                                                        |
| Unzip gates                        | OK: no dev/cheat/DebugOverlay; `libgodot_android.so` arm64+x86_64; no `assets/store/`; no `scripts/tests/` |
| `export_presets.cfg` after export  | clean (no keystore passwords)                                                                              |
| bundletool / aapt2 dump            | пропущено локально (`bundletool.jar` відсутній → warning)                                                  |

## Historical (superseded — не upload)

| Candidate                   | SHA-256 / source                                |
| --------------------------- | ----------------------------------------------- |
| Stage1 2026-08-04           | AAB `398b83f3…` @ `2ef0fcdf…`                   |
| Local drift Aug 10 (pre-RC) | AAB `d240b736…` — не відтворюваний RC candidate |
| Earlier superseded          | `a6db8b29` / `c9e315af…`, `6aef26d6…`           |

## Owner upload

Див. [`CLOSED_TESTING_RUNBOOK.md`](CLOSED_TESTING_RUNBOOK.md) + [`CT_SMOKE_CHECKLIST.md`](CT_SMOKE_CHECKLIST.md). Upload **лише власник Console** після VC16 check. **Немає push/upload від агента.**
