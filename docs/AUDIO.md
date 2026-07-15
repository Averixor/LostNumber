# Lost Number — звук і музика

Єдиний менеджер: **`godot/scripts/managers/AudioManager.gd`**.

Аудіофайли: **`godot/assets/audio/`** (music + sfx, mp3 через git LFS).

## Музика (`godot/assets/audio/music/`)

| Ключ у налаштуваннях | Файл                  |
| -------------------- | --------------------- |
| `ambient`            | `ambient.mp3`         |
| `crystalFlow`        | `Crystal Flow.mp3`    |
| `digitalHorizon`     | `Digital Horizon.mp3` |
| `neonDrift`          | `Neon Drift.mp3`      |
| `stellarLogic`       | `Stellar Logic.mp3`   |

Поведінка:

- циклічне відтворення;
- старт після першої дії користувача;
- один активний трек;
- гучність за замовчуванням ~30%.

Налаштування в `SettingsManager` / екрані «Налаштування»: `music_enabled`, `music_volume`, `music_track`, `sound_enabled`.

## Звукові ефекти (`godot/assets/audio/sfx/`)

connect, chain-complete, button, bonus, xp, error, quest-complete, victory.

Виклики SFX — з `Game.gd`, `GameHud.gd`, `BonusManager.gd`, UI-кнопок через `AudioManager.play_sfx()`.

## Godot export

Аудіо включається в AAB разом з `godot/assets/audio/`. Перевірка на пристрої: увімкнути звук у Settings, пройти один хід на полі.
