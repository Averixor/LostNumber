# Closed testing runbook — Lost Number

Передумови: [`PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md), [`ANDROID_RELEASE_READINESS.md`](ANDROID_RELEASE_READINESS.md), [`STAGE1_RELEASE_RECORD.md`](STAGE1_RELEASE_RECORD.md), [`AUTH_SIGNIN_QA.md`](AUTH_SIGNIN_QA.md), [`CT_SMOKE_CHECKLIST.md`](CT_SMOKE_CHECKLIST.md).

## Ship target (канон = `export_presets.cfg`)

| Поле                      | Значення                                                                   |
| ------------------------- | -------------------------------------------------------------------------- |
| Package                   | `com.Averixor.Lost_Number`                                                 |
| Debug                     | `com.Averixor.Lost_Number.dev`                                             |
| versionName / versionCode | **2.1.6 / 6** (далі: VC ≥ max у Console + 1)                               |
| targetSdk                 | **36**                                                                     |
| Auth                      | Google Sign-In only (`LostNumberFirebase`); **немає** Cloud Save           |
| CT status                 | **NO-GO / BLOCKED** до `google-services.json` + нового AAB + Sign-In smoke |
| AAB                       | `build/android/lost-number.aab` — **лише після rebuild з prod JSON**       |
| Privacy                   | [privacy.html](https://averixor.github.io/LostNumber/privacy.html)         |

### Заборонено upload

| SHA / artifact          | Причина                                   |
| ----------------------- | ----------------------------------------- |
| `1463fd4c…`             | Auth bridge без Firebase resources        |
| `5c0530b0…`             | Legacy listing / інший candidate          |
| `398b83f3…`             | Старий Stage1 (`com.averixor.lostnumber`) |
| `lost-number-debug.apk` | Не CT smoke (лише device QA)              |

## 1. Pre-upload gate (репо)

```bash
git switch main && git pull --ff-only
npm ci
# OWNER: android/firebase/prod/google-services.json + dev twin
npm run godot:android:release
npm run release:check          # має PASS лише з Firebase resources у AAB
sha256sum build/android/lost-number.aab
```

| Крок                     | Статус                                             |
| ------------------------ | -------------------------------------------------- |
| Identity VC6 / package   | ✅ presets + SoT                                   |
| Auth B2 bridge + privacy | ✅ source                                          |
| Firebase JSON у AAB      | ☐ OWNER                                            |
| Positive Sign-In smoke   | ☐ [`AUTH_SIGNIN_QA.md`](AUTH_SIGNIN_QA.md)         |
| `release:check` PASS     | ☐ після rebuild                                    |
| CT smoke з Play          | ☐ [`CT_SMOKE_CHECKLIST.md`](CT_SMOKE_CHECKLIST.md) |

## 2. Device QA (до CT)

- Gameplay / save: [`ANDROID_QA.md`](ANDROID_QA.md) (історичний GO на debug — **не** Auth-ready CT).
- Auth: [`AUTH_SIGNIN_QA.md`](AUTH_SIGNIN_QA.md).

## 3. Console перед upload (OWNER)

- [ ] Recon: Upload SHA `43:93:42:63…`, max VC, identity — [`PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md)
- [ ] Listing + ≥2 phone screenshots
- [ ] Privacy URL 200
- [ ] Data safety = optional Google Sign-In ([`STAGE1_CONSOLE_FORMS.md`](STAGE1_CONSOLE_FORMS.md), [`FIREBASE_PRIVACY_DELTA.md`](FIREBASE_PRIVACY_DELTA.md))
- [ ] Новий AAB SHA записаний у [`STAGE1_RELEASE_RECORD.md`](STAGE1_RELEASE_RECORD.md)

## 4. Closed testing release (OWNER — лише Console)

1. Upload **новий** `lost-number.aab` (не `1463fd4c…` / не legacy).
2. Release notes: `2.1.6 (6)` — Auth-capable listing `com.Averixor.Lost_Number`.
3. Testers → Save → Review → Start rollout → opt-in URL.

## 5. Після upload

Канонічний smoke: [`CT_SMOKE_CHECKLIST.md`](CT_SMOKE_CHECKLIST.md) (включно Sign-In).

## OWNER blockers (зараз)

1. Покласти `android/firebase/{dev,prod}/google-services.json`.
2. Перезібрати debug + release → новий SHA.
3. Positive Google Sign-In smoke.
4. Лише тоді Closed Testing upload.
5. Cloud Save / 4B — окремо після CT GO ([`FIREBASE_STAGE4_SEQUENCE.md`](FIREBASE_STAGE4_SEQUENCE.md)).
