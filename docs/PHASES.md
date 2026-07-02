# Фази (LostNumber)

## Фаза 5 — performance (локально завершувати перед хмарними збереженнями)

- **5.6 FPS** — моніторинг FPS у dev-інструментах (`performance-monitor.js`); **плаваючі числа на фоні прибрані** з продукту (`createFloatingNumbers` — no-op). Подія `lostnumber:floating-numbers-auto-disable` лишається в dev-коді для сумісності, але не керує UI гравця.
- **5.7 Grid / інтеракція** — `syncGridDOMFromModel` / `preferSyncOrFullRender` у `grid-render`; rAF для pointer move (`ui-events`); квадратні клітини (`aspect-ratio` у `grid.css`); після перемішування та гравітації — `grid-physics.js`.
- **5.8 Lite (MIUI / слабкі пристрої)** — `PlatformDetector.shouldPreferLiteVisual()`, клас `html.low-performance` + `css/low-performance.css`, налаштування `liteVisualMode`: auto/on/off у `settings.js`.

**Критерій «фаза 5 закрита»:** немає помітних регресій UI; після тривалої гри сітка синхронна з моделлю; lite-режим працює згідно збережених налаштувань.

## Мобільний UX (реалізовано)

- Єдиний шаблон кнопок меню: іконка 32px + текст (`css/ui.css`, `index.html`); головне меню — по центру екрана.
- Два фони: чергування раз на день при вході в головне меню (`background.js`).
- Збереження партії: `lostNumberSave`, кнопка «Продовжити», автозбереження при виході з гри.
- Android «Назад»: `js/app/navigation/back-navigation.js`, confirm «Нова гра» — `menu.js`.
- Аудіо: `docs/AUDIO.md`.
- Smoke DOM↔модель: `scripts/test-grid-dom-sync.mjs`.

## Фаза 6 — Firebase (ще не впроваджувати до закриття фази 5)

- Auth: Google.
- Firestore документ **`users/{uid}/save/current`** (або узгоджений шлях).
- Конфлікти: брати версію з **більшим `updatedAt`**.
- Fallback: **`localStorage`**, коли офлайн або помилка бекенду.
