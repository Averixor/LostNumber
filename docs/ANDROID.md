# Lost Number — Android (Godot)

**Єдиний шлях Android:** Godot 4 AAB/APK. Capacitor/WebView-збірку видалено.

| Задача                | Команда / документ                                                      |
| --------------------- | ----------------------------------------------------------------------- |
| Release AAB (Play)    | `npm run godot:android:release` → `build/android/lost-number.aab` |
| Debug APK             | `npm run godot:android:debug`                                           |
| Підпис, keystore      | `android/keystore.properties` (gitignored) — див. нижче                 |
| Чеклист перед релізом | [ANDROID_RELEASE_READINESS.md](./ANDROID_RELEASE_READINESS.md)          |
| Play Console          | [PLAY_STORE_GODOT.md](./PLAY_STORE_GODOT.md), [PLAY_STORE.md](./PLAY_STORE.md) |
| QA на телефоні        | `docs/ANDROID_QA.md` (оновлюй під Godot, якщо потрібно)                 |

## Підпис release

Keystore лишається у **`android/keystore/`** + **`android/keystore.properties`** (не комітити). Експорт підписує `scripts/godot-android-export.sh`.

Детально: **[ANDROID_RELEASE_READINESS.md](./ANDROID_RELEASE_READINESS.md)**.
