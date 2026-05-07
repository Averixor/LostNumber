# Фази (LostNumber)

## Фаза 5 — performance (локально завершувати перед хмарними збереженнями)

- **5.6 FPS / плаваючі числа** — моніторинг FPS, подія `lostnumber:floating-numbers-auto-disable`, збереження `floatingNumbersDisabledBy`, ручний оверрайд у налаштуваннях.
- **5.7 Grid / інтеракція** — менше повних `render` під час drag (`ui-events`), sync DOM з моделі (`syncGridDOMFromModel` / `preferSyncOrFullRender` у `grid-render`), фізика викликає `preferSyncOrFullRender` після падіння/перемішування.
- **5.8 Lite (MIUI / слабкі пристрої)** — `PlatformDetector.shouldPreferLiteVisual()`, ранній bootstrap у `index.html`, клас `html.low-performance` + `css/low-performance.css`, налаштування `liteVisualMode`: auto/on/off через `settings.js`.

**Критерій «фаза 5 закрита»:** немає помітних регресій UI; після тривалої гри сітка синхронна з моделлю; lite і авто‑відключення фону працюють згідно збережених налаштувань.

## Фаза 6 — Firebase (ще не впроваджувати до закриття фази 5)

- Auth: Google.
- Firestore документ **`users/{uid}/save/current`** (або узгоджений шлях).
- Конфлікти: брати версію з **більшим `updatedAt`**.
- Fallback: **`localStorage`**, коли офлайн або помилка бекенду.
