# Stage 1 — Console forms cheat sheet (Auth B2 / optional Google Sign-In)

Копіювати в Play Console. Джерело: [`PLAY_STORE.md`](PLAY_STORE.md), [`FIREBASE_PRIVACY_DELTA.md`](FIREBASE_PRIVACY_DELTA.md), `privacy.html`.  
Listing: [`store/PLAY_CONSOLE_LISTING.md`](../store/PLAY_CONSOLE_LISTING.md).  
Package: **`com.Averixor.Lost_Number`** / VC **6**.

## IARC / Content rating

| Тема                      | Відповідь                             |
| ------------------------- | ------------------------------------- |
| Категорія                 | Гра / головоломка                     |
| Насильство                | Ні                                    |
| Секс                      | Ні                                    |
| Наркотики                 | Ні                                    |
| Gambling на реальні гроші | Ні (колесо = внутрішній XP, не гроші) |
| IAP                       | Ні                                    |
| User-generated content    | Ні                                    |
| Online interaction        | Опційний Google Sign-In (не чат)      |
| Реклама                   | Ні                                    |

## Target audience

Широка аудиторія. **Не** заявляти «переважно для дітей». **Не** Designed for Families без окремого PO-рішення.

## Data safety (Auth B2)

| Питання                   | Відповідь                                              |
| ------------------------- | ------------------------------------------------------ |
| Збір даних користувача    | Так, **опційно** при Google Sign-In                    |
| Передача даних            | Google / Firebase Auth (акаунт); **немає** Cloud Save  |
| Локальне збереження       | Так — `user://` на пристрої                            |
| Користувацький фон        | Локально                                               |
| INTERNET permission       | **Так** (Auth-capable)                                 |
| Analytics / Crashlytics   | Ні                                                     |
| Реклама / IAP             | Ні                                                     |

Cloud Save / Firestore — окрема хвиля Data safety після Stage 4B.
