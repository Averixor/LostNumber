# Closed testing runbook — Lost Number

Передумови: [`PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md), [`ANDROID_RELEASE_READINESS.md`](ANDROID_RELEASE_READINESS.md), [`ROADMAP.md`](ROADMAP.md).

## Ship target (поки Console не скаже інакше)

| Поле                      | Значення                                                                      |
| ------------------------- | ----------------------------------------------------------------------------- |
| Package                   | `com.averixor.lostnumber`                                                     |
| versionName / versionCode | як у `main` зараз (**2.1.6 / 16**, або **2.1.7 / 17** після окремого bump PR) |
| AAB                       | `build/android/lost-number.aab` з **конкретного SHA `main`**                  |
| Privacy                   | [privacy.html](https://averixor.github.io/LostNumber/privacy.html)            |

## 1. Pre-upload gate

```bash
git switch main && git pull --ff-only
# зафіксувати SHA: git rev-parse HEAD
npm ci
npm run godot:verify:aab
```

Канонічний gate — `godot:verify:aab` (не лише `godot:test:all`).

## 2. Device QA

Повний чеклист: [`ANDROID_QA.md`](ANDROID_QA.md). Без P0/P1.

## 3. Console перед upload

- [ ] Listing + ≥2 справжні phone screenshots (promo drafts недостатньо для зовнішніх тестерів)
- [ ] Icon / feature graphic
- [ ] Privacy URL 200
- [ ] Data safety / IARC / audience
- [ ] Upload key SHA = recon

## 4. Closed testing release

1. Test and release → Closed testing → Create new release → upload AAB.
2. Release notes з фактичною versionName/versionCode.
3. Testers → Save → Review → Start rollout.
4. Надіслати opt-in URL.

## 5. Після upload

- [ ] Немає помилки підпису
- [ ] Тестер пройшов smoke
- [ ] Production не стартувати до identity approval
