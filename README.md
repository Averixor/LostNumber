# Lost Number — Godot 4 (Android)

Єдина playable-реалізація — **Godot 4.7** у `godot/`. Ship target: Google Play (`npm run godot:android:release` → `build/android/lost-number.aab`).

## Requirements

- Godot **4.7+** (4.7 tested; `config/features` у `project.godot`)
- Portrait 420×920 (`godot/project.godot`)
- Node.js ≥ 20.19 for npm scripts

## Quick start

```bash
npm run godot:import          # first-time import
godot4 --path godot           # editor
npm run godot:test:all        # headless tests (requires godot4)
npm run release:check         # CI gate
```

## Android

```bash
npm run godot:android:debug     # build/android/lost-number-debug.apk
npm run godot:android:release   # build/android/lost-number.aab
```

Version: `2.1.6` / versionCode `16` (`godot/export_presets.cfg`).

## Privacy policy (Play Store)

Static page **`privacy.html`** at repo root — not part of the game. Host separately: `npm run privacy:package` → see [docs/PRIVACY_HOSTING.md](docs/PRIVACY_HOSTING.md).

## Documentation

Повний навігатор: **[docs/README.md](docs/README.md)**

| Topic               | Doc                                                                    |
| ------------------- | ---------------------------------------------------------------------- |
| Folder structure    | [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md)                 |
| Canonical decisions | [docs/en/SOURCE_OF_TRUTH.md](docs/en/SOURCE_OF_TRUTH.md)               |
| Visual target       | [docs/en/VISUAL_TARGET.md](docs/en/VISUAL_TARGET.md)                   |
| Android release     | [docs/ANDROID_RELEASE_READINESS.md](docs/ANDROID_RELEASE_READINESS.md) |
| Play Store          | [docs/PLAY_STORE.md](docs/PLAY_STORE.md)                               |

## Structure

```
godot/                 # Game: scenes, GDScript, assets, Android export
android/keystore/      # Release signing (gitignored)
build/android/         # APK/AAB output (gitignored)
store/                 # Play Console listing + graphics
scripts/               # npm tooling, Godot export helpers
docs/                  # Project documentation
privacy.html           # Privacy Policy (UK + EN)
```
