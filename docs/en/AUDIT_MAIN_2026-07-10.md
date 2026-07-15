---
language: en
title: Main Branch Audit — 2026-07-10
version: 2.1.6
last_updated: 2026-07-10
ref: dd6300ac6f073fef86c2e1ff73c67846e68f95ee
---

# Main Branch Audit — 2026-07-10

Static audit of `main` at ref `dd6300a`. Performed by reading repository files only — no Godot runtime, tests, APK/AAB export, or CI execution. This is a dated technical snapshot for engineering; **not** for the Master Project Source document.

## Method

- Source: committed files at `dd6300ac6f073fef86c2e1ff73c67846e68f95ee`
- No local code changes during audit
- Conclusions are static analysis unless noted

## 1. Godot project structure

**Application entry:**

```
godot/project.godot
  → godot/scenes/Boot.tscn
  → godot/scripts/ui/Boot.gd
  → godot/scenes/App.tscn
  → godot/scripts/App.gd
  → ScreenRouter (autoload)
  → active screen
```

`project.godot` sets `Boot.tscn` as `main_scene`, portrait viewport 420×920, mobile renderer, global theme, and eight autoloads.

**Layout:**

```
godot/
├── project.godot
├── export_presets.cfg
├── scenes/          Boot, App, MainMenu, Game, Settings, SkinPreview, …
├── scripts/         core/, game/, ui/, managers/, meta/, tests/
├── assets/          i18n/, ui/, audio/
├── themes/
└── docs/
```

Smoke test enumerates 11 screen scenes plus components: BackgroundLayer, NeonButton, MenuDockButton, MenuQuickChip, FeatureStubOverlay, ScreenTransition, Tile, ChainLineLayer, GameHud, AchievementCard, DailyQuestCard.

`App.tscn` holds persistent BackgroundLayer, ScreenRoot, OverlayRoot (ToastLayer, ModalLayer, TransitionLayer), and AudioRoot.

## 2. Autoloads

| Autoload            | Path                                            |
| ------------------- | ----------------------------------------------- |
| SaveManager         | `godot/scripts/managers/SaveManager.gd`         |
| SettingsManager     | `godot/scripts/managers/SettingsManager.gd`     |
| AudioManager        | `godot/scripts/managers/AudioManager.gd`        |
| I18nManager         | `godot/scripts/managers/I18nManager.gd`         |
| ThemeManager        | `godot/scripts/managers/ThemeManager.gd`        |
| LeaderboardService  | `godot/scripts/managers/LeaderboardService.gd`  |
| ScreenRouter        | `godot/scripts/ui/ScreenRouter.gd`              |
| LegacySaveMigration | `godot/scripts/managers/LegacySaveMigration.gd` |

Confirmed in `[autoload]` section of `godot/project.godot`.

## 3. Core gameplay status

**Verdict:** Core logic is largely ported; **release readiness is not proven** by tests or real AAB export.

**Implemented in Godot:**

- Same / double / sum-match chain rules; 8-direction adjacency
- Minimum chain length 2; finish requires power-of-two sum with `sum > first`
- One-step backtrack; merge into anchor cell
- Gravity and weighted spawn; XP; target, level complete, carry
- Drag with low-FPS path interpolation
- 5×8 grid; `BoardLogic` separated from UI
- Bonuses, daily quests, wheel included in smoke test scope

**Remaining gaps:** Visual HUD polish, overlays, system dialogs, high-level progression safety tests, real Android verification.

## 4. Level progression (clarification)

`LevelManager` defines `MANUAL_LEVEL_COUNT := 40` and initial target 64.

**Important:** Levels 1–40 are **not** a hand-authored preset table. There is no static array of 40 configs in the repo. At init:

```gdscript
func _init() -> void:
    _manual_levels = _generate_manual_levels(MANUAL_LEVEL_COUNT)
```

`_generate_manual_levels()` builds targets and number sets algorithmically:

- Target doubles each level (64, 128, 256, …)
- Initial set `[2, 4, 8]`; every three levels the next power of two is added; set capped at seven elements

From **zero-based index 40**, `get_level_config()` uses `_procedural_target()`, `_build_level_numbers()`, and `_generate_new_numbers()`. Config is index-only and therefore deterministic.

**Critical risk (static analysis, not runtime-confirmed):**

```gdscript
var doubled := 64 * int(pow(2, level_index))
return mini(doubled, int(pow(2, 52)))
```

The cap is applied **after** computing a potentially overflowing value. At very high indices, protection may not behave as intended.

**Test gap:** Rules/smoke tests do not cover `LevelManager` at boundaries 39/40/41 or high levels (50, 100, 200, 500+). **Do not claim** high progression is safe until dedicated tests and a cap-before-overflow fix land.

**Save note:** `current_level` restores target and level tables. RNG grid state is not saved — level config is deterministic, not future random spawns after reload.

## 5. Save system and legacy import

**Native paths:**

| Item           | Value                              |
| -------------- | ---------------------------------- |
| Primary        | `user://lost_number_save.json`     |
| Backup         | `user://lost_number_save.bak.json` |
| Envelope       | version 1                          |
| Payload schema | `version: 2`                       |
| Integrity      | SHA-256 of `data_json`             |

Before write, existing primary is copied to backup. Corrupt primary → try backup → promote backup to primary on success. Legacy flat `version: 2` saves still load.

**Recovery risk:** `has_save()` checks **primary only**. If primary is missing but backup is valid, `Game.gd` may start a new game without calling `load_game()`. Startup migration may also treat native save as absent.

**Legacy import (implemented):**

1. Skip if Godot primary exists
2. Check `legacy_capacitor_save.json`, `imported_save.json`
3. Try Android singleton `LostNumberMigration`
4. Map camelCase web fields to Godot schema; write native save; rename source to `.imported`

`Boot.gd` runs migration before transitioning to App.

**Settings import button (stub on main):** `_on_import_legacy()` in `Settings.gd` only sets localized `settings_import_legacy_none` — it does **not** call `LegacySaveMigration.try_manual_import()`. Startup migration and `LegacySaveMigration` autoload remain the working paths.

Save tests cover roundtrip, corrupt primary, both corrupt, flat save, meta-state, Capacitor import — but **not** backup-only without primary.

**Android migration plugin:** Documentation requires `godot/android/plugins/LostNumberMigration.gdap`. That exact path returned 404 on GitHub inspection; both export presets still set `plugins/LostNumberMigration=true`. File-import path is confirmed; committed AAR/singleton presence is **not** confirmed.

## 6. Localization

Three JSON files: `godot/assets/i18n/{uk,ru,en}.json` — **285 keys** each (confirmed by inventory).

- Default locale: **uk** when no settings file
- Locale persisted in `user://lost_number_settings.json`
- `I18nManager`: aliases, fallback uk→ru→en, `%/{placeholder}` formatting
- Language change reloads current screen via `ScreenRouter.reload_current()`

**Test gaps:** `run_i18n_tests.gd` does not verify full key parity across locales, placeholder parity, or key count 285.

## 7. Android APK/AAB and versioning

| Field       | Release                               | Debug                                       |
| ----------- | ------------------------------------- | ------------------------------------------- |
| Format      | AAB                                   | APK                                         |
| Package     | `com.averixor.lostnumber`             | `com.averixor.lostnumber.dev`               |
| versionCode | 16                                    | 16                                          |
| versionName | 2.1.6                                 | 2.1.6-dev                                   |
| minSdk      | 24                                    | 24                                          |
| targetSdk   | 35                                    | 35                                          |
| ABI         | arm64-v8a, x86_64                     | arm64-v8a, x86_64                           |
| Output      | `build/android/lost-number.aab` | `build/android/lost-number-debug.apk` |

Internet permission disabled. Vibration and image access enabled for custom backgrounds.

Release signing from local `android/keystore.properties`; script temporarily writes passwords to export config then restores file.

**Launcher icon mismatch:** `ANDROID_RELEASE_READINESS.md` cites `godot/assets/icons/icon-1024.png`; `export_presets.cfg` uses `res://assets/store/icon-1024.png` while `assets/store/*` is in `exclude_filter`. Requires real AAB export to verify launcher icon.

Next Play upload: versionCode **17**; formula `versionName = 2.1.(versionCode - 10)`. CI/scripts do not enforce monotonic versionCode automatically.

## 8. CI limitations

Workflow: single job `release-check` → `npm ci` + `npm run release:check`.

Godot is **not** installed in CI. `release:check` runs Prettier, ESLint, TypeScript, static/tagline checks, legacy Capacitor Android check, static Godot export config check, JS smoke tests.

**CI does not run:** `godot:import`, `godot:test:*`, headless Boot→App→MainMenu, debug APK, release AAB, device tests.

`verify-godot-release.mjs` skips AAB manifest checks when AAB is absent — green CI does **not** prove AAB exists or is correct.

**`release:ideal` scope:** `scripts/release-ideal.mjs` runs Godot **rules + save only**; silently skips if `godot4` is missing; does **not** run smoke or i18n. Full gate: `scripts/verify-godot-aab.sh` or `npm run godot:verify:aab`.

## 9. VISUAL_PORT_MAP status (corrected on main)

**DONE:** MainMenu, About, Stats, Boot, App/ScreenRouter, base Tile, ThemeTokens, backgrounds, BackgroundLayer, NeonButton, low-effects switch, legacy-save migration map entry, SVG icons, audio, FeatureStubOverlay, ScreenTransition, HUD bonuses.

**PARTIAL (including tracker corrections):**

- **Chain-sum HUD** — `GameHud.update_chain_sum()` shows BottomStrip, sum, panel color, `chain_can_merge` / `chain_sum_hud` messages; wired from `Game.gd`. Visual acceptance pending.
- **Preview bubble** — `Board.gd` creates PreviewBubble with sum, valid/invalid color, pointer positioning. Visual acceptance pending.
- Game/HUD, Settings, SkinPreview, Achievements, DailyQuests, Wheel, board panel, tile palette/states/animations, frozen visual, Boot error handling, LevelOverlay, wheel polish, i18n visual parity.

**TODO:** Victory overlay, reusable confirm dialog, system toast, menu skin token polish, full error screen.

**Visual authority:** Web/Capacitor is a **parity reference** for UI/i18n diffing — not the sole source of truth. Acceptance is determined by PO, approved Godot screenshots, and shipped Godot implementation.

## 10. Documentation vs code gaps (post-dd6300a)

| Item                                       | Status on `dd6300a`                                          |
| ------------------------------------------ | ------------------------------------------------------------ |
| `project.godot` description "Godot 2.0"    | Fixed → Godot 4.5 / 2.1.6                                    |
| `GAME_RULES.md` meta as "Not in MVP"       | Fixed → listed as implemented                                |
| `MIGRATION_FROM_JS.md` legacy import `[ ]` | Fixed → DONE                                                 |
| `SOURCE_OF_TRUTH.md` added                 | Yes                                                          |
| "40 preset table" wording                  | **Still wrong** in several docs — fixed in this audit branch |
| "Levels 50–500+ safe" claims               | **Unproven** — no LevelManager tests                         |
| `VISUAL_PORT_MAP` web as sole truth        | **Conflict** — needs parity-reference wording                |
| Chain-sum HUD / preview bubble TODO        | **Stale** — both PARTIAL on main                             |
| `HANDOFF-IDEAL` `release:ideal` scope      | **Overstated** — rules+save only                             |
| Settings Import button                     | **Stub** — docs implied working manual import                |
| `.gdap` / AAR at documented path           | **404** on GitHub                                            |
| Launcher icon path docs vs preset          | **Mismatch**                                                 |

## 11. Priorities

### P0 — before Android release

1. **LevelManager tests** at 39/40/41, 50, 100, 200, 500+; apply target cap **before** overflow.
2. **Migration plugin** — restore/verify `LostNumberMigration.gdap` + AAR or disable in preset and docs; real Capacitor upgrade test.
3. **Backup-only recovery** — `has_save()` / startup path; requires PO decision + dedicated save test.
4. **Real `godot:android:release`** — verify package, icon, versionCode, ABIs, plugin singleton, no stray `assets/store/` in AAB.

### P1 — CI and quality

1. CI job with pinned Godot + headless import + `godot:test:all` (fail if Godot missing).
2. versionName/versionCode consistency check.
3. Stronger i18n tests: key set parity, placeholders, count 285.

### P2 — UI and documentation

1. Update `VISUAL_PORT_MAP` tracker (this branch).
2. Complete victory overlay, confirm, toast, error screen.
3. Align README, HANDOFF, GAME_RULES, Android docs with Godot-first reality.

## 12. Recommended PR split

| Branch                           | Scope                                              |
| -------------------------------- | -------------------------------------------------- |
| `docs/audit-main-2026-07-10`     | Dated audit + doc fixes only (this branch)         |
| `fix/endless-progression-safety` | `LevelManager.gd` + boundary/high-level tests      |
| `fix/save-backup-recovery`       | Backup-only behavior + save test (PO approval)     |
| `fix/android-release-assets`     | Plugin, .gdap/AAR, launcher icon, AAB verification |
| `ci/godot-headless-gate`         | Godot import + `godot:test:all` in CI              |

One focused change per PR — do not mix documentation, gameplay, saves, and Android packaging.

## Verification status (audit session)

| Check                             | Run? |
| --------------------------------- | ---- |
| GitHub file read                  | Yes  |
| Godot import                      | No   |
| Godot rules/save/smoke/i18n tests | No   |
| Headless boot                     | No   |
| APK/AAB export                    | No   |
| Branch/PR created during audit    | No   |
| Repository modified during audit  | No   |
