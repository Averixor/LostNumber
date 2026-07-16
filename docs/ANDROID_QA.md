# Lost Number — Android QA (Godot)

Короткий чеклист перед установкою release/debug збірки Godot на телефон. Автоматичні gate: `npm run release:check`, `npm run godot:verify:aab` (перед Play upload).

## Збірка

```bash
npm run godot:android:debug    # debug APK
npm run godot:android:release  # release AAB (потрібен android/keystore.properties)
```

## Перед установкою

- [ ] `npm run release:check` проходить
- [ ] Версія в `godot/export_presets.cfg` збільшена (`versionCode` > попереднього upload)
- [ ] Keystore / passwords не в git
- [ ] Privacy URL відкривається

Детальніше: `docs/ANDROID_RELEASE_READINESS.md`, `docs/PLAY_STORE.md`.
