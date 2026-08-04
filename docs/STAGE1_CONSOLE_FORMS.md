# Stage 1 — Console forms cheat sheet (offline product)

Копіювати в Play Console. Джерело правди: [`PLAY_STORE.md`](PLAY_STORE.md), offline ship.  
Listing тексти: [`store/PLAY_CONSOLE_LISTING.md`](../store/PLAY_CONSOLE_LISTING.md).  
Скріншоти: `store/screenshots/phone/` (≥2 real: `01`, `02`).

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
| Online interaction        | Ні                                    |
| Реклама                   | Ні                                    |

## Target audience

Широка аудиторія. **Не** заявляти «переважно для дітей». **Не** Designed for Families без окремого PO-рішення.

## Data safety (поточний offline)

| Питання                   | Відповідь                   |
| ------------------------- | --------------------------- |
| Збір даних користувача    | Ні                          |
| Передача даних розробнику | Ні                          |
| Локальне збереження       | Так — `user://` на пристрої |
| Користувацький фон        | Локально                    |
| INTERNET permission       | Ні                          |
| Реклама / IAP             | Ні                          |

Після Firebase форму переглянути.
