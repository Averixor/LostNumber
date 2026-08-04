# Lost Number — Roadmap v1.1

| Поле               | Значення                                                                                                      |
| ------------------ | ------------------------------------------------------------------------------------------------------------- |
| Версія документа   | **1.1** (2026-08-04)                                                                                          |
| База               | `main` @ `f2d69ddb` (після merge #58; Stage 3 repo base) / AAB source `main` @ `a6db8b29` (Stage 1 candidate) |
| Ship version у git | **2.1.6 / versionCode 16** (не змінювати до факту з Play Console)                                             |

## Стратегія

Godot 4.7 offline-головоломка → **Google Play Closed testing** → UX/візуальний polish → лише після стабільного мобільного релізу **Phase 6 Firebase** ([`docs/PHASES.md`](PHASES.md): Phase 5 → Phase 6).

```mermaid
flowchart LR
  A[Stage0_main_base] --> B[Console_recon]
  B --> C[Version_gate]
  C --> D[verify_aab]
  D --> E[Device_QA]
  E --> F[Closed_testing]
  F --> G[Screenshots_and_polish]
  G --> H[Repo_hygiene]
  H --> I[Phase6_later]
```

## Етап 0 — Фіксація релізної бази `main`

PR #48 (`godot/fix-gothic-chrome-readability`) **уже merged** (2026-08-02): head `21a627b`, merge `1feda649`. Пункт «довести feature-гілку» **неактуальний**.

Задачі етапу 0:

1. Підтвердити CI для **цільового commit SHA** (не стверджувати «зелений» без run).
2. Тримати [`docs/AUDIT_PLAY_360.md`](AUDIT_PLAY_360.md) у `main` (PR #52) + Prettier/format gate.
3. Оновити таблицю аудитів і факт CI у [`docs/en/SOURCE_OF_TRUTH.md`](en/SOURCE_OF_TRUTH.md).
4. Збирати новий AAB **лише з конкретного SHA `main`**.

Формулювання для аудиту:

> Аудит початково виконано на `21a627b`; зміни PR #48 інтегровані в `main` через `1feda649`; перед релізом стан повторно звірено з актуальним HEAD.

Станом на `f2d69ddb`: workflow **CI** має `release-check` + `Godot tests (4.7.1)`; на цьому SHA обидва check-runs = success.

## Етап 1 — Play Console recon → version → AAB → device QA → Closed testing

### Жорсткий version gate (не міняти код до факту Console)

```text
Console max versionCode
        ↓
VC16 не використовувався → залишити 16 / 2.1.6
VC16 уже існує          → bump 17 / 2.1.7 (окремий PR godot/release-play-v17)
        ↓
збірка з main @ SHA
        ↓
npm run godot:verify:aab   ← канонічний фінальний gate
        ↓
device QA (окремий deliverable)
        ↓
Closed testing upload
```

`npm run godot:test:all` допустимий як ранній gate; **фінальний** — завжди `godot:verify:aab` (перебудовує AAB).

Власник Console: [`docs/PLAY_CONSOLE_RECON.md`](PLAY_CONSOLE_RECON.md).  
Операції upload: [`docs/CLOSED_TESTING_RUNBOOK.md`](CLOSED_TESTING_RUNBOOK.md) (версія в runbook = поточна в git, до bump).

### Device QA

Повний сценарний чеклист — [`docs/ANDROID_QA.md`](ANDROID_QA.md) (окремий PR). DoD етапу 1 включає сценарії: clean install, Boot→Menu→Game, діагоналі/довгі ланцюги, save/kill/restore, backup recovery, Android Back, pause/audio, uk/ru/en, low-effects, immersive/notch, Wheel/Daily/Achievements, upgrade-over-install, legacy migration plugin.

### Скріншоти (зсув ближче до Closed testing)

- **До** запрошення зовнішніх тестерів: ≥2 справжні Godot/device скріншоти.
- **Після** першого feedback: повний комплект із 4.
- Promo drafts — лише тимчасовий внутрішній матеріал.

## Етап 2 — Polish після Closed testing

Prep (без CT): [`STAGE2_PREP.md`](STAGE2_PREP.md) — hybrid wheel, Import stub B, порядок PR.  
VISUAL_TARGET, Settings Import stub UX, розмір AAB, фінальні 4 скріншоти. Firebase — ні.

## Етап 3 — Repo hygiene (окремий PR)

`fix/repo-hygiene`: видалити tracked `.bak` / `.broken` / soft-gothic / зайві `.import`. Не змішувати з version bump.

## Етап 4 — Phase 6 Firebase

Лише після стабільного Closed testing і Phase 5 без device-регресій.

## Розділення PR (обов’язково)

| Гілка / PR                 | Зміст                                                                                                   |
| -------------------------- | ------------------------------------------------------------------------------------------------------- |
| `docs/roadmap-v1.1-sot-ci` | ROADMAP v1.1, SoT CI + audit index, audit narrative, Prettier AUDIT, recon/runbook **без** version bump |
| `docs/android-device-qa`   | Повний device checklist                                                                                 |
| `fix/repo-hygiene`         | Junk cleanup only                                                                                       |
| `godot/release-play-v17`   | **Лише якщо** Console підтвердить, що VC16 використано                                                  |

## Що свідомо не стверджуємо без перевірки

- Історія upload / max versionCode у Play Console
- Збіг fingerprints upload key (локальні SHA є в recon — звірка власником)
- Identity verification status
- «CI зелений» без конкретного successful run для target SHA
- Device QA sign-off

## Не змінюємо найближчим часом

Offline-first, Godot-only ship, exclude store/tests з AAB, secrets поза git, Production до identity approval.
