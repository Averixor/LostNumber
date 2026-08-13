# Lost Number — Android device QA

Сценарний чеклист для arm64 перед Closed testing / upload.  
Автоматичні gate: `npm run release:check`, канонічний `npm run godot:verify:aab`.

Пов’язано: [ANDROID_RELEASE_READINESS.md](ANDROID_RELEASE_READINESS.md), [AUTH_SIGNIN_QA.md](AUTH_SIGNIN_QA.md), [CLOSED_TESTING_RUNBOOK.md](CLOSED_TESTING_RUNBOOK.md), [STAGE1_RELEASE_RECORD.md](STAGE1_RELEASE_RECORD.md).

> **Поточний CT вердикт (2026-08-13):** **NO-GO** для Closed Testing.  
> Identity: `com.Averixor.Lost_Number(.dev)` / **VC 6** / targetSdk **36**.  
> Без `google-services.json` Auth дає `firebase_not_configured` (очікувано).  
> Історичний gameplay GO нижче **не** означає Auth-ready / CT GO.

## Збірка

```bash
npm run godot:android:debug    # APK → com.Averixor.Lost_Number.dev
npm run godot:android:release  # AAB (keystore + prod google-services.json)
npm run godot:android:install
```

## Перед установкою

- [ ] `versionCode` **6** у git; max VC у Console — OWNER ([PLAY_CONSOLE_RECON.md](PLAY_CONSOLE_RECON.md))
- [ ] Keystore / passwords не в git
- [ ] Privacy URL: [privacy.html](https://averixor.github.io/LostNumber/privacy.html) HTTP 200
- [ ] Пристрій **arm64-v8a**
- [ ] Auth checklist: [AUTH_SIGNIN_QA.md](AUTH_SIGNIN_QA.md)

## Сценарії (P0 блокує Auth-ready upload)

### Чисте встановлення та перший запуск

- [ ] Clean/reinstall debug APK (`com.Averixor.Lost_Number.dev`)
- [ ] Boot splash → Main Menu без зависання / ANR; **без** блокувального Auth popup

### Навігація / геймплей / save

- [ ] Main Menu, Settings, Wheel, Back
- [ ] Merge + HUD score/XP
- [ ] Force-stop → relaunch → progress restored

### Auth (обовʼязково для CT)

- [ ] Без JSON: Settings → Guest / `firebase_not_configured` (не `sign_in_unavailable`)
- [ ] З JSON: Google Sign-In → display name; Sign out → Guest; локальний save лишається

## Результат (історичний gameplay — 2026-08-04)

| Дата       | SHA / versionCode                           | Пристрій                                 | Тестер      | Примітка                                      |
| ---------- | ------------------------------------------- | ---------------------------------------- | ----------- | --------------------------------------------- |
| 2026-08-04 | `a6db8b29` / **16** (тодішній listing)      | Xiaomi `23117RA68G` / `6pwkydzdayxcfyu4` | agent + adb | Gameplay GO на **старому** package/VC — архів |
| 2026-08-13 | `ee6af9e2…` / **6** / `.dev`                | той самий пристрій                       | agent + adb | Auth negative smoke PASS; CT **NO-GO**        |

**Поточний вердикт:** gameplay debug OK; **Closed Testing = NO-GO** до Firebase JSON + нового AAB + positive Sign-In.
