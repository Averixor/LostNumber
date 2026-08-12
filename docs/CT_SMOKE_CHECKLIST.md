# Closed testing smoke — OWNER checklist

| Поле                | Значення                                                              |
| ------------------- | --------------------------------------------------------------------- |
| Статус CT           | **OWNER pending** — агент **не** ставить GO і **не** flip → completed |
| Docs / source       | `main` @ `8f1a7c2` (merge #81 + verified AAB 2026-08-12)              |
| Install джерело     | **Google Play** після opt-in (не sideload debug APK як CT smoke)      |
| Firebase / INTERNET | **Заборонено** до CT **GO**                                           |

Повний runbook: [`CLOSED_TESTING_RUNBOOK.md`](CLOSED_TESTING_RUNBOOK.md). Sequence далі: [`FIREBASE_STAGE4_SEQUENCE.md`](FIREBASE_STAGE4_SEQUENCE.md). Recon: [`PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md).

---

## CT candidate

> Вантажити **лише AAB**. Debug APK і будь-який файл з cert SHA1 `00:D9:4E:BB…` — **reject**. Upload key має бути `43:93:42:63…`.

```text
build/android/lost-number.aab
SHA-256: 5c0530b0028d105be01332698092080044e92dd95934224c283b1789d5481104
source:  8f1a7c2376bef44dfcb875339138ea5afd4f3729
version: 2.1.6 / VC 16
package: com.averixor.lostnumber
cert SHA-1: 43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3
```

### Repo verification (агент, 2026-08-12 — не замінює Console)

| Перевірка                        | Результат                                          |
| -------------------------------- | -------------------------------------------------- |
| `sha256sum` локального AAB       | **match** `5c0530b0…`                              |
| AAB upload cert SHA-1            | **match** `43:93:42:63…` (`godot:verify:aab` gate) |
| Upload keystore SHA-1 / SHA-256  | **match** таблиці в PLAY_CONSOLE_RECON             |
| Console Upload key == локальний? | ☐ OWNER (App integrity → **Upload** key only)      |
| VC16 уже upload у Console?       | ☐ так → **стоп**, bump VC17 / ☐ ні / ☐ ніколи      |

Локальні fingerprints (звірити з Console **Upload key**):

| Алгоритм | Відбиток                                                                                          |
| -------- | ------------------------------------------------------------------------------------------------- |
| SHA-1    | `43:93:42:63:7F:1D:1B:26:F7:9A:DF:24:D8:34:31:58:FA:C2:AA:C3`                                     |
| SHA-256  | `35:B0:4D:F7:D7:CE:62:48:94:F8:83:FF:77:BB:51:69:2F:9B:DB:3A:C5:44:22:AF:6A:EC:87:8A:C3:A4:E8:97` |

Якщо SHA-256 файлу ≠ `5c0530b0…`, cert ≠ `43:93:42:63…`, або VC16 already used → **не** вантажити цей AAB.

---

## Paste-чеклист (строго по порядку)

```text
Closed testing smoke — Lost Number 2.1.6 / VC16
AAB SHA-256: 5c0530b0028d105be01332698092080044e92dd95934224c283b1789d5481104

PRE-UPLOAD (обовʼязково):
[ ] 0a. Upload key SHA у Console == таблиця вище (не App signing key)
[ ] 0b. VC16 ніколи не upload (інакше STOP → godot/release-play-v17 + новий AAB)
[ ] 0c. Файл = lost-number.aab (НЕ lost-number-debug.apk)

SMOKE:
[ ] 1. Upload AAB без signing error
[ ] 2. Play opt-in → Accept → Install з Google Play
[ ] 3. Boot — без зависання / ANR
[ ] 4. Main Menu працює
[ ] 5. Валідний merge
[ ] 6. Збереження прогресу
[ ] 7. Force-stop застосунку
[ ] 8. Повторний запуск
[ ] 9. Restore — той самий рівень / сітка / XP (не лише «відкрилось»)
[ ] 10. Android Back — без крашу
[ ] 11. Записати GO або NO-GO нижче (P0/P1 → NO-GO)
```

---

## Результат (заповнює OWNER)

| Поле           | Значення                                       |
| -------------- | ---------------------------------------------- |
| Дата           | \_\_\_\_-\_\_-\_\_                             |
| Пристрій       | \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ |
| AAB SHA-256    | `5c0530b0…`                                    |
| AAB source SHA | `8f1a7c2…`                                     |
| Upload SHA OK  | ☐ так / ☐ ні                                   |
| VC16 unused    | ☐ так / ☐ ні (був → VC17 AAB)                  |
| Вердикт        | ☐ **GO** / ☐ **NO-GO**                         |
| P0 / P1        | none / список: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_  |
| Нотатки        | \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ |

### Після вердикту

| Вердикт   | Дія                                                                                                    |
| --------- | ------------------------------------------------------------------------------------------------------ |
| **GO**    | CT `pending` → `completed` у [`STAGE3_CLOSEOUT.md`](STAGE3_CLOSEOUT.md) + gates; далі Phase 5…         |
| **NO-GO** | CT лишається `pending`; P0/P1 у нотатках; **не** flip Firebase gates; **не** `INTERNET` / SDK / bridge |

Скопіюй заповнену таблицю в PR `docs/ct-smoke-result` або встав у closeout / gates notes.
