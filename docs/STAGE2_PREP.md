# Stage 2 prep — після Closed testing (не стартувати Firebase)

**Передумова плану:** Stage 2 UI polish — **після робочого Closed testing**.  
Цей документ фіксує **prep**, який можна зробити зараз без CT upload, і порядок PR після CT.

Статус CT: **OWNER upload pending** (див. [`CLOSED_TESTING_RUNBOOK.md`](CLOSED_TESTING_RUNBOOK.md)). Не стверджувати, що Closed testing завершено.

## Рішення (зафіксовано)

### Wheel — hybrid

Канон: **велика іконка сегмента + короткий i18n label** на сегменті.  
Узгоджує [`docs/en/VISUAL_TARGET.md`](en/VISUAL_TARGET.md) («icons + labels») і читабельність після gothic chrome.  
Не змінювати `WheelManager` / економіку / XP таблиці в polish PR.

### Settings Import — stub B

Кнопка **лишається**. Натиск показує чесний stub (`settings_import_legacy_stub`): без хибного «успіху», **без зміни сейву** з Settings.  
Автоміграція на Boot (`LegacySaveMigration.try_migrate_on_startup`) лишається.  
Повний file-picker UX — окремий PR `godot/settings-import-ux` пізніше.

### Firebase

Docs kickoff ready; **runtime blocked** на OWNER gates ([`FIREBASE_STAGE4_GATES.md`](FIREBASE_STAGE4_GATES.md)). Не стартувати SDK / `INTERNET` до CT + Phase 5 + approve ([`PHASES.md`](PHASES.md), [`ROADMAP.md`](ROADMAP.md)).

## Порядок UI polish PR (після CT + feedback)

1. Класифікація feedback P0→P3; P0/P1 → fix PR + новий Closed build (+1 VC)
2. `docs/store-real-screenshots` — 4 реальні знімки: Menu / Game / **Settings** / **Wheel** (зараз Menu+Game є)
3. `godot/ui-main-menu-polish` — logo + ≤2 CTA + pedestal dock
4. `godot/ui-wheel-polish` — ornate rim/hub + hybrid sectors
5. `godot/ui-hud-polish` — stone frames; не чіпати XP/merge/bonuses logic
6. `godot/ui-settings-polish` — panels, previews, Back
7. `godot/settings-import-ux` — повний import (після stub B)
8. `godot/optimize-aab-assets` — розмір AAB окремо; до/після + visual check
9. Phase 5 device perf sign-off; **без Firebase**

Після кожного великого UI PR: `npm run release:check` + `npm run godot:test:all`.  
Перед новим upload: `npm run godot:verify:aab` + regression з [`ANDROID_QA.md`](ANDROID_QA.md).

## Branch scaffolding (створювати після CT GO)

Не відкривати premature polish PR до робочого CT, якщо немає блокуючого P0.  
Гілки іменувати як у таблиці вище; один concern = один PR.
