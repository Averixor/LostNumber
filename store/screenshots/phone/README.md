# Phone screenshots (portrait 1080×1920)

Play Console requires at least **2** phone screenshots. Files must be **RGB** (no alpha) — `npm run release:check` enforces this.

## Stage 1 (Closed testing) — реал з телефону

| Файл                  | Зміст                                     | Статус                      |
| --------------------- | ----------------------------------------- | --------------------------- |
| `01-menu-dark.png`    | Головне меню (uk), LOST NUMBER, CTA, dock | **Реальний** device capture |
| `02-gothic-style.png` | Геймплей: сітка, HUD, бонуси              | **Реальний** device capture |

Достатньо для Stage 1 (≥2 real).

## Stage 2 prep — ще потрібні

| Файл                    | Ціль                                 | Статус                 |
| ----------------------- | ------------------------------------ | ---------------------- |
| `03-levels-bonuses.png` | Settings (або levels/bonuses in-app) | Promo draft — замінити |
| `04-offline-calm.png`   | Wheel / progress                     | Promo draft — замінити |

Рекомендований набір із 4: **Menu / Game / Settings / Wheel**.

## Як зняти

1. `npm run godot:android:install` на arm64.
2. Скрін з телефону (System screenshot) або `adb exec-out screencap -p`.
3. Обрізати/масштабувати до **1080×1920**, конвертувати в **RGB PNG** (без alpha).
4. `npm run release:check` перед комітом.
