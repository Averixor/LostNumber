# Google Play Console — Lost Number

Готові поля для **Store listing** (основна локаль листингу — українська).  
Повна процедура публікації: **[docs/PLAY_STORE.md](../docs/PLAY_STORE.md)**.

Файли графіки: `npm run store:prepare` → папка `store/`.

---

## Основні поля

| Поле                   | Значення                                             |
| ---------------------- | ---------------------------------------------------- |
| **Назва**              | `Lost Number`                                        |
| **Категорія**          | **Ігри** → **Головоломки** (Games → Puzzle)          |
| **Email підтримки**    | `ryabinin.sergei.alekseevich@gmail.com`              |
| **Privacy Policy URL** | `https://averixor.github.io/LostNumber/privacy.html` |

> **Privacy URL** має відкриватися в браузері до відправки на перевірку. Якщо GitHub Pages недоступний — див. [docs/GITHUB_PAGES.md](../docs/GITHUB_PAGES.md).

---

## Короткий опис (до 80 символів)

**Українська** — скопіювати в Play Console:

```
Логічна головоломка з числами. Рівні, бонуси, збереження прогресу.
```

(67 символів)

**English** (додаткова локаль):

```
Calm number grid puzzle. Levels, bonuses, offline save.
```

(54 characters)

**Русский** (додаткова локаль):

```
Логическая головоломка с числами. Уровни, бонусы, сохранение прогресса.
```

(70 символов)

Файли: `docs/store-listing/short-description-*.txt`

---

## Повний опис

### Українська

```
Lost Number — логічна головоломка з числами у зручному для тебе темпі.

Поєднуй сусідні клітинки, будуй ланцюжки з правильних сум і відкривай нові рівні. Жодного зайвого тиску — грай коли зручно.

Що всередині:
• Сітка 5×8 і зростаюча складність
• Бонуси: вибух, перемішування, знищення клітинки
• Колесо фортуни за очки XP
• Щоденні завдання та досягнення
• Дві візуальні теми та кілька фонів меню
• Збереження прогресу на пристрої (офлайн)
• Українська, російська та англійська мови

Підходить для коротких сесій і розминки для мозку. Без реєстрації та без реклами в поточній версії.
```

### English

```
Lost Number is a relaxed number grid puzzle you can enjoy on your schedule.

Connect neighboring tiles, build valid chains, and unlock new levels. No rush — play when it suits you.

Features:
• 5×8 grid with growing difficulty
• Bonuses: explosion, shuffle, destroy tile
• Fortune wheel for XP rewards
• Daily quests and achievements
• Two visual themes and multiple menu backgrounds
• Progress saved locally on your device (offline)
• Ukrainian, Russian, and English UI

Great for short sessions and brain warm-ups. No account required. No ads in the current release.
```

### Русский

```
Lost Number — логическая головоломка с числами в удобном для вас темпе.

Соединяйте соседние клетки, стройте цепочки с нужными суммами и открывайте новые уровни. Без лишнего давления — играйте когда удобно.

В игре:
• Сетка 5×8 и постепенное усложнение
• Бонусы: взрыв, перемешивание, уничтожение клетки
• Колесо фортуны за очки XP
• Ежедневные задания и достижения
• Две темы оформления и несколько фонов меню
• Сохранение прогресса на устройстве (офлайн)
• Украинский, русский и английский языки

Короткие сессии и тренировка логики. Без регистрации и без рекламы в текущей версии.
```

Файли: `docs/store-listing/full-description-*.txt`

---

## Графіка (завантажити в Console)

| Тип                 | Файл                                            | Розмір                  |
| ------------------- | ----------------------------------------------- | ----------------------- |
| **Іконка**          | `store/play-high-res-icon-512.png`              | 512×512 PNG             |
| **Feature graphic** | `store/feature-graphic-1024x500.png`            | 1024×500 PNG            |
| **Скріншоти**       | `store/screenshots/phone/01-*.png` … `04-*.png` | 1080×1920 PNG (портрет) |

Мінімум **2** скріншоти. Рекомендовано 4–8. Перед публічним релізом замініть чернетки на знімки з реального APK (меню, гра, налаштування). Див. `store/screenshots/phone/README.md`.

---

## Додатково в Console

| Поле                     | Рекомендація                            |
| ------------------------ | --------------------------------------- |
| **Тип застосунку**       | Гра                                     |
| **Безкоштовно / платно** | Безкоштовно                             |
| **Теги**                 | puzzle, numbers, logic, casual, offline |
| **Цільова аудиторія**    | Everyone / 3+ (після IARC)              |
| **Package name**         | `com.averixor.lostnumber`               |
| **Версія**               | `2.1.4` (versionCode 14)                |

---

## Політики Google Play

Повні таблиці IARC, Target audience, Data safety і production-чекліст — у **[docs/PLAY_STORE.md](../docs/PLAY_STORE.md)** (розділи 6–8).

Коротко:

- IARC — чесно: головоломка, без насильства / реклами / IAP
- Target audience — **не** «переважно для дітей»
- Data safety — **дані не збираються** (лише `localStorage` на пристрої)
- Ads, IAP, Financial features — **No**

---

## Чекліст листингу

1. [ ] `npm run store:prepare`
2. [ ] Завантажити іконку, feature graphic, скріншоти
3. [ ] Вставити описи (UK + EN + RU)
4. [ ] Email і Privacy URL (див. вище)
5. [ ] Категорія: Games → Puzzle
6. [ ] Далі — [docs/PLAY_STORE.md](../docs/PLAY_STORE.md): IARC, Data safety, AAB у Closed testing
