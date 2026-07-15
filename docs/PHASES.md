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

## Фаза 6 — Firebase (ще не впроваджувати до закриття фази 5)

- Auth: Google.
- Firestore документ **`users/{uid}/save/current`** (або узгоджений шлях).
- Конфлікти: брати версію з **більшим `updatedAt`**.
- Fallback: локальний Godot save (`user://`), коли офлайн або помилка бекенду.
