---
language: en
title: Lost Number — Source of Truth
version: 2.1.7
last_updated: 2026-10-03
---

Single canonical reference for PO-approved decisions. When docs disagree with this file, **update the other doc** (or escalate to PO if the code is wrong).

## Version snapshot

| Field               | Value                                                           |
| ------------------- | --------------------------------------------------------------- |
| Package             | `com.Averixor.Lost_Number`                                      |
| Debug package       | `com.Averixor.Lost_Number.dev`                                  |
| versionName         | `2.1.7`                                                         |
| versionCode         | `7`                                                             |
| Next Play upload    | versionCode `>` Console max; bump **versionName + versionCode** |
| Engine              | Godot **4.7**                                                   |
| npm package version | `2.1.7`                                                         |

**Versioning rule:**

- Debug: fixed `versionName=dev`; `versionCode` follows the release integer in presets.
- Play compares **versionCode** only — it must be `>` max already uploaded for `com.Averixor.Lost_Number`.
- **Current CT candidate:** `2.1.7` / `7` (account deletion + Play compliance). Supersedes `2.1.6` / `6` (`93f72b58…` — **do not upload**).
- On every new Play upload series: bump **versionName** and **versionCode** together; sync `package.json` and `godot/project.godot` `config/version` with release `versionName`.

Verified in: `godot/export_presets.cfg`, `godot/project.godot`, `package.json`.

## Decisions table

| Topic                 | Canonical choice                                                                                                                                                                                                                | Verify in code                                                     |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| **Ship target**       | Godot 4.7 Android AAB → Google Play (`npm run godot:android:release`)                                                                                                                                                           | `scripts/godot-android-export.sh`, `export_presets.cfg`            |
| **Entry flow**        | `Boot.tscn` → `App.tscn` → screens via `ScreenRouter` autoload                                                                                                                                                                  | `godot/project.godot`, `ScreenRouter.gd`                           |
| **Autoloads**         | SaveManager, SettingsManager, AudioManager, I18nManager, ThemeManager, LeaderboardService, AuthManager, ScreenRouter, LegacySaveMigration                                                                                       | `project.godot` `[autoload]`                                       |
| **Network**           | `permissions/internet=true` for **optional** Google Sign-In (Firebase Auth). Offline play without account remains the default. No Cloud Save yet.                                                                               | `godot/export_presets.cfg`, `AuthManager.gd`, `LostNumberFirebase` |
| **Cloud / Firebase**  | **Auth-only (B2)** + in-app account deletion; local `android/firebase/{dev,prod}/google-services.json` (gitignored). CT candidate **2.1.7 / 7**. Cloud Save / Firestore still deferred.                                         | `docs/FIREBASE_PRIVACY_DELTA.md`, `docs/AUTH_SIGNIN_QA.md`, STAGE1 |
| **Account deletion**  | Settings → **Видалити акаунт** (Firebase `delete` + Google re-auth). Local saves kept. Web: `https://averixor.github.io/LostNumber/delete-account.html` (manual ≤7 days). No “delete data without account”.                     | `AuthManager.gd`, Firebase plugin, `delete-account.html`, privacy  |
| **Save**              | `user://` envelope v1 + SHA-256 + `.bak`; legacy import via `LegacySaveMigration`                                                                                                                                               | `SaveManager.gd`, `LegacySaveMigration.gd`                         |
| **i18n**              | uk / ru / en — **341 keys** each                                                                                                                                                                                                | `godot/assets/i18n/*.json`, `run_i18n_tests.gd`                    |
| **Levels**            | First **40** configs algorithmically generated at init (`_generate_manual_levels(40)`); from index 40+ separate procedural branch                                                                                               | `LevelManager.gd`                                                  |
| **Visual authority**  | **PO mockups + [VISUAL_TARGET.md](./VISUAL_TARGET.md)** = acceptance; gothic fantasy integration over flat neon                                                                                                                 | `VISUAL_TARGET.md`, `docs/archive/VISUAL_PORT_MAP.md`              |
| **Legacy import UI**  | Settings **Import** stub demoted below gallery CTA (`settings_import_legacy_stub`): no save mutation; startup migration + `LegacySaveMigration` remain                                                                          | `Settings.gd`, `LegacySaveMigration.gd`, `Boot.gd`                 |
| **Custom background** | Settings **Обрати фон з галереї** + BackgroundPreview picker → `ImagePickerHelper` → `user://custom_backgrounds/` via `SettingsManager.add_custom_background`                                                                   | `Settings.gd`, `ImagePickerHelper.gd`, `BackgroundPreview.gd`      |
| **CI**                | `release:check` **і** `godot:test:all` (Godot **4.7.1**) на push/PR `main`; CodeQL через GitHub Advanced Security (шаблон manual Java: `docs/ci/codeql.workflow.yml`). Перед релізом підтвердити successful run для commit SHA. | `.github/workflows/ci.yml`, `docs/ci/codeql.workflow.yml`          |

## Build commands (by role)

| Role                | Command                         | Output                                                                |
| ------------------- | ------------------------------- | --------------------------------------------------------------------- |
| **Primary release** | `npm run godot:android:release` | `build/android/lost-number.aab`                                       |
| Full local gate     | `npm run release:ideal`         | format + lint + repo checks + Godot rules/save (skips if no `godot4`) |
| Pre-upload gate     | `npm run godot:verify:aab`      | `godot:test:all` + release:check + AAB manifest                       |
| CI gate             | `npm run release:check`         | format + lint + tagline + Godot export config + smoke                 |

## Doc index — which doc is authoritative for what

| Question                                                  | Authoritative doc                                                                                                                                                  |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **This file** — decisions, version, doc roles             | `docs/en/SOURCE_OF_TRUTH.md`                                                                                                                                       |
| Game rules (chain, merge, XP)                             | `docs/GAME_RULES.md` + `docs/en/GAME.md`                                                                                                                           |
| Endless progression (40 + procedural)                     | `docs/GAME_RULES.md`, `LevelManager.gd`                                                                                                                            |
| Architecture, autoloads, repo layout                      | `docs/en/ARCHITECTURE.md`                                                                                                                                          |
| Accepted decisions (save, i18n, screens, compliance)      | `docs/en/DECISIONS.md`                                                                                                                                             |
| Release / Play Console checklists                         | `docs/en/RELEASE.md`, `docs/CLOSED_TESTING_RUNBOOK.md`, `docs/STAGE1_RELEASE_RECORD.md` (HANDOFF-IDEAL superseded)                                                 |
| JS → Godot parity checklist (historical)                  | `docs/archive/MIGRATION_FROM_JS.md`                                                                                                                                |
| **Visual north star** (mockups, gaps, per-screen targets) | `docs/en/VISUAL_TARGET.md`                                                                                                                                         |
| Web → Godot visual port status (historical)               | `docs/archive/VISUAL_PORT_MAP.md`                                                                                                                                  |
| Android export, signing, presets                          | `docs/ANDROID_RELEASE_READINESS.md`                                                                                                                                |
| Legacy save import                                        | `docs/LEGACY_SAVE_MIGRATION.md`                                                                                                                                    |
| Folder map (uk)                                           | `docs/PROJECT_STRUCTURE.md`                                                                                                                                        |
| Doc navigator (uk)                                        | `docs/README.md`                                                                                                                                                   |
| English doc index                                         | `docs/en/README.md`                                                                                                                                                |
| Roadmap / Play sequence                                   | `docs/ROADMAP.md`                                                                                                                                                  |
| Firebase Stage 4 sequence / gates / ADR / OWNER / privacy | `docs/FIREBASE_STAGE4_SEQUENCE.md`, `docs/FIREBASE_STAGE4_GATES.md`, `docs/en/FIREBASE_ADR.md`, `docs/FIREBASE_OWNER_RUNBOOK.md`, `docs/FIREBASE_PRIVACY_DELTA.md` |
| Play Console recon                                        | `docs/PLAY_CONSOLE_RECON.md`                                                                                                                                       |
| Closed testing runbook                                    | `docs/CLOSED_TESTING_RUNBOOK.md`                                                                                                                                   |
| 360° Play audit                                           | `docs/AUDIT_PLAY_360.md`                                                                                                                                           |
| Godot quick start                                         | `godot/README.md`, root `README.md`                                                                                                                                |
| Android export, signing, presets                          | `docs/ANDROID_RELEASE_READINESS.md`, `docs/ANDROID.md`                                                                                                             |

## Known risks and audits

Dated technical audits capture static-analysis findings, test gaps, and release blockers. They are **not** copied into the Master Project Source.

| Audit                                                  | Ref       | Notes                                                                                                                      |
| ------------------------------------------------------ | --------- | -------------------------------------------------------------------------------------------------------------------------- |
| [AUDIT_MAIN_2026-07-10.md](./AUDIT_MAIN_2026-07-10.md) | `dd6300a` | LevelManager high-index risk, backup-only save, migration plugin path, Settings import stub, CI/`release:ideal` scope      |
| [AUDIT_PLAY_360.md](../AUDIT_PLAY_360.md)              | `5e39937` | 360° Play readiness; gothic PR #48 already on main; CI jobs configured — confirm run per release SHA; VC16 Console unknown |
| [ROADMAP.md](../ROADMAP.md)                            | v1.2      | Play-first; Auth B2 + account deletion; CT candidate **2.1.7 / 7**; Cloud Save later                                       |

Update this table when a new dated audit lands on `main`.

## Intentional non-goals (deferred by design)

- Freeze tiles, pressure transfer
- Monetization (ads, IAP, premium, tournaments)
- Cloud save runtime (Phase 6) — deferred after Auth-only B2; Firestore not in this build
- Play Games / Firebase leaderboard HTTP (stub only; 4C after Cloud Save)
- Twilight theme in settings UI (code exists; art not shipped)

## When to update this file

Update after any PO-approved change to: ship target, version fields, save schema, level count, i18n key count, CI scope, or autoload list.
