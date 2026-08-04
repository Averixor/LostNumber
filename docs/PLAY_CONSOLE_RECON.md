# Play Console recon — Lost Number

Дата оновлення: 2026-08-04  
Релізна база git: **`2ef0fcdf2aaf5083cf79c88a41b989720e137b47`** (`main`, post-adaptive CT candidate)  
Ship version у git: **2.1.6 / versionCode 16** (не bump до факту Console)  
AAB SHA-256 (див. [`STAGE1_RELEASE_RECORD.md`](STAGE1_RELEASE_RECORD.md)): `398b83f33d79b878e71ca1262d6cfac2e0a981045d77299a5c0824c1dba848c4`  
Старі candidates `a6db8b29` / `c9e315af…` — **superseded**, не upload.  
Локальний upload keystore: `android/keystore/lostnumber-upload-2026.jks`  
Alias: `lostnumber_upload`

## Локальні fingerprints (звірити з Console)

Отримано через `npm run keystore:info` (2026-08-04, re-verified перед CT upload handoff):

| Алгоритм    | Відбиток                                                                                          |
| ----------- | ------------------------------------------------------------------------------------------------- |
| **SHA-1**   | `43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3`                                     |
| **SHA-256** | `35:B0:4D:F7:D7:CE:62:48:94:F8:83:FF:77:BB:51:69:2F:9B:DB:3A:C5:44:22:AF:6A:EC:87:8A:C3:A4:E8:97` |

Play Console → Setup → App integrity → App signing → **Upload key certificate** (не App signing certificate).

## OWNER — обовʼязково заповнити в Console (блокер upload)

Ці поля **недоступні з репо**. Без них DoD етапу 1 у Console не закритий.

| #   | Питання                                         | Відповідь (власник)                 |
| --- | ----------------------------------------------- | ----------------------------------- |
| 1   | Upload cert SHA збігається з таблицею вище?     | ☐ так / ☐ ні                        |
| 2   | Чи є **versionCode 16** серед uploaded bundles? | ☐ так / ☐ ні / ☐ ніколи             |
| 3   | Identity verification                           | ☐ pending / ☐ approved / ☐ rejected |
| 4   | Max versionCode у Console                       | ______                              |
| 5   | Closed testing track існує?                     | ☐ так / ☐ ні                        |
| 5b  | Назва трека / testers group                     | ______                              |

**Якщо п.1 = ні** — **не вантажити** AAB (спочатку правильний keystore / Play upload key reset).

## Автоматично перевірено (репо / мережа)

| Перевірка                  | Результат                                                       |
| -------------------------- | --------------------------------------------------------------- |
| Privacy HTTP               | **200** (`curl -sI`, 2026-08-04 re-check)                       |
| Privacy URL                | https://averixor.github.io/LostNumber/privacy.html              |
| Локальний keystore + alias | OK (`lostnumber_upload`)                                        |
| CI на `2ef0fcd`            | green (`release-check` + Godot 4.7.1) — run 30907149534         |
| `npm run godot:verify:aab` | **OK** — [`STAGE1_RELEASE_RECORD.md`](STAGE1_RELEASE_RECORD.md) |
| Phone screenshots ≥2 real  | OK — `01-menu-dark`, `02-gothic-style` (RGB, no alpha)          |
| IARC / Data safety cheat   | [`STAGE1_CONSOLE_FORMS.md`](STAGE1_CONSOLE_FORMS.md)            |

## Рішення по versionCode (робоче до факту п.2)

| Факт Console             | Дія                                                   |
| ------------------------ | ----------------------------------------------------- |
| VC16 ніколи не upload    | залишити **16 / 2.1.6** — **поточне рішення Stage 1** |
| VC16 уже був (п.2 = так) | окремий PR `godot/release-play-v17` → **17 / 2.1.7**  |

До заповнення пункту 2 власником **не змінювати** `export_presets.cfg` / `package.json`.  
Поточна робоча збірка Stage 1: **16 / 2.1.6** на SHA вище; AAB SHA-256 у release record.

Далі: [`CLOSED_TESTING_RUNBOOK.md`](CLOSED_TESTING_RUNBOOK.md), [`STAGE1_RELEASE_RECORD.md`](STAGE1_RELEASE_RECORD.md), [`ROADMAP.md`](ROADMAP.md).
