---
language: en
title: Lost Number — English Documentation Index
version: 2.1.6
last_updated: 2026-07-16
---

# Lost Number — English Documentation

Professional technical documentation for the Lost Number project. **Godot 4** is the sole ship target (`2.1.6` / versionCode `6`, package `com.Averixor.Lost_Number`).

## English docs (this folder)

| Document                                               | Description                                                             |
| ------------------------------------------------------ | ----------------------------------------------------------------------- |
| **[SOURCE_OF_TRUTH.md](./SOURCE_OF_TRUTH.md)**         | **Canonical reference** — decisions, version, doc index                 |
| [FIREBASE_ADR.md](./FIREBASE_ADR.md)                   | Firebase Cloud Save ADR (Kotlin bridge; runtime blocked on gates)       |
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
| [docs/CT_SMOKE_CHECKLIST.md](../CT_SMOKE_CHECKLIST.md)               | Closed testing smoke (OWNER) — GO/NO-GO            |
| [docs/FIREBASE_STAGE4_SEQUENCE.md](../FIREBASE_STAGE4_SEQUENCE.md)   | Stage 4 OWNER walkable path (CT → gates → bridge)  |
| [docs/FIREBASE_STAGE4_GATES.md](../FIREBASE_STAGE4_GATES.md)         | Stage 4 OWNER hard gates (runtime blocked)         |
| [docs/FIREBASE_OWNER_RUNBOOK.md](../FIREBASE_OWNER_RUNBOOK.md)       | Firebase Console / SHA / secrets setup             |
| [docs/FIREBASE_PRIVACY_DELTA.md](../FIREBASE_PRIVACY_DELTA.md)       | Privacy / Data safety changes when cloud lands     |
| [docs/ANDROID.md](../ANDROID.md)                                     | Godot Android build                                |
| [docs/ANDROID_RELEASE_READINESS.md](../ANDROID_RELEASE_READINESS.md) | Android export, signing, pre-upload gate           |
| [docs/ANDROID_QA.md](../ANDROID_QA.md)                               | Pre-release QA on device                           |
| [docs/STAGE1_RELEASE_RECORD.md](../STAGE1_RELEASE_RECORD.md)         | Stage 1 closed testing release record              |
| [docs/STAGE2_PREP.md](../STAGE2_PREP.md)                             | Stage 2 prep (no CT upload)                        |
| [docs/STAGE3_REPO_HARDENING.md](../STAGE3_REPO_HARDENING.md)         | Stage 3 repo hardening baseline                    |
| [docs/STAGE3_CLOSEOUT.md](../STAGE3_CLOSEOUT.md)                     | Stage 3 closeout checklist                         |
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

| Field       | Value                                      |
| ----------- | ------------------------------------------ |
| Package     | `com.Averixor.Lost_Number`                 |
| Debug       | `com.Averixor.Lost_Number.dev`             |
| versionName | `2.1.6` (debug: `dev`)                     |
| versionCode | `6`                                        |
| Next upload | versionCode `>` Console max for this listing |
