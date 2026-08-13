# Google Play — закрите тестування та публікація

Підготовка для **Lost Number** (`com.Averixor.Lost_Number`). Повноцінна публікація в Production можлива після **завершення перевірки особи** в Google Play Console.

## Швидкий статус

| Артефакт                       | Шлях / команда                                                                        |
| ------------------------------ | ------------------------------------------------------------------------------------- |
| Release AAB (Godot)            | `npm run godot:android:release` → `build/android/lost-number.aab`                     |
| Debug APK (локальна перевірка) | `npm run godot:android:debug` → `build/android/lost-number-debug.apk`                 |
| Іконка Play (512)              | `store/play-high-res-icon-512.png`                                                    |
| Feature graphic                | `store/feature-graphic-1024x500.png`                                                  |
| Чернетки скріншотів            | `store/screenshots/phone/`                                                            |
| Описи магазину                 | `docs/store-listing/` + **`store/PLAY_CONSOLE_LISTING.md`** (готові поля для Console) |
| Privacy Policy URL             | `https://averixor.github.io/LostNumber/privacy.html`                                  |

## 1. Збірка AAB

```bash
cd ~/Desktop/LostNumber
npm run release:check
npm run godot:android:release
```

Потрібен `android/keystore.properties` (не в git). У цьому проєкті типово:

```properties
storeFile=keystore/lostnumber-release-2026.jks
storePassword=***
keyAlias=lostnumber_release_2026
keyPassword=***
```

**Не копіюйте** плейсхолдери на кшталт `/путь/к/your-release-key.jks` — це лише приклади з інтернету.

Відбиток сертифіката (SHA-1 / SHA-256 для Play Console):

```bash
npm run keystore:info
```

Скрипт читає `android/keystore.properties` і викликає `keytool` з правильним шляхом.

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

- Файл: `privacy.html` (корінь репозиторію)
- Хостинг: GitHub Pages автоматично після push у `main` (`.github/workflows/pages.yml`, лише privacy)
- Альтернатива: `npm run privacy:package` → `privacy-host/` (Netlify Drop, Cloudflare Pages тощо)
- URL для Play Console: `https://averixor.github.io/LostNumber/privacy.html`

## 4. Заповнення сторінки застосунку

Скопіюйте тексти з `docs/store-listing/` або **`store/PLAY_CONSOLE_LISTING.md`**:

| Локаль | Короткий опис              | Повний опис               |
| ------ | -------------------------- | ------------------------- |
| UK     | `short-description-uk.txt` | `full-description-uk.txt` |
| EN     | `short-description-en.txt` | `full-description-en.txt` |
| RU     | `short-description-ru.txt` | `full-description-ru.txt` |

**Категорія:** Games → Puzzle  
**Теги (приклад):** puzzle, numbers, logic, casual, offline  
**Контакт:** `ryabinin.sergei.alekseevich@gmail.com`  
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

**Policy → App content → Data safety** — відповідати **фактичній** Auth B2 політиці ([`FIREBASE_PRIVACY_DELTA.md`](./FIREBASE_PRIVACY_DELTA.md), `privacy.html`):

| Питання                                       | Відповідь                                                                  |
| --------------------------------------------- | -------------------------------------------------------------------------- |
| Збирає або передає дані користувачів?         | **Так (опційно)** — лише якщо гравець обирає Google Sign-In                |
| Типи даних                                    | Account / name / email (через Google); інакше локальний прогрес лише на девайсі |
| Шифрування при передачі                       | Так (HTTPS / Google / Firebase Auth)                                       |
| Видалення даних                               | Sign out у Settings + очищення даних застосунку в Android                  |
| Privacy policy URL                            | `https://averixor.github.io/LostNumber/privacy.html`                       |

Локальний прогрес у `user://` **не синхронізується** в Cloud Save (ще не shipped).  
Власний фон з системного picker → `user://custom_backgrounds/` локально.  
Android presets: **`permissions/internet=true`** (Auth-capable).

Додатково в **App content**: Ads — No; In-app purchases — No.

Потрібен успішний деплой privacy URL — див. [PRIVACY_HOSTING.md](./PRIVACY_HOSTING.md).

Детальна таблиця відповідей для листингу: **`store/PLAY_CONSOLE_LISTING.md`**.

## 8. Чекліст перед Production

- [ ] Перевірка особи завершена
- [ ] `npm run release:check` зелений (AAB з Firebase resources)
- [ ] AAB зібраний з release flags (`cheatsEnabled=false`)
- [ ] Скріншоти з реального APK на телефоні
- [ ] Privacy policy опублікована (URL відкривається)
- [ ] IARC (Content rating) заповнено чесно
- [ ] Target audience — **не** «переважно для дітей»
- [ ] Data safety — optional Google Sign-In (не «дані не збираються»)
- [ ] Email підтримки вказано в Store listing
- [ ] Closed testing пройдено без критичних багів + Auth smoke
- [ ] versionCode > max у Console (зараз у git **6 / 2.1.6**)

## 9. Версіонування

- `versionName` — читабельна мітка у форматі `major.minor.patch` (вільна).
- `versionCode` — ціле число, яке порівнює Play; збільшується на 1 при кожному завантаженні.

Поточні значення:

| Артефакт     | versionName | versionCode | Package                     |
| ------------ | ----------- | ----------- | --------------------------- |
| Godot (ship) | `2.1.6`     | `6`         | `com.Averixor.Lost_Number`  |
| Debug        | `dev`       | `6`         | `com.Averixor.Lost_Number.dev` |

Кожен новий upload потребує **versionCode більший за будь-який раніше завантажений** у **цьому** listing.

ABI: постачаються лише `arm64-v8a` + `x86_64`. Без `armeabi-v7a` 32-бітні пристрої (~8 тис. у каталозі) не підтримуються — свідоме рішення.

## 10. Корисні команди

```bash
npm run godot:android:release   # signed AAB для Play
npm run godot:android:debug     # debug APK
python3 scripts/prepare-play-store-assets.py
```

Див. також: [README.md](./README.md), [ANDROID.md](./ANDROID.md), [ANDROID_QA.md](./ANDROID_QA.md).
