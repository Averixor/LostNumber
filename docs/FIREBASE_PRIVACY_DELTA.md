# Privacy / Data safety delta — Firebase Auth (Sign-In only)

> **Зараз (B2):** `INTERNET=true`; optional Google Sign-In; **немає** Cloud Save / Firestore.
> Коли з’явиться Cloud Save, розширити цей delta + Data safety у тій самій хвилі PR.

## Що змінилось у B2

| До                                  | Після B2                                                         |
| ----------------------------------- | ---------------------------------------------------------------- |
| Повністю offline (`INTERNET=false`) | Опційний Google Sign-In; гра без акаунта лишається нормою        |
| Немає UID                           | Firebase Auth UID після явного входу                             |
| Немає мережі для Auth               | `INTERNET` + `ACCESS_NETWORK_STATE`                              |
| privacy: «INTERNET не запитується»  | privacy: optional Google Sign-In; Analytics/Crashlytics вимкнені |

## Дані Auth (без Cloud Save)

| Категорія (Play Data safety) | Приклад                       | Примітка                                          |
| ---------------------------- | ----------------------------- | ------------------------------------------------- |
| Personal info (account)      | Google account / display name | Opt-in Sign-In; мінімізувати email у власних docs |
| Device or other IDs          | Firebase Auth `uid`           | Локальний UI-кеш `user://auth_session.json`       |

**Не** завантажувати: ігровий прогрес у Firestore, custom backgrounds, OAuth tokens у plaintext поза SDK.

## Crashlytics / Analytics

| Продукт              | B2                    |
| -------------------- | --------------------- |
| Firebase Auth        | **Так** (Google only) |
| Firestore / Cloud    | **Ні**                |
| Firebase Crashlytics | **НІ**                |
| Google Analytics     | **НІ**                |
| Remote Config        | **НІ**                |

## Контролі користувача (B2)

1. Opt-in Sign in Google (Settings).
2. Sign out — без wipe локального сейву.
3. Гра повністю без акаунта.

## Документи оновлені в цій хвилі

- `privacy.html`
- [`docs/en/SOURCE_OF_TRUTH.md`](en/SOURCE_OF_TRUTH.md)
- Play Console Data safety — OWNER оновлює форму під optional Account info / App activity = local only

## Посилання

- ADR: [`en/FIREBASE_ADR.md`](en/FIREBASE_ADR.md)
- OWNER: [`FIREBASE_OWNER_RUNBOOK.md`](FIREBASE_OWNER_RUNBOOK.md)
- QA: [`docs/AUTH_SIGNIN_QA.md`](AUTH_SIGNIN_QA.md)
