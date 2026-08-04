# Stage 3 — repo hardening baseline (після PR #58)

Дата старту: **2026-08-04**

## Git / базова точка

| Поле | Значення |
| --- | --- |
| Stage 3 base SHA (main HEAD після #58) | `f2d69ddb08413c7f0746f5aff1bfb8d2dd32614d` |
| Ship version | `2.1.6` / VC16 |
| Package | `com.averixor.lostnumber` |
| Package (device QA debug) | `com.averixor.lostnumber.dev` |

## Closed testing (AAB candidate)

> Не позначаю як “completed”, доки не підтверджено реальний Play opt-in / device smoke.

| Поле | Значення |
| --- | --- |
| Closed testing | `pending` |
| Release AAB source commit (окремо від main HEAD) | `a6db8b2939f1379eeca057f53ae7987d77ce954a` |
| Release AAB path | `build/android/lost-number.aab` |
| Release AAB SHA-256 | `c9e315afcf27aacc19a5d69b823d8e035da8c07cca8f9bbbcedb6617e5321be6` |

## Last verified CI (для base SHA)

| Check | Result | Run/Job |
| --- | --- | --- |
| `release-check` | `success` | https://github.com/Averixor/LostNumber/actions/runs/30894328279/job/91943513720 |
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

