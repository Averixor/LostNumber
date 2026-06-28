# Google Play Console — Lost Number

Готовые поля для **Store listing** (украинский — основной язык листинга).  
Файлы графики: `npm run store:prepare` → папка `store/`.

---

## Основные поля

| Поле                   | Значение                                             |
| ---------------------- | ---------------------------------------------------- |
| **Название**           | `Lost Number`                                        |
| **Категория**          | **Игры** → **Головоломки** (Games → Puzzle)          |
| **Email поддержки**    | `ryabinin.sergei.alekseevich@gmail.com`              |
| **Privacy Policy URL** | `https://averixor.github.io/LostNumber/privacy.html` |

> **Privacy URL:** работает после деплоя GitHub Pages. Пока Pages выключен — временно укажите другой хостинг или опубликуйте `privacy.html` (см. `docs/PLAY_STORE.md`).

---

## Краткое описание (до 80 символов)

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

## Полное описание

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

## Графика (загрузить в Console)

| Тип                    | Файл                                            | Размер                  |
| ---------------------- | ----------------------------------------------- | ----------------------- |
| **Иконка**             | `store/play-high-res-icon-512.png`              | 512×512 PNG             |
| **Feature graphic**    | `store/feature-graphic-1024x500.png`            | 1024×500 PNG            |
| **Скриншоты телефона** | `store/screenshots/phone/01-*.png` … `04-*.png` | 1080×1920 PNG (портрет) |

Минимум **2** скриншота для публикации. Рекомендуется 4–8.

Перед публичным релизом замените промо-скриншоты на реальные снимки с телефона (меню, игра, настройки).

---

## Дополнительно в Console

| Поле                   | Рекомендация                                |
| ---------------------- | ------------------------------------------- |
| **Тип приложения**     | Игра                                        |
| **Бесплатно / платно** | Бесплатно                                   |
| **Теги**               | puzzle, numbers, logic, casual, offline     |
| **Целевая аудитория**  | Everyone / 3+ (после анкеты Content rating) |
| **Package name**       | `com.averixor.lostnumber`                   |
| **Версия**             | `1.0` (versionCode 1)                       |

---

## Чеклист загрузки

1. [ ] `npm run store:prepare` — обновить `store/`
2. [ ] Store listing → загрузить иконку, feature graphic, скриншоты
3. [ ] Вставить краткое и полное описание (UK + EN + RU)
4. [ ] Указать email поддержки и Privacy Policy URL
5. [ ] Категория: Games → Puzzle
6. [ ] Testing → Closed testing → загрузить `app-release.aab`

Подробнее: [docs/PLAY_STORE.md](../docs/PLAY_STORE.md)
