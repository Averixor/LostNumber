# Closed testing runbook — Lost Number

Передумови: [`PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md), [`ANDROID_RELEASE_READINESS.md`](ANDROID_RELEASE_READINESS.md), [`STAGE1_RELEASE_RECORD.md`](STAGE1_RELEASE_RECORD.md), [`ROADMAP.md`](ROADMAP.md).

## Ship target (поки Console не скаже інакше)

| Поле                      | Значення                                                           |
| ------------------------- | ------------------------------------------------------------------ |
| Package                   | `com.averixor.lostnumber`                                          |
| versionName / versionCode | **2.1.6 / 16** (bump лише якщо Console покаже VC16 already used)   |
| AAB                       | `build/android/lost-number.aab` з SHA `2ef0fcd…` (див. record)     |
| AAB SHA-256               | `398b83f33d79b878e71ca1262d6cfac2e0a981045d77299a5c0824c1dba848c4` |
| Privacy                   | [privacy.html](https://averixor.github.io/LostNumber/privacy.html) |

## 1. Pre-upload gate (репо — виконано 2026-08-04)

```bash
git switch main && git pull --ff-only
git rev-parse HEAD   # очікується 2ef0fcdf2aaf5083cf79c88a41b989720e137b47 (або новіший main після docs merge)
npm ci
npm run godot:verify:aab
sha256sum build/android/lost-number.aab
```

| Крок                    | Статус                                                    |
| ----------------------- | --------------------------------------------------------- |
| `godot:verify:aab`      | ✅ OK                                                     |
| Release record          | ✅ [`STAGE1_RELEASE_RECORD.md`](STAGE1_RELEASE_RECORD.md) |
| Device QA GO/NO-GO      | ✅ [`ANDROID_QA.md`](ANDROID_QA.md)                       |
| Listing + ≥2 real shots | ✅ `01` + `02`                                            |
| Forms cheat sheet       | ✅ [`STAGE1_CONSOLE_FORMS.md`](STAGE1_CONSOLE_FORMS.md)   |

Канонічний gate — `godot:verify:aab` (не лише `godot:test:all`).

## 2. Device QA

Повний чеклист: [`ANDROID_QA.md`](ANDROID_QA.md). Без P0/P1 для upload.

## 3. Console перед upload (OWNER)

- [ ] Recon таблиця OWNER (Upload SHA, VC16, identity, track) — [`PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md)
- [ ] Listing + ≥2 phone screenshots (`01`, `02`)
- [ ] Icon / feature graphic (`store/play-high-res-icon-512.png`, `store/feature-graphic-1024x500.png`)
- [ ] Privacy URL 200
- [ ] Data safety / IARC / audience — [`STAGE1_CONSOLE_FORMS.md`](STAGE1_CONSOLE_FORMS.md)
- [ ] Upload key SHA = recon

## 4. Closed testing release (OWNER — лише Console)

1. Test and release → Closed testing → Create new release → upload `build/android/lost-number.aab`.
2. Release notes: `2.1.6 (16)` — Closed testing candidate з `main@2ef0fcd` (post-adaptive; старі `a6db8b29` / `c9e315af…` superseded).
3. Testers → Save → Review → Start rollout.
4. Надіслати opt-in URL тестеру.

**З репо upload неможливий** (немає Play Console API credentials у цьому середовищі).

## 5. Після upload (OWNER + tester)

- [ ] Немає помилки підпису
- [ ] Тестер: Play opt-in → install → merge + save + Back
- [ ] Production не стартувати до identity approval

## OWNER handoff — що вже готове

1. AAB підписаний upload keystore, verify OK, SHA-256 у release record.
2. Device QA на Xiaomi 23117RA68G → **GO** (див. ANDROID_QA).
3. Listing тексти: [`store/PLAY_CONSOLE_LISTING.md`](../store/PLAY_CONSOLE_LISTING.md).
4. Forms: [`STAGE1_CONSOLE_FORMS.md`](STAGE1_CONSOLE_FORMS.md).
5. Версія **залишена 16** до вашого факту VC16 у Console.

## OWNER blockers

1. Увійти в Play Console і заповнити recon чекбокси (SHA / VC16 / identity / track).
2. Якщо VC16 already used → сказати агенту зробити PR `godot/release-play-v17`, перезібрати AAB, оновити record.
3. Upload AAB у Closed testing + opt-in smoke з Play.
