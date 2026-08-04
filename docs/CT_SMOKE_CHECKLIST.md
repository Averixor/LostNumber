# Closed testing smoke — OWNER checklist

| Поле                | Значення                                                                 |
| ------------------- | ------------------------------------------------------------------------ |
| Статус              | **OWNER pending** — агент **не** ставить GO і **не** flip CT → completed |
| Install джерело     | **Google Play** після opt-in (не sideload debug APK як CT smoke)         |
| Firebase / INTERNET | **Заборонено** до CT **GO**                                              |

Локальний файл AAB (перевірено в середовищі агента 2026-08-04):

```text
build/android/lost-number.aab
SHA-256: 398b83f33d79b878e71ca1262d6cfac2e0a981045d77299a5c0824c1dba848c4
source:  2ef0fcdf2aaf5083cf79c88a41b989720e137b47
version: 2.1.6 / VC 16
package: com.averixor.lostnumber
```

Перед upload звірити Upload key SHA з [`PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md).  
Якщо Console уже мав VC16 → **не** вантажити цей AAB; спочатку bump VC17.

Повний runbook: [`CLOSED_TESTING_RUNBOOK.md`](CLOSED_TESTING_RUNBOOK.md). Sequence далі: [`FIREBASE_STAGE4_SEQUENCE.md`](FIREBASE_STAGE4_SEQUENCE.md).

---

## Paste-чеклист (виконувати строго по порядку)

```text
Closed testing smoke — Lost Number 2.1.6 / VC16
AAB SHA-256: 398b83f33d79b878e71ca1262d6cfac2e0a981045d77299a5c0824c1dba848c4

[ ] 1. Upload AAB у Closed testing (файл з SHA вище; немає signing error)
[ ] 2. Play opt-in → Accept → Install з Play
[ ] 3. Boot — splash → без зависання / ANR
[ ] 4. Main Menu — читабельне, CTA працюють
[ ] 5. merge — хоча б один валідний ланцюг
[ ] 6. save — прогрес записався (звичайний flow гри)
[ ] 7. force-stop → relaunch з іконки / Play
[ ] 8. restore — Continue / load: той самий прогрес (рівень / сітка / XP)
[ ] 9. Android Back — Game→Menu або exit, без крашу
[ ] 10. Записати GO або NO-GO нижче (немає P0/P1 для GO)
```

---

## Результат (заповнює OWNER)

| Поле           | Значення                                       |
| -------------- | ---------------------------------------------- |
| Дата           | \_\_\_\_-\_\_-\_\_                             |
| Пристрій       | \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ |
| AAB SHA-256    | `398b83f3…` (або новий record після rebuild)   |
| AAB source SHA | `2ef0fcd…`                                     |
| Вердикт        | ☐ **GO** / ☐ **NO-GO**                         |
| P0 / P1        | none / список: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_  |
| Нотатки        | \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ |

### Після вердикту

| Вердикт   | Дія                                                                                                                                                                    |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **GO**    | Оновити CT `pending` → `completed` у [`STAGE3_CLOSEOUT.md`](STAGE3_CLOSEOUT.md) + відповідні ☐ у [`FIREBASE_STAGE4_GATES.md`](FIREBASE_STAGE4_GATES.md); далі Phase 5… |
| **NO-GO** | Залишити CT `pending`; зафіксувати P0/P1; **не** flip gates; **не** Firebase / `INTERNET`                                                                              |

Скопіюй заповнену таблицю в PR `docs/ct-smoke-result` або встав у closeout / gates notes.
