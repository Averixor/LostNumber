---
language: en
title: Lost Number — English Documentation Index
version: 2.1.6
last_updated: 2026-07-10
---

# Lost Number — English Documentation

Professional technical documentation for the Lost Number project. **Godot 4** is the primary Android ship target (`2.1.6` / versionCode `16`). The Capacitor/Web build (`js/`, `android/`) remains a visual reference and legacy path.

## English docs (this folder)

| Document                                       | Description                                                             |
| ---------------------------------------------- | ----------------------------------------------------------------------- |
| **[SOURCE_OF_TRUTH.md](./SOURCE_OF_TRUTH.md)** | **Canonical reference** — decisions, version, doc index                 |
| [GAME.md](./GAME.md)                           | Game description, goal, mechanics, controls, progression                |
| [MIGRATION_GODOT.md](./MIGRATION_GODOT.md)     | Godot 4 migration: completed work, remaining tasks, removable legacy    |
| [DECISIONS.md](./DECISIONS.md)                 | Accepted decisions: save format, i18n, screens, visuals, compliance     |
| [RELEASE.md](./RELEASE.md)                     | Release plans and checklists: Android, Google Play, testing, versioning |
| [ARCHITECTURE.md](./ARCHITECTURE.md)           | Architecture audit, technical decisions, approved plans, repo layout    |

## Ukrainian / bilingual docs (repository root)

| Document                                           | Description                                        |
| -------------------------------------------------- | -------------------------------------------------- |
| [docs/README.md](../README.md)                     | Ukrainian documentation navigator                  |
| [docs/PHASES.md](../PHASES.md)                     | Development phases (performance, Firebase roadmap) |
| [docs/ANDROID.md](../ANDROID.md)                   | Capacitor Android build (legacy)                   |
| [docs/ANDROID_QA.md](../ANDROID_QA.md)             | Pre-release QA on device                           |
| [docs/PLAY_STORE.md](../PLAY_STORE.md)             | Google Play Console setup                          |
| [docs/GITHUB_PAGES.md](../GITHUB_PAGES.md)         | GitHub Pages and privacy URL                       |
| [docs/AUDIO.md](../AUDIO.md)                       | Music and SFX                                      |
| [docs/DEBUG_CHEATS.md](../DEBUG_CHEATS.md)         | Debug build cheats                                 |
| [HANDOFF-IDEAL.md](../../HANDOFF-IDEAL.md)         | Production handoff (ideal build)                   |
| [PROJECT_STRUCTURE.md](../../PROJECT_STRUCTURE.md) | Folder structure and code flows                    |
| [README.md](../../README.md)                       | Project quick start                                |

## Godot-specific docs (`godot/docs/`)

| Document                                                                                 | Description                                      |
| ---------------------------------------------------------------------------------------- | ------------------------------------------------ |
| [godot/README.md](../../godot/README.md)                                                 | Godot entry flow, tests, Android commands        |
| [godot/docs/GAME_RULES.md](../../godot/docs/GAME_RULES.md)                               | Core rules (1:1 with `rules.js`)                 |
| [godot/docs/MIGRATION_FROM_JS.md](../../godot/docs/MIGRATION_FROM_JS.md)                 | JS → Godot architecture map and parity checklist |
| [godot/docs/VISUAL_PORT_MAP.md](../../godot/docs/VISUAL_PORT_MAP.md)                     | Web → Godot visual port tracker                  |
| [godot/docs/ANDROID_RELEASE_READINESS.md](../../godot/docs/ANDROID_RELEASE_READINESS.md) | Android export preset, signing, pre-upload gate  |
| [godot/docs/LEGACY_SAVE_MIGRATION.md](../../godot/docs/LEGACY_SAVE_MIGRATION.md)         | Capacitor → Godot save import                    |
| [godot/docs/PLAY_STORE_GODOT.md](../../godot/docs/PLAY_STORE_GODOT.md)                   | Play listing for Godot build                     |
| [godot/docs/PLAY_CONSOLE_LISTING.md](../../godot/docs/PLAY_CONSOLE_LISTING.md)           | Store listing copy                               |

## Quick commands

```bash
# Godot (primary ship target)
npm run godot:import
npm run godot:test:all
npm run godot:android:release   # → build/godot/android/lost-number.aab

# Full local verification
npm run release:ideal

# Legacy Capacitor/Web
npm run android:bundle
```

## Version

| Field       | Value                               |
| ----------- | ----------------------------------- |
| Package     | `com.averixor.lostnumber`           |
| versionName | `2.1.6`                             |
| versionCode | `16`                                |
| Next upload | versionCode `17` (required by Play) |
