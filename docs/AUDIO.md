# Lost Number — звук і музика

Єдиний менеджер: **`js/system/platform/audio.js`** (`AudioManager`).

Аудіофайли лежать у **`public/audio/`** і потрапляють у збірку так:

```
public/audio/  →  npm run build:pages  →  _site/audio/  →  Capacitor Android
```

У коді шляхи завжди **`audio/...`** (відносно кореня web-артефакту).

## Музика (`public/audio/music/`)

| Ключ у налаштуваннях | Файл                  |
| -------------------- | --------------------- |
| `ambient`            | `ambient.mp3`         |
| `crystalFlow`        | `Crystal Flow.mp3`    |
| `digitalHorizon`     | `Digital Horizon.mp3` |
| `neonDrift`          | `Neon Drift.mp3`      |
| `stellarLogic`       | `Stellar Logic.mp3`   |

Поведінка:

- циклічне відтворення (`loop`);
- старт лише після **першої дії користувача** (`unlock()` через будь-який SFX або кнопку);
- **один** активний трек — без накладання;
- повторний `playMusic()` не перезапускає вже граючий трек;
- гучність за замовчуванням ~30% (`musicVolume: 0.3`).

Налаштування в екрані «Налаштування» і в `localStorage` (`lostNumberSettings`):

- `musicEnabled` — увімкнена / вимкнена;
- `musicVolume` — 0.25 / 0.5 / 0.75 / 1.0;
- `musicTrack` — один із ключів таблиці вище.

Застосування налаштувань: **`AudioManager.applySettings()`** (`settings.js`, constructor `LostNumberGame`). Окремо **`setSoundEnabled()`** — перемикач звуку у футері гри (`ui-events.js`).

## Звукові ефекти (`public/audio/sfx/`)

| Файл                 | Метод                 | Коли грає                                                                |
| -------------------- | --------------------- | ------------------------------------------------------------------------ |
| `connect.mp3`        | `playChainLink()`     | Старт цепочки (перша клітинка) і кожне наступне додавання цифри          |
| `chain-complete.mp3` | `playChainComplete()` | Валідне відпускання — ланцюг зливається (**один** звук)                  |
| `error.mp3`          | `playError()`         | Невалідне відпускання; заморожена клітинка; немає бонусу; помилка бонусу |
| `button.mp3`         | `playTap()`           | Кнопки меню, налаштувань, футера, оверлеїв                               |
| `bonus.mp3`          | `playBonus()`         | Успішне використання бонусу (shuffle / destroy / explosion)              |
| `xp.mp3`             | `playXp()`            | Нарахування XP за хід; нагорода XP за щоденне завдання                   |
| `quest-complete.mp3` | `playQuestComplete()` | Щоденне завдання виконано                                                |
| `victory.mp3`        | `playVictory()`       | Рівень пройдено                                                          |

У папці `public/audio/sfx/` лише файли з цієї таблиці (8 штук).

## Розділення «звук» і «музика»

| Налаштування            | Що вимикає    |
| ----------------------- | ------------- |
| `soundEnabled` (Звук)   | Усі SFX       |
| `musicEnabled` (Музика) | Фонова музика |

Кнопка звуку у футері гри перемикає лише **`soundEnabled`** (SFX).

## Де в коді

| Подія                     | Файл                                                |
| ------------------------- | --------------------------------------------------- |
| Цепочка, тап по полю      | `js/app/ui/ui-events.js`                            |
| Злиття, XP, перемога      | `js/app/flow/game-flow.js`                          |
| Бонуси                    | `js/game/mechanics/bonuses.js`                      |
| Щоденні завдання          | `js/game/meta/daily.js`                             |
| Збереження налаштувань    | `js/ui/overlays/settings.js`                        |
| Зелений/червоний HUD суми | `js/ui/overlays/overlays.js` (без звуку валідності) |

## Capacitor

Плагіни: `@capacitor/status-bar`, `@capacitor/app` (кнопка «Назад» — див. `docs/ANDROID.md`).

При згортанні застосунку на ігровому екрані стан зберігається (`capacitor-bridge.js` → `saveGameState`).
