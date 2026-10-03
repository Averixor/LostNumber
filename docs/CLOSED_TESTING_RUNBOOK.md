# Closed testing runbook — Lost Number

Передумови: [`PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md), [`ANDROID_RELEASE_READINESS.md`](ANDROID_RELEASE_READINESS.md), [`STAGE1_RELEASE_RECORD.md`](STAGE1_RELEASE_RECORD.md), [`AUTH_SIGNIN_QA.md`](AUTH_SIGNIN_QA.md), [`CT_SMOKE_CHECKLIST.md`](CT_SMOKE_CHECKLIST.md).

## Ship target (канон = `export_presets.cfg`)

| Поле                      | Значення                                                                         |
| ------------------------- | -------------------------------------------------------------------------------- |
| Package                   | `com.Averixor.Lost_Number`                                                       |
| Debug                     | `com.Averixor.Lost_Number.dev`                                                   |
| versionName / versionCode | **2.1.7 / 7** (далі: VC ≥ max у Console + 1)                                     |
| targetSdk                 | **36**                                                                           |
| Auth                      | Google Sign-In only (`LostNumberFirebase`); **немає** Cloud Save                 |
| CT status                 | **PRE-UPLOAD READY** (2.1.7 / 7); SHA після rebuild; Play upload OWNER           |
| AAB                       | `build/android/lost-number.aab` — **лише після rebuild з prod JSON**             |
| Privacy                   | [privacy.html](https://averixor.github.io/LostNumber/privacy.html)               |
| Account deletion URL      | [delete-account.html](https://averixor.github.io/LostNumber/delete-account.html) |

### Заборонено upload

| SHA / artifact          | Причина                                   |
| ----------------------- | ----------------------------------------- |
| `1463fd4c…`             | Auth bridge без Firebase resources        |
| `5c0530b0…`             | Legacy listing / інший candidate          |
| `398b83f3…`             | Старий Stage1 (`com.averixor.lostnumber`) |
| `93f72b58…` (VC6)       | Superseded — upload **2.1.7 / 7** only    |
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

| Крок                     | Статус                                                                         |
| ------------------------ | ------------------------------------------------------------------------------ |
| Identity VC7 / package   | ✅ presets + SoT (2.1.7 / 7)                                                   |
| Auth B2 bridge + privacy | ✅ source                                                                      |
| Firebase JSON у AAB      | ✅ 2026-10-03 (`release:check` / `godot:verify:aab`)                           |
| Positive Sign-In smoke   | ☐ Play CT ([`AUTH_SIGNIN_QA.md`](AUTH_SIGNIN_QA.md)); sideload 2026-08-14 PASS |
| `release:check` PASS     | ✅ 2026-10-03                                                                  |
| CT smoke з Play          | ☐ [`CT_SMOKE_CHECKLIST.md`](CT_SMOKE_CHECKLIST.md)                             |

## 2. Device QA (до CT)

- Gameplay / save: [`ANDROID_QA.md`](ANDROID_QA.md) (історичний GO на debug — **не** Auth-ready CT).
- Auth: [`AUTH_SIGNIN_QA.md`](AUTH_SIGNIN_QA.md).

## 3. Console перед upload (OWNER)

- [ ] Recon: Upload SHA `43:93:42:63…`, max VC, identity — [`PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md)
- [ ] Listing + ≥2 phone screenshots
- [ ] Privacy URL 200
- [ ] Data safety + Account deletion URL ([`FIREBASE_PRIVACY_DELTA.md`](FIREBASE_PRIVACY_DELTA.md), `delete-account.html`)
- [ ] Data safety = optional Google Sign-In ([`STAGE1_CONSOLE_FORMS.md`](STAGE1_CONSOLE_FORMS.md))
- [ ] Новий AAB SHA записаний у [`STAGE1_RELEASE_RECORD.md`](STAGE1_RELEASE_RECORD.md)

## 4. Closed testing release (OWNER — лише Console)

1. Upload **новий** `lost-number.aab` (не `1463fd4c…` / не legacy).
2. Release notes: `2.1.7 (7)` — Auth + account deletion; listing `com.Averixor.Lost_Number`.
3. Testers → Save → Review → Start rollout → opt-in URL.

## 5. Після upload

Канонічний smoke: [`CT_SMOKE_CHECKLIST.md`](CT_SMOKE_CHECKLIST.md) (включно Sign-In).

## OWNER blockers (зараз)

1. ~~Покласти `android/firebase/{dev,prod}/google-services.json`.~~ ✅ локально 2026-10-03
2. ~~Перезібрати release → SHA для **2.1.7 / 7**.~~ ✅ `d10d3f2e…` + verify PASS
3. Play Console: Upload key check + Account deletion URL + upload AAB **2.1.7 / 7** + opt-in.
4. Positive Google Sign-In smoke **з Play install**.
5. Cloud Save / 4B — окремо після CT GO ([`FIREBASE_STAGE4_SEQUENCE.md`](FIREBASE_STAGE4_SEQUENCE.md)).
