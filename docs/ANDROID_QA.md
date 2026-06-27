# Lost Number — Android release candidate QA

Короткий чеклист перед установкою release APK на телефон. Автоматичні gate: `npm run release:check`, `npm run verify:android`.

## Збірка release APK

```bash
npm run release:check
npm run android:sync          # build:pages + cap sync android
cd android && ./gradlew assembleRelease
```

APK: `android/app/build/outputs/apk/release/app-release.apk`

Підпис: локальний `android/keystore.properties` + `android/keystore/*.jks` (не в git).

## Debug APK з читами (особисте тестування)

```bash
npm run android:debug:cheats
adb install -r android/app/build/outputs/apk/debug/app-debug.apk
```

Package: `com.averixor.lostnumber.dev` — окремий застосунок, не конфліктує з release.

Детально: [DEBUG_CHEATS.md](./DEBUG_CHEATS.md)

## Manual QA — телефон

Позначайте `[x]` після перевірки. Орієнтовний час: 20–30 хв.

### Перший запуск

- [ ] Додаток відкривається без білого екрану
- [ ] Звук/музика (якщо увімкнено в налаштуваннях) відтворюються
- [ ] Portrait lock — екран не обертається в landscape

### Головне меню

| Дія                    | Очікування                                      |
| ---------------------- | ----------------------------------------------- |
| **Грати**              | Нова гра або перехід у гру без збереження       |
| **Продовжити**         | Видно лише якщо є save; відновлює сесію         |
| **Нова гра** (confirm) | Підтвердження → скидання save → нова гра        |
| **Увійти**             | Stub: синхронізація пізніше, без обіцянок login |
| **Вийти**              | Закриває додаток (`App.exitApp`)                |
| **Налаштування**       | Екран відкривається, Back → меню                |
| **Статистика**         | Екран відкрито, дані без падіння                |
| **Про гру**            | Екран / overlay відкривається                   |
| **Преміум** (dock)     | Stub: переваги + «покупки ще немає»             |
| **Турніри** (dock)     | Stub: щотижневі / рекорди / нагороди            |
| **Досягнення** (dock)  | Список досягнень                                |
| **Завдання** (dock)    | Щоденні завдання, neon icons                    |
| **Бонуси** (dock)      | Stub або екран бонусів без crash                |

- [ ] Top bar (Увійти / Вийти) не перекриває CTA «Грати»
- [ ] Bottom dock не перекриває головну кнопку на малому екрані
- [ ] Усі підписи українською (за замовчуванням UA)
- [ ] Немає emoji в кнопках меню / stub

### Back (системна кнопка «Назад»)

- [ ] Feature stub (Преміум, Турніри, Увійти, Бонуси) — Back закриває modal
- [ ] Налаштування / Статистика / Завдання — Back → головне меню
- [ ] Ігрове поле — Back → збереження → головне меню
- [ ] Головне меню — Back → вихід з додатку
- [ ] Під час анімації merge — Back не ламає grid (save відкладено)

### Gameplay

- [ ] Merge двох однакових плиток працює
- [ ] Chain ≥5 — досягнення `chain5` (один раз)
- [ ] Chain ≥10 — досягнення `chain10` (один раз)
- [ ] Destroy bonus — сітка осідає через post-merge pipeline
- [ ] Explosion bonus — те саме, без «дір» у grid
- [ ] FreezeSystem — заморожені клітини не рухаються від pressure
- [ ] Згорнути додаток (Home) → відкрити → **Продовжити** відновлює рівень

### Lite mode (низька продуктивність)

Увімкнути в налаштуваннях або через low-end device:

- [ ] Меню читабельне, dock на місці
- [ ] Neon icons видимі (CSS fallback)
- [ ] Колесо / анімації спрощені або вимкнені — без crash
- [ ] Фон відображається

### Фони (rotation)

- [ ] Три фони: `background.png`, `background-alt.png`, `background-alt2.png`
- [ ] Після зміни календарного дня (або dev: змінити `localStorage.lostNumberBackground`) — інший фон
- [ ] Ключ `lostNumberBackground` у localStorage: `{ index: 0|1|2, lastDay: "YYYY-MM-DD" }`

## Dev helper notes

| Задача                | Підказка                                                                        |
| --------------------- | ------------------------------------------------------------------------------- |
| Logcat                | `adb logcat \| grep -i lostnumber`                                              |
| Очистити save         | Налаштування → скинути прогрес, або `localStorage.removeItem('lostNumberSave')` |
| Перевірити stub       | Головне меню → dock / Увійти                                                    |
| Пересобрати web у APK | `npm run android:sync` перед `./gradlew assembleRelease`                        |
| Debug WebView         | Лише debug build з `webContentsDebuggingEnabled: true` — **не** у release       |

## Security checklist (автоматично + раз на реліз)

- [x] `android:allowBackup="false"` у `AndroidManifest.xml`
- [x] `webContentsDebuggingEnabled: false` у `capacitor.config.json`
- [x] `allowMixedContent: false`
- [x] Keystore / passwords не в git (`npm run verify:android`)
