# Lost Number — Android device QA

Сценарний чеклист для arm64 перед Closed testing / upload.  
Автоматичні gate: `npm run release:check`, канонічний `npm run godot:verify:aab`.

Пов’язано: [ANDROID_RELEASE_READINESS.md](ANDROID_RELEASE_READINESS.md), [ROADMAP.md](ROADMAP.md), [CLOSED_TESTING_RUNBOOK.md](CLOSED_TESTING_RUNBOOK.md).

## Збірка

```bash
npm run godot:android:debug    # APK
npm run godot:android:release  # AAB (keystore required)
npm run godot:android:install
```

## Перед установкою

- [ ] Target SHA `main` зафіксовано; CI run для цього SHA перевірено (не «припускаємо зелений»)
- [ ] `npm run release:check` локально OK
- [ ] `versionCode` узгоджений з Console (див. [PLAY_CONSOLE_RECON.md](PLAY_CONSOLE_RECON.md))
- [ ] Keystore / passwords не в git
- [ ] Privacy URL: [privacy.html](https://averixor.github.io/LostNumber/privacy.html)
- [ ] Пристрій **arm64-v8a**

## Сценарії (P0 блокує upload)

### Чисте встановлення та перший запуск

- [ ] Clean install (без попередньої версії)
- [ ] Boot splash → Main Menu без зависання / ANR

### Навігація

- [ ] Boot → Main Menu → Game
- [ ] Android Back: у грі, у Settings, у головному меню (очікуваний back-stack / exit confirm)
- [ ] Wheel, Daily Quests, Achievements відкриваються і повертають коректно

### Геймплей

- [ ] Drag по діагоналі надійний
- [ ] Довгі ланцюжки merge без зависання інпуту
- [ ] HUD score/XP оновлюється

### Збереження

- [ ] Save → kill process → restore прогресу
- [ ] Recovery із `.bak` (якщо симульовано пошкодження основного сейву)
- [ ] Upgrade поверх попередньої встановленої версії зберігає прогрес

### Legacy

- [ ] Legacy migration plugin / Import UX: немає крашу (stub повідомлення OK)

### Аудіо та lifecycle

- [ ] Pause / resume додатку
- [ ] Audio focus (згортання / повернення без дублювання треку)

### Локалізація та візуал

- [ ] uk / ru / en без битих ключів на Menu + Settings
- [ ] low-effects режим
- [ ] Immersive / notch / gesture navigation: критичні кнопки досяжні

### Стабільність

- [ ] 10+ хв smoke без crash/ANR

## Результат

| Дата | SHA / versionCode | Пристрій | Тестер | P0/P1 | GO / NO-GO |
| ---- | ----------------- | -------- | ------ | ----- | ---------- |
|      |                   |          |        |       |            |
