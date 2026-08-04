# Privacy / Data safety delta — Firebase Cloud Save

> **Зараз (kickoff):** мережі немає; `INTERNET=false`; цей документ — **план змін**, не факт у проді.  
> Коли runtime увімкне Auth + Firestore + `INTERNET=true`, оновити `privacy.html`, Play Data safety, [`STAGE1_CONSOLE_FORMS.md`](STAGE1_CONSOLE_FORMS.md), SoT в **тій самій** хвилі PR (`docs/firebase-privacy-console`).

## Що зміниться (коли Stage 4 runtime увімкнено)

| До (сьогодні)                      | Після Firebase-capable build                              |
| ---------------------------------- | --------------------------------------------------------- |
| Повністю offline                   | Optional cloud: Google Sign-In + sync progress            |
| Немає UID / хмарного прогресу      | Firebase Auth UID; Firestore save envelope                |
| Немає мережевих дозволів для cloud | `INTERNET` + `ACCESS_NETWORK_STATE` (лише в Firebase PR)  |
| Гра без акаунта — норма            | Залишається: гра **без** акаунта / мережі (offline-first) |

## Дані, що очікуються в хмарі

| Категорія (Play Data safety)     | Приклад вмісту                                         | Примітка                                   |
| -------------------------------- | ------------------------------------------------------ | ------------------------------------------ |
| App activity / gameplay progress | Рівні, очки, unlocks у `payload`                       | Необхідно для Cloud Save                   |
| App info and performance         | `appVersion`, `versionCode`, sync metadata, `revision` | Мінімум для конфліктів / діагностики       |
| Device or other IDs              | Firebase Auth `uid`; opaque `deviceId`                 | Не логінити зайвий PII в Firestore         |
| Personal info (email)            | Лише якщо Auth/SDK реально обробляє account email      | **Мінімізувати**; не дублювати email у doc |

**Не** завантажувати: custom background images, OAuth tokens, local keystores, зайві контакти/photos.

## Crashlytics / Analytics

| Продукт              | Kickoff / Stage 4 MVP       |
| -------------------- | --------------------------- |
| Firebase Crashlytics | **НЕ** вмикати автоматично  |
| Google Analytics     | **НЕ** вмикати автоматично  |
| Remote Config        | **НЕ** в першому Cloud Save |

Окреме OWNER-рішення + окремий privacy delta, якщо колись знадобляться.

## Контролі користувача (обовʼязково в 4B UI)

1. **Opt-in** — Sign in Google (хмарне збереження вимкнене за замовчуванням / явний вхід).
2. **Sync** — ручний sync + політики з ADR (після local save).
3. **Sign out** — вихід з акаунта без обовʼязкового wipe локального сейву.
4. **Delete cloud data** — видалення `users/{uid}/save/current` (і повʼязаних cloud docs за правилами).
5. **Account deletion path** — процедура видалення акаунта (Play / support); **без** авто-wipe локального `user://` сейву.
6. **Retention** — описати в privacy policy (як довго зберігаємо cloud save після delete request).
7. **Support contact** — канал у privacy / About для запитів на дані.

## Conflict UI (privacy UX)

Діалог keep local / use remote / cancel — користувач свідомо обирає, яка копія прогресу залишається canonical локально після конфлікту. Без тихого field-merge.

## Документи для оновлення в privacy PR

- `privacy.html` + [`PRIVACY_HOSTING.md`](PRIVACY_HOSTING.md)
- Play Console Data safety form
- [`STAGE1_CONSOLE_FORMS.md`](STAGE1_CONSOLE_FORMS.md)
- [`docs/en/SOURCE_OF_TRUTH.md`](en/SOURCE_OF_TRUTH.md) (Network / Cloud rows)
- Inventory / store listing якщо згадують «offline only» без застереження

## Посилання

- Gates: [`FIREBASE_STAGE4_GATES.md`](FIREBASE_STAGE4_GATES.md)
- ADR: [`en/FIREBASE_ADR.md`](en/FIREBASE_ADR.md)
- OWNER Console: [`FIREBASE_OWNER_RUNBOOK.md`](FIREBASE_OWNER_RUNBOOK.md)
