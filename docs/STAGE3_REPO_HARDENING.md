# Stage 3 — repo hardening baseline (після PR #58)

Дата старту: **2026-08-04**

> **Historical.** Current ship identity: `com.Averixor.Lost_Number` / VC **6** — [`docs/en/SOURCE_OF_TRUTH.md`](en/SOURCE_OF_TRUTH.md), [`STAGE1_RELEASE_RECORD.md`](STAGE1_RELEASE_RECORD.md).

## Git / базова точка (на момент Stage 3)

| Поле                                   | Значення                                   |
| -------------------------------------- | ------------------------------------------ |
| Stage 3 base SHA (main HEAD після #58) | `f2d69ddb08413c7f0746f5aff1bfb8d2dd32614d` |
| Ship version (тоді)                    | `2.1.6` / VC16 (legacy listing)            |
| Package (тоді)                         | `com.averixor.lostnumber`                  |
| Current package (2026-08-13+)          | `com.Averixor.Lost_Number` / VC **6**      |

## Closed testing (AAB candidate)

> Legacy Stage 3 candidate — **superseded**. Current CT = **NO-GO** ([`CT_SMOKE_CHECKLIST.md`](CT_SMOKE_CHECKLIST.md)).

| Поле                     | Значення                                     |
| ------------------------ | -------------------------------------------- |
| Closed testing (Stage 3) | `pending` → superseded                       |
| Legacy AAB SHA-256       | `398b83f3…` @ `2ef0fcd…` — **не** upload     |
| Current CT AAB           | pending rebuild after `google-services.json` |

## Last verified CI (для base SHA)

| Check                 | Result    | Run/Job                                                                         |
| --------------------- | --------- | ------------------------------------------------------------------------------- |
| `release-check`       | `success` | https://github.com/Averixor/LostNumber/actions/runs/30894328279/job/91943513720 |
| `Godot tests (4.7.1)` | `success` | https://github.com/Averixor/LostNumber/actions/runs/30894328279/job/91943513673 |

## Junk rescan (з “TЗ §3”, як підтвердження гігієни репо)

Виконав на base SHA:

```bash
git ls-files | rg '(^godot/icon\.svg\.broken$|^godot/scenes/Boot\.tscn\.bak$|^godot/project\.godot\.soft-gothic-|^godot/GothicUiStyler\.gd\.soft-gothic-|^project\.godot\.soft-gothic-|^icon-1024\.png\.import$)'
```

Результат: **0 збігів** (після попередніх Stage1/2 очисток).

## Repo risks (коротко)

- Перехід на Stage 3 може тригернути новий AAB SHA після Android adaptive icon / bundletool gating.
- Docs/SoT можуть дрейфувати від реальних export preset’ів (контроль через `release:check` і `godot:verify:aab`).
