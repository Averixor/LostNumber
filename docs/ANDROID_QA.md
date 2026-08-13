# Lost Number — Android device QA

Сценарний чеклист для arm64 перед Closed testing / upload.  
Автоматичні gate: `npm run release:check`, канонічний `npm run godot:verify:aab`.

Пов’язано: [ANDROID_RELEASE_READINESS.md](ANDROID_RELEASE_READINESS.md), [ROADMAP.md](ROADMAP.md), [CLOSED_TESTING_RUNBOOK.md](CLOSED_TESTING_RUNBOOK.md), [STAGE1_RELEASE_RECORD.md](STAGE1_RELEASE_RECORD.md).

## Збірка

```bash
npm run godot:android:debug    # APK
npm run godot:android:release  # AAB (keystore required)
npm run godot:android:install
```

## Перед установкою

- [x] Target SHA `main` зафіксовано; CI run для цього SHA перевірено (`a6db8b29`, green)
- [x] `npm run release:check` локально OK (у складі `godot:verify:aab`)
- [x] `versionCode` **16** у git; узгодження з Console — OWNER (див. [PLAY_CONSOLE_RECON.md](PLAY_CONSOLE_RECON.md))
- [x] Keystore / passwords не в git
- [x] Privacy URL: [privacy.html](https://averixor.github.io/LostNumber/privacy.html) HTTP 200
- [x] Пристрій **arm64-v8a** (Xiaomi 23117RA68G)

## Сценарії (P0 блокує upload)

### Чисте встановлення та перший запуск

- [x] Clean/reinstall debug APK (`com.Averixor.Lost_Number.dev`) — Success
- [x] Boot splash → Main Menu без зависання / ANR (меню uk, v2.1.6, CTA + dock)

### Навігація

- [x] Boot → Main Menu (підтверджено screencap)
- [x] Android Back / exit confirm: діалог «Вийти з гри?» з Назад/Вийти
- [x] Daily Quests («Щоденні завдання») відкривається і має Назад
- [~] Wheel / Settings / Achievements — іконки в dock видимі; adb hit-test нестабільний на MIUI; **рекомендовано OWNER tap-check** перед upload
- [x] Геймплей на девайсі (Рівень 4, Ціль 256/512, Очки 577 XP) + store shot `02-gothic-style.png`

### Геймплей

- [~] Drag по діагоналі — не повністю автоматизовано adb; жива сесія Level 4 на пристрої
- [~] Довгі ланцюжки — OWNER spot-check на Closed testing smoke
- [x] HUD score/XP оновлюється (device Level 4 + store shot)

### Збереження

- [x] Kill process → relaunch (am force-stop + monkey) без FATAL
- [~] Recovery із `.bak` — не симульовано в цій сесії
- [~] Upgrade-over-install release package — QA на `.dev`; release package перевірити після Play install

### Legacy

- [x] Settings Import stub B: кнопка лишається, чесний stub без мутації сейву (код); Boot migration лишається

### Аудіо та lifecycle

- [x] Pause (HOME) / resume (relaunch) без FATAL
- [~] Audio focus детально — OWNER під час smoke

### Локалізація та візуал

- [x] uk на Menu + Daily (видимі рядки)
- [~] ru / en switch — OWNER spot-check у Settings
- [~] low-effects — OWNER
- [x] Immersive / notch: критичні CTA досяжні на 1080×2400

### Стабільність

- [x] Короткий smoke (~10+ хв сесії інструментів) без crash/ANR у logcat

## Результат

| Дата       | SHA / versionCode                           | Пристрій                                 | Тестер      | P0/P1    | GO / NO-GO                                                    |
| ---------- | ------------------------------------------- | ---------------------------------------- | ----------- | -------- | ------------------------------------------------------------- |
| 2026-08-04 | `a6db8b29` / **16** (`2.1.6-dev` on device) | Xiaomi `23117RA68G` / `6pwkydzdayxcfyu4` | agent + adb | немає P0 | **GO** (з OWNER spot-check Wheel/Settings/drag на Play smoke) |

**Вердикт:** **GO** для Closed testing upload кандидата VC16. Повний Play smoke (install з opt-in) — OWNER після upload.
