---
language: en
title: Lost Number — Source of Truth
version: 2.1.6
last_updated: 2026-07-10
---

# Lost Number — Source of Truth

Single canonical reference for PO-approved decisions. When docs disagree with this file, **update the other doc** (or escalate to PO if the code is wrong).

## Version snapshot

| Field               | Value                                  |
| ------------------- | -------------------------------------- |
| Package             | `com.averixor.lostnumber`              |
| Debug package       | `com.averixor.lostnumber.dev`          |
| versionName         | `2.1.6`                                |
| versionCode         | `16`                                   |
| Next Play upload    | versionCode `17` (mandatory increment) |
| Engine              | Godot **4.5**                          |
| npm package version | `2.1.6`                                |

**Versioning rule (code ≥ 15):** `versionName = 2.1.(versionCode - 10)` — e.g. code `16` → `2.1.6`. Debug builds append `-dev`.

Verified in: `godot/export_presets.cfg`, `godot/project.godot`, `package.json`, `android/app/build.gradle`.

## Decisions table

| Topic                | Canonical choice                                                                                                             | Verify in code                                          |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| **Ship target**      | Godot 4.5 Android AAB → Google Play (`npm run godot:android:release`)                                                        | `scripts/godot-android-export.sh`, `export_presets.cfg` |
| **Web / Capacitor**  | Visual reference + legacy; **not** primary Play path                                                                         | `js/`, `android/`, `index.html`                         |
| **Entry flow**       | `Boot.tscn` → `App.tscn` → screens via `ScreenRouter` autoload                                                               | `project.godot`, `ScreenRouter.gd`                      |
| **Autoloads**        | SaveManager, SettingsManager, AudioManager, I18nManager, ThemeManager, LeaderboardService, ScreenRouter, LegacySaveMigration | `project.godot` `[autoload]`                            |
| **Save**             | `user://` envelope v1 + SHA-256 + `.bak`; legacy import via `LegacySaveMigration`                                            | `SaveManager.gd`, `LegacySaveMigration.gd`              |
| **i18n**             | uk / ru / en — **285 keys** each                                                                                             | `godot/assets/i18n/*.json`, `run_i18n_tests.gd`         |
| **Levels**           | **40** preset levels + procedural endless after (`MANUAL_LEVEL_COUNT := 40`)                                                 | `LevelManager.gd`                                       |
| **Visual authority** | Dark Neon Fantasy (`ThemeTokens`, `LnUi`); web = parity reference                                                            | `VISUAL_PORT_MAP.md`                                    |
| **CI**               | `release:check` only on push/PR; `godot:test:all` **local only**                                                             | `.github/workflows/ci.yml`                              |
| **Network**          | None — fully offline                                                                                                         | —                                                       |
| **Cloud / Firebase** | Phase 6 — not started                                                                                                        | `docs/PHASES.md`                                        |

## Build commands (by role)

| Role                | Command                         | Output                                                     |
| ------------------- | ------------------------------- | ---------------------------------------------------------- |
| **Primary release** | `npm run godot:android:release` | `build/godot/android/lost-number.aab`                      |
| Full local gate     | `npm run release:ideal`         | format + lint + Godot tests                                |
| CI gate             | `npm run release:check`         | web smoke + static checks                                  |
| Legacy Capacitor    | `npm run android:bundle`        | `android/app/build/outputs/bundle/release/app-release.aab` |

## Doc index — which doc is authoritative for what

| Question                                             | Authoritative doc                                               |
| ---------------------------------------------------- | --------------------------------------------------------------- |
| **This file** — decisions, version, doc roles        | `docs/en/SOURCE_OF_TRUTH.md`                                    |
| Game rules (chain, merge, XP)                        | `godot/docs/GAME_RULES.md` + `docs/en/GAME.md`                  |
| Endless progression (40 + procedural)                | `godot/docs/GAME_RULES.md`, `LevelManager.gd`                   |
| Architecture, autoloads, repo layout                 | `docs/en/ARCHITECTURE.md`                                       |
| Accepted decisions (save, i18n, screens, compliance) | `docs/en/DECISIONS.md`                                          |
| Release / Play Console checklists                    | `docs/en/RELEASE.md`, `HANDOFF-IDEAL.md`                        |
| JS → Godot parity checklist                          | `godot/docs/MIGRATION_FROM_JS.md`, `docs/en/MIGRATION_GODOT.md` |
| Web → Godot visual port status                       | `godot/docs/VISUAL_PORT_MAP.md`                                 |
| Android export, signing, presets                     | `godot/docs/ANDROID_RELEASE_READINESS.md`                       |
| Legacy save import                                   | `godot/docs/LEGACY_SAVE_MIGRATION.md`                           |
| Folder map (uk)                                      | `PROJECT_STRUCTURE.md`                                          |
| Doc navigator (uk)                                   | `docs/README.md`                                                |
| English doc index                                    | `docs/en/README.md`                                             |
| Production handoff                                   | `HANDOFF-IDEAL.md`                                              |
| Godot quick start                                    | `godot/README.md`                                               |
| Web quick start (secondary)                          | root `README.md`                                                |
| Performance / Firebase phases                        | `docs/PHASES.md`                                                |
| Capacitor Android (legacy)                           | `docs/ANDROID.md`, `docs/PLAY_STORE.md`                         |

## Intentional non-goals (deferred by design)

- Freeze tiles, pressure transfer
- Monetization (ads, IAP, premium, tournaments)
- Cloud save (Phase 6 Firebase)
- Play Games / Firebase leaderboard HTTP (stub only)
- Twilight theme in settings UI (code exists; art not shipped)

## When to update this file

Update after any PO-approved change to: ship target, version fields, save schema, level count, i18n key count, CI scope, or autoload list.
