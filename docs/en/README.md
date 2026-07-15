---
language: en
title: Lost Number — English Documentation Index
version: 2.1.6
last_updated: 2026-07-16
---

# Lost Number — English Documentation

Professional technical documentation for the Lost Number project. **Godot 4** is the sole ship target (`2.1.6` / versionCode `16`).

## English docs (this folder)

| Document                                               | Description                                                             |
| ------------------------------------------------------ | ----------------------------------------------------------------------- |
| **[SOURCE_OF_TRUTH.md](./SOURCE_OF_TRUTH.md)**         | **Canonical reference** — decisions, version, doc index                 |
| [AUDIT_MAIN_2026-07-10.md](./AUDIT_MAIN_2026-07-10.md) | Dated main-branch technical audit (ref `dd6300a`)                       |
| [GAME.md](./GAME.md)                                   | Game description, goal, mechanics, controls, progression                |
| [MIGRATION_GODOT.md](./MIGRATION_GODOT.md)             | Godot 4 migration: completed work, remaining tasks                      |
| [DECISIONS.md](./DECISIONS.md)                         | Accepted decisions: save format, i18n, screens, visuals, compliance     |
| [RELEASE.md](./RELEASE.md)                             | Release plans and checklists: Android, Google Play, testing, versioning |
| [ARCHITECTURE.md](./ARCHITECTURE.md)                   | Architecture audit, technical decisions, approved plans, repo layout    |
| [VISUAL_TARGET.md](./VISUAL_TARGET.md)                 | Visual north star (PO mockups, acceptance criteria)                     |

## Ukrainian / bilingual docs (`docs/`)

| Document                                                             | Description                                        |
| -------------------------------------------------------------------- | -------------------------------------------------- |
| [docs/README.md](../README.md)                                       | Ukrainian documentation navigator                  |
| [docs/PROJECT_STRUCTURE.md](../PROJECT_STRUCTURE.md)                 | Folder structure and code flows                    |
| [docs/HANDOFF-IDEAL.md](../HANDOFF-IDEAL.md)                         | Production handoff (ideal build)                   |
| [docs/PHASES.md](../PHASES.md)                                       | Development phases (performance, Firebase roadmap) |
| [docs/ANDROID.md](../ANDROID.md)                                     | Godot Android build                                |
| [docs/ANDROID_RELEASE_READINESS.md](../ANDROID_RELEASE_READINESS.md) | Android export, signing, pre-upload gate           |
| [docs/ANDROID_QA.md](../ANDROID_QA.md)                               | Pre-release QA on device                           |
| [docs/PLAY_STORE.md](../PLAY_STORE.md)                               | Google Play Console setup                          |
| [docs/PLAY_STORE_GODOT.md](../PLAY_STORE_GODOT.md)                   | Play listing for Godot build                       |
| [docs/PRIVACY_HOSTING.md](../PRIVACY_HOSTING.md)                     | Privacy URL hosting options                        |
| [docs/AUDIO.md](../AUDIO.md)                                         | Music and SFX                                      |
| [docs/DEBUG_CHEATS.md](../DEBUG_CHEATS.md)                           | Debug build cheats                                 |
| [docs/GAME_RULES.md](../GAME_RULES.md)                               | Core game rules                                    |
| [docs/LEGACY_SAVE_MIGRATION.md](../LEGACY_SAVE_MIGRATION.md)         | Legacy save import                                 |
| [README.md](../../README.md)                                         | Project quick start                                |

## Archive (`docs/archive/`)

Historical JS→Godot migration maps — **not** current source of truth:

| Document                                                | Description                     |
| ------------------------------------------------------- | ------------------------------- |
| [MIGRATION_FROM_JS.md](../archive/MIGRATION_FROM_JS.md) | JS → Godot architecture map     |
| [VISUAL_PORT_MAP.md](../archive/VISUAL_PORT_MAP.md)     | Web → Godot visual port tracker |
| [MERGE_NOTES.md](../archive/MERGE_NOTES.md)             | Zip consolidation provenance    |

## Quick commands

```bash
# Godot (primary ship target)
npm run godot:import
npm run godot:test:all
npm run godot:android:release   # → build/android/lost-number.aab

# Full local verification (rules + save; skips Godot if godot4 missing)
npm run release:ideal

# Full Godot test suite
npm run godot:test:all
```

## Version

| Field       | Value                               |
| ----------- | ----------------------------------- |
| Package     | `com.averixor.lostnumber`           |
| versionName | `2.1.6`                             |
| versionCode | `16`                                |
| Next upload | versionCode `17` (required by Play) |
