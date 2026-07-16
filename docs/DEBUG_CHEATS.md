# Lost Number — Debug / cheats

**Play Store release — без читів.** Для Android використовуй Godot debug preset.

| Збірка  | Package ID                    | Чити                        |
| ------- | ----------------------------- | --------------------------- |
| Release | `com.averixor.lostnumber`     | вимкнено                    |
| Debug   | `com.averixor.lostnumber.dev` | dev tools у Godot debug APK |

## Godot debug APK

```bash
npm run godot:android:debug
adb install -r build/android/lost-number-debug.apk
```

## Перевірка release

```bash
npm run release:check
```

Див. також: [ANDROID.md](./ANDROID.md), [ANDROID_RELEASE_READINESS.md](./ANDROID_RELEASE_READINESS.md)
