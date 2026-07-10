# Port report

## Структура після чистки

```text
LostNumber-Godot-clean/
├─ project.godot
├─ scenes/
├─ scripts/
│  ├─ core/
│  ├─ game/
│  ├─ managers/
│  ├─ tests/
│  └─ ui/
├─ assets/
│  ├─ icons/
│  ├─ store/
│  └─ audio/
└─ docs/
```

## Важливі правки

- Виправлено `SaveManager.load_game(state)`: тепер він може завантажувати в існуючий `GameState`, а не тільки створювати новий.
- Додано `load_from_save_dict()` як основний метод відновлення save.
- Поле більше не повинно скидати ланцюг через пропуск pointer-позицій при просадці FPS.
- Touch/mouse drag обробляються на рівні `BoardView`, з допуском на gap між клітинками.
- UI-підписи переведені на українську.
- Додано логічні модулі `NumberFormatter`, `SeededRandom`, `PlayerProgress`.

## Що не переносив навмисно

- HTML/CSS-анімації — їх треба робити нативними Godot tween/AnimationPlayer.
- Web audio/cache/lifecycle — в Godot це має бути `AudioStreamPlayer`.
- Capacitor/storage/localStorage — замінено на `user://` файли.
- Web debug overlays — краще зробити окрему Godot debug-панель.
- Старі npm release checks — не потрібні для Godot-проєкту.

## Ризики

- Я не міг запустити Godot CLI в цьому середовищі, тому потрібен перший запуск у твоєму редакторі.
- Сцени лишилися MVP-рівня; візуал треба окремо доробити.
- `docs/js-reference/` залишено тільки як донор логіки, не як runtime-код.
