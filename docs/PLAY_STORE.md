# Google Play — закритe тестування та публікація

Підготовка для **Lost Number** (`com.averixor.lostnumber`). Повноцінна публікація в Production можлива після **завершення перевірки особи** в Google Play Console.

## Швидкий статус

| Артефакт                         | Шлях / команда                                                                        |
| -------------------------------- | ------------------------------------------------------------------------------------- |
| Release AAB                      | `npm run android:bundle` → `android/app/build/outputs/bundle/release/app-release.aab` |
| Release APK (локальна перевірка) | `npm run android:release`                                                             |
| Іконка Play (512)                | `store/play-high-res-icon-512.png`                                                    |
| Feature graphic                  | `store/feature-graphic-1024x500.png`                                                  |
| Чернетки скріншотів              | `store/screenshots/phone/`                                                            |
| Описи магазину                   | `docs/store-listing/` + **`store/PLAY_CONSOLE_LISTING.md`** (все поля в одном месте)  |
| Privacy Policy URL               | `https://averixor.github.io/LostNumber/privacy.html`                                  |

## 1. Збірка AAB

```bash
cd ~/git/LostNumber
npm run release:check
npm run android:bundle
```

Потрібен `android/keystore.properties` (не в git). Приклад:

```properties
storeFile=release-keystore.jks
storePassword=***
keyAlias=upload
keyPassword=***
```

Після збірки завантажте **app-release.aab** у Play Console.

## 2. Графіка для Play Console

```bash
python3 scripts/generate-android-icons.py   # mipmap у APK
python3 scripts/prepare-play-store-assets.py # store/ для Console
```

| Тип               | Вимога Google Play | Файл у репо                          |
| ----------------- | ------------------ | ------------------------------------ |
| High-res icon     | 512×512 PNG        | `store/play-high-res-icon-512.png`   |
| Feature graphic   | 1024×500           | `store/feature-graphic-1024x500.png` |
| Phone screenshots | ≥2, портрет 9:16   | `store/screenshots/phone/*.png`      |

**Важливо:** поточні скріншоти в `store/screenshots/phone/` — **чернетки з фонів меню**. Перед публічним релізом замініть на реальні знімки з телефона (меню з UI, гра, налаштування). Див. `store/screenshots/phone/README.md`.

## 3. Privacy Policy

- Файл: `privacy.html` (копіюється в `_site/` при `npm run build:pages`)
- URL для Play Console: **https://averixor.github.io/LostNumber/privacy.html**
- Після зміни політики: `npm run build:pages` + деплой GitHub Pages

## 4. Заповнення сторінки застосунку

Скопіюйте тексти з:

- `docs/store-listing/short-description-uk.txt` (80 символів)
- `docs/store-listing/full-description-uk.txt`
- `docs/store-listing/short-description-en.txt`
- `docs/store-listing/full-description-en.txt`

**Категорія:** Games → Puzzle  
**Теги (приклад):** puzzle, numbers, logic, casual, offline  
**Контакт:** `ryabinin.sergei.alekseevich@gmail.com` (див. `store/PLAY_CONSOLE_LISTING.md`)
**Ціна:** безкоштовно

## 5. Закрите тестування (Closed testing)

Поки триває перевірка особи, можна готувати трек:

1. [Google Play Console](https://play.google.com/console) → **Lost Number**
2. **Testing → Closed testing** → Create track (наприклад `closed-beta`)
3. **Testers** → список email (Google-акаунти) або Google Group
4. **Releases** → Create new release → завантажити `app-release.aab`
5. Release notes (укр.):

   ```
   Перший закритий тест Lost Number 1.0.
   Офлайн головоломка з числами, рівнями, бонусами та локальним збереженням.
   ```

6. **Review and roll out** (після завершення identity verification)

Тестери отримають посилання **opt-in** з Console (Testing → Closed testing → How testers join).

### Internal testing (опційно)

Для швидкої перевірки команди (до 100 тестерів, без review на перший upload у деяких регіонах):

**Testing → Internal testing** → той самий AAB.

## 6. Контентний рейтинг (IARC)

**Policy → App content → Content rating** — заповнити анкету **чесно**:

| Питання                     | Відповідь                                          |
| --------------------------- | -------------------------------------------------- |
| Категорія                   | Гра / головоломка                                  |
| Насильство, секс, наркотики | Ні                                                 |
| Gambling                    | Ні (колесо фортуни — ігровий XP, не реальні гроші) |
| IAP / paid random items     | Ні                                                 |
| User-generated content      | Ні                                                 |
| Online interaction          | Ні (офлайн)                                        |
| Реклама                     | Ні                                                 |

Очікуваний результат: **Everyone / 3+**.

## 6b. Цільова аудиторія

**Policy → App content → Target audience and content**:

- **Ні** — «застосунок переважно для дітей»
- **Так** — широка аудиторія / усі віки
- **Не** вмикати Designed for Families без окремої програми Google

## 7. Data safety

**Policy → App content → Data safety** — вказати **фактичну** відсутність збору персональних даних:

| Питання                                       | Відповідь                                            |
| --------------------------------------------- | ---------------------------------------------------- |
| Збирає або передає дані користувачів?         | **Ні**                                               |
| Усі типи даних (ім'я, email, геолокація тощо) | **Не збирається**                                    |
| Шифрування при передачі                       | Не застосовується                                    |
| Видалення даних                               | Користувач очищає дані застосунку в Android          |
| Privacy policy URL                            | `https://averixor.github.io/LostNumber/privacy.html` |

Локальний прогрес у `localStorage` **не передається** на сервери розробника — у формі це «дані не збираються».

Додатково в **App content**: Ads — No; In-app purchases — No.

Потрібен успішний деплой privacy URL — див. [GITHUB_PAGES.md](./GITHUB_PAGES.md).

Детальна таблиця відповідей: **`store/PLAY_CONSOLE_LISTING.md`** → розділ «Политики Google Play».

## 8. Чекліст перед Production

- [ ] Перевірка особи завершена
- [ ] `npm run release:check` зелений
- [ ] AAB зібраний з release flags (`cheatsEnabled=false`)
- [ ] Скріншоти з реального APK на телефоні
- [ ] Privacy policy опублікована (URL відкривається)
- [ ] IARC (Content rating) заповнено чесно
- [ ] Target audience — **не** «переважно для дітей»
- [ ] Data safety — «дані не збираються»
- [ ] Email підтримки вказано в Store listing
- [ ] Closed testing пройдено без критичних багів
- [ ] versionCode збільшено для наступного релізу (`android/app/build.gradle`)

## 9. Версіонування

Поточна версія в `android/app/build.gradle`:

- `versionCode 1`
- `versionName "1.0"`

Кожен новий upload у Play Console потребує **versionCode + 1**.

## 10. Корисні команди

```bash
npm run android:sync          # оновити web assets у android/
npm run android:release       # signed APK
npm run android:bundle        # signed AAB для Play
python3 scripts/prepare-play-store-assets.py
```

Див. також: [ANDROID.md](./ANDROID.md), [ANDROID_QA.md](./ANDROID_QA.md).
