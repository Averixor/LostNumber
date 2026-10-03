# Фази (LostNumber)

> **Примітка (2026-07):** Web/JS стек видалено. Фази 5–6 застосовуються до Godot-реалізації; історичні посилання на `js/`, `css/`, `index.html` — лише контекст міграції.

## Фаза 5 — performance (локально завершувати перед хмарними збереженнями)

- **5.6 FPS** — моніторинг FPS; плаваючі числа на фоні прибрані з продукту. Godot: `bg_effects_enabled` у Settings.
- **5.7 Grid / інтеракція** — синхронізація сітки після shuffle/gravity у `Board.gd` / `BoardLogic.gd`.
- **5.8 Lite (слабкі пристрої)** — `SettingsManager.bg_effects_enabled`, low-performance візуал у Godot.

**Критерій «фаза 5 закрита»:** немає помітних регресій UI; після тривалої гри сітка синхронна з моделлю.

## Мобільний UX (Godot — реалізовано)

- Boot → App shell, ScreenRouter, back-stack навігація
- Збереження: `user://lost_number_save.json` + `.bak` rollback
- Android «Назад»: `App.gd` + ScreenRouter
- Аудіо: `docs/AUDIO.md`, `AudioManager.gd`
- Smoke: `npm run godot:test:smoke`

## Фаза 6 — Firebase (**Auth B2 shipped; Cloud Save blocked**)

> **Auth-only (B2)** у коді: `AuthManager` + `LostNumberFirebase` (`permissions/internet=true`).  
> Docs / gates: [`FIREBASE_STAGE4_GATES.md`](FIREBASE_STAGE4_GATES.md), ADR [`en/FIREBASE_ADR.md`](en/FIREBASE_ADR.md), path [`FIREBASE_STAGE4_SEQUENCE.md`](FIREBASE_STAGE4_SEQUENCE.md).  
> **Cloud Save / Firestore (4B/4C)** — **не** стартувати, доки OWNER не закриє gates (стабільний Closed testing, privacy + explicit Cloud Save approve).  
> CT зараз: **NO-GO** до `android/firebase/{dev,prod}/google-services.json` + нового AAB. Див. [`ROADMAP.md`](ROADMAP.md) § Етап 4.

Коли Cloud Save gates зелені (окремі Godot/Firebase PR):

- Auth: **лише Google** (вже в runtime B2).
- Bridge: Godot Android **Kotlin** plugin (не WebView/Capacitor); SaveManager-first sync.
- Firestore: **`users/{uid}/save/current`**; envelope з `revision` + `payloadChecksum`.
- Конфлікти: revision + checksum + **діалог** (keep local / use remote / cancel) — **без** field-merge.
- Fallback: локальний Godot save (`user://`); гра повністю без акаунта/мережі.
- Custom backgrounds — **лише локально**; Crashlytics/Analytics не вмикати мовчки.
