# Closed testing runbook — Lost Number

Операційний гайд для завантаження **Closed testing** у Google Play.  
Передумови: [`docs/PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md), [`docs/ANDROID_RELEASE_READINESS.md`](ANDROID_RELEASE_READINESS.md).

## Поточний ship target

| Поле        | Значення                                           |
| ----------- | -------------------------------------------------- |
| Package     | `com.averixor.lostnumber`                          |
| versionName | `2.1.7`                                            |
| versionCode | `17`                                               |
| AAB         | `build/android/lost-number.aab`                    |
| Privacy     | https://averixor.github.io/LostNumber/privacy.html |

## 1. Локальний pre-upload gate

На чистій гілці `main` (або release-кандидаті) з наявним `android/keystore.properties`:

```bash
npm ci
npm run godot:verify:aab
```

Очікування: exit 0; AAB пересобрано; немає `assets/store/` / `scripts/tests/` у бандлі.

Опційно:

```bash
sha256sum build/android/lost-number.aab > build/android/lost-number.aab.sha256
```

## 2. Device QA

Пройти [`docs/ANDROID_QA.md`](ANDROID_QA.md) на arm64 телефоні (debug APK або internal test з AAB).  
Без P0/P1 — можна upload.

## 3. Play Console — перед upload

- [ ] Listing copy (UK/EN/RU) з `store/PLAY_CONSOLE_LISTING.md` / `docs/store-listing/`
- [ ] High-res icon `store/play-high-res-icon-512.png`
- [ ] Feature graphic `store/feature-graphic-1024x500.png`
- [ ] ≥2 phone screenshots (`store/screenshots/phone/`)
- [ ] Privacy policy URL збережено й відкривається
- [ ] Data safety / IARC / Target audience (див. `docs/PLAY_STORE.md`)
- [ ] Upload key SHA збігається з recon

## 4. Створення Closed testing release

1. Play Console → **Test and release** → **Closed testing** (або створити track).
2. **Create new release** → upload `lost-number.aab`.
3. Release name / notes (приклад):

```text
2.1.7 (17) — Closed testing
- Godot 4.7 Android build
- Gothic UI readability fixes
- Offline puzzle; no ads / no IAP
```

4. Add email list або Google Groups тестерів → **Save** → **Review release** → **Start rollout to Closed testing**.
5. Скопіювати opt-in URL тестерам.

## 5. Після upload

- [ ] Console показує versionCode **17** без помилок підпису
- [ ] Статус release: available / in review (не failed)
- [ ] Тестер встановив і пройшов smoke з `ANDROID_QA.md`
- [ ] Production **не** запускати, доки identity verification не approved

## 6. Rollback / наступний build

Кожен новий upload: `versionCode` +1 (`18` / `2.1.8` за правилом `2.1.(code-10)` для code ≥ 15).
