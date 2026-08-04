# Lost Number — Android QA (Godot)

Чеклист перед Closed testing / установкою debug або release збірки на телефон.  
Автоматичні gate: `npm run release:check`, `npm run godot:verify:aab` (перед Play upload).

Пов’язано: `docs/ANDROID_RELEASE_READINESS.md`, `docs/PLAY_STORE.md`, `docs/CLOSED_TESTING_RUNBOOK.md`.

## Збірка

```bash
npm run godot:android:debug    # debug APK → build/android/lost-number-debug.apk
npm run godot:android:release  # release AAB (потрібен android/keystore.properties)
npm run godot:android:install  # або adb install -r …
```

## Перед установкою

- [ ] `npm run release:check` проходить
- [ ] `versionCode` у `godot/export_presets.cfg` **більший** за будь-який раніше завантажений у Console
- [ ] Keystore / passwords не в git (`git status` чистий від `export_presets.cfg` з паролями)
- [ ] Privacy URL відкривається: https://averixor.github.io/LostNumber/privacy.html
- [ ] Пристрій **arm64-v8a** (32-bit-only не підтримується)

## Сценарії на пристрої (arm64)

Позначити P0 / P1 / OK. **P0 блокує upload.**

### Навігація та оболонка

- [ ] Boot splash → Main Menu без зависання
- [ ] Відкрити Game, Settings, Wheel, Achievements, Daily Quests, Stats, About
- [ ] Системна кнопка **Назад** повертає по back-stack (не миттєвий exit з меню без підтвердження, якщо так задумано)
- [ ] Перехід Menu ↔ Game зберігає очікуваний стан

### Геймплей

- [ ] Нова гра стартує; сітка видима; тап/свайп ланцюга працює
- [ ] Merge / score / XP оновлюються на HUD
- [ ] Пауза / resume (якщо є) не ламає інпут
- [ ] Після довгої партії (5+ хв) сітка синхронна з моделлю (немає «привидів» плиток)

### Збереження

- [ ] Вийти в меню / вбити процес → перезапуск відновлює прогрес
- [ ] Немає втрати сейву після force-stop
- [ ] Legacy Import у Settings: показує очікуваний stub/повідомлення (не краш)

### Аудіо та lifecycle

- [ ] Музика/SFX за налаштуваннями
- [ ] Згорнути додаток (Home) → повернутись: аудіо не дублюється / не зависає
- [ ] Вимкнути музику в Settings → тихо одразу

### Локалізація та візуал

- [ ] uk / ru / en перемикаються без битих ключів на Main Menu + Settings
- [ ] Immersive / notch: критичні кнопки (Back, Play) не під системними жестами
- [ ] Тема dawn/dusk: фон і chrome читабельні (не flat neon на лаві)

### Стабільність

- [ ] Немає ANR / crash за 10 хв smoke
- [ ] Обертання заблоковане (portrait only) — UI не ламається

## Результат

| Дата | Збірка (versionCode) | Пристрій | Тестер | P0/P1 | Вердикт        |
| ---- | -------------------- | -------- | ------ | ----- | -------------- |
|      |                      |          |        |       | ☐ GO / ☐ NO-GO |

**GO** = нуль P0 і нуль відкритих P1, критичних для Closed testing.
