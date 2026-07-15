---
language: en
title: Lost Number — Accepted Technical Decisions
version: 2.1.6
last_updated: 2026-07-10
---

# Accepted Technical Decisions

Record of decisions that govern implementation. Changes require explicit review — do not silently diverge.

## Ship target

| Decision              | Choice                                                                         |
| --------------------- | ------------------------------------------------------------------------------ |
| Primary Android build | **Godot 4.5** AAB (`build/android/lost-number.aab`)                      |
| Visual authority      | PO mockups + [VISUAL_TARGET.md](./VISUAL_TARGET.md) — not legacy Web/CSS      |
| Legacy Android        | Removed (Capacitor/WebView stack deleted July 2026)                            |
| Runtime network       | **None** — fully offline; GDPR-friendly (no tracking, no PII)                  |
| Cloud budget          | **$0** runtime                                                                 |

## Save format (Godot)

Native saves live at `user://lost_number_save.json` via `SaveManager.gd`.

### Envelope schema

```json
{
  "envelope_version": 1,
  "saved_at": "2026-07-01T11:00:00",
  "checksum": "<sha256 of data_json>",
  "data_json": "{ \"version\": 2, \"current_level\": 0, \"grid\": [...], ... }"
}
```

| Rule              | Detail                                                              |
| ----------------- | ------------------------------------------------------------------- |
| Integrity         | SHA-256 checksum over `data_json` string                            |
| Recovery          | Corrupt primary → load `lost_number_save.bak.json` → promote backup |
| Flat legacy       | Godot flat `version: 2` snake_case saves load without envelope      |
| Web compatibility | **Not** compatible with `localStorage.lostNumberSave` v2 directly   |
| Tests             | `npm run godot:test:save`                                           |

### Legacy import order (startup)

1. Godot native save (`SaveManager`)
2. `user://legacy_capacitor_save.json` or `user://imported_save.json`
3. Android plugin `LostNumberMigration.exportLegacySave()`
4. New game

Manual import: **Settings → Import legacy save** (desktop file picker or Android plugin).

### Field mapping (JS v2 → Godot)

| JS (Capacitor)      | Godot                                            |
| ------------------- | ------------------------------------------------ |
| `currentLevel`      | `current_level`                                  |
| `xpMultiplier`      | `xp_multiplier`                                  |
| `bonusInventory`    | `bonus_inventory`                                |
| `pendingTransition` | `pending_transition`                             |
| `wheelSpinsToday`   | `wheel_spins_today`                              |
| `lastWheelDay`      | `last_wheel_day`                                 |
| `grid` v2 cells     | flat int grid                                    |
| `stats`             | `progress.stats`                                 |
| `achievements`      | `progress.achievements` (camelCase → snake_case) |

## i18n rules

| Rule             | Detail                                                                            |
| ---------------- | --------------------------------------------------------------------------------- |
| Locales          | Ukrainian (default), Russian, English                                             |
| Source of truth  | `godot/assets/i18n/{uk,ru,en}.json` — **285 keys** each                           |
| Origin           | Ported from `js/system/i18n/i18n.js`                                              |
| API              | `I18nManager` autoload; screens call `tr()` / manager helpers                     |
| Fallback chain   | uk → ru → en                                                                      |
| Tests            | `npm run godot:test:i18n`                                                         |
| Web-only strings | Toasts, confirm dialogs — partial in Godot (visual TODO per `VISUAL_PORT_MAP.md`) |

Language selection persists via `SettingsManager`; UI refreshes on change.

## Level progression

| Rule         | Detail                                                                      |
| ------------ | --------------------------------------------------------------------------- |
| Preset count | **40** manual levels (`LevelManager.MANUAL_LEVEL_COUNT := 40`)              |
| After preset | Procedural endless via `getLevelConfig(levelIndex)` — deterministic targets |
| Save field   | `current_level` (0-based index); target recomputed on load                  |
| Parity       | Matches `js/game/state.js` `MANUAL_LEVEL_COUNT = 40`                        |

## Screen structure

### Entry flow

```
Boot.tscn (main_scene)
  → preload SaveManager + App
  → fade
  → App.tscn (shell)
  → MainMenu via ScreenRouter
```

### App shell (`App.tscn`)

| Layer              | Purpose                                     |
| ------------------ | ------------------------------------------- |
| `BackgroundLayer`  | Global art, dim overlay, optional particles |
| `ScreenRoot`       | Active screen instance                      |
| `OverlayRoot`      | Modals, stubs, wheel overlay                |
| `ScreenTransition` | Fade / slide cover-uncover                  |

### ScreenRouter (`ScreenRouter.gd` autoload)

| Screen ID      | Scene               |
| -------------- | ------------------- |
| `main_menu`    | `MainMenu.tscn`     |
| `game`         | `Game.tscn`         |
| `settings`     | `Settings.tscn`     |
| `achievements` | `Achievements.tscn` |
| `daily`        | `DailyQuests.tscn`  |
| `wheel`        | `Wheel.tscn`        |
| `stats`        | `Stats.tscn`        |
| `about`        | `About.tscn`        |
| `skin_preview` | `SkinPreview.tscn`  |

| Navigation rule | Detail                                                     |
| --------------- | ---------------------------------------------------------- |
| API             | `push()`, `replace()`, `go_back()`, `reload_current()`     |
| Back-stack      | `push()` saves previous screen; `go_back()` pops           |
| Transitions     | 0.18s fade; slide when `bg_effects_enabled`                |
| Android back    | `App.gd` → `NOTIFICATION_WM_GO_BACK_REQUEST` → `go_back()` |
| Standalone (F6) | Falls back to `change_scene_to_file`                       |

Screens **must not** call `get_tree().change_scene_to_file` directly when the App shell is mounted.

## Visual system

### Dark Neon Fantasy (design spec v2)

Applied across `ThemeTokens.gd`, `LnUi.gd`, `NeonButton.tscn`, `lost_number_theme.tres`, `BackgroundLayer.tscn`, and screen scripts.

| Token        | Example                                                           |
| ------------ | ----------------------------------------------------------------- |
| Background   | `#0a0e27`, `#141829`, `#1a1f3a`                                   |
| Neon accents | purple `#b83dff`, pink `#ff1b9e`, green `#00ff6b`, cyan `#00f0ff` |
| Text         | primary `#ffffff`, muted `#8a7a9e`                                |

### Themes

| Theme    | UI exposure                                                               |
| -------- | ------------------------------------------------------------------------- |
| Dawn     | Light palette — `DAWN_*` tokens                                           |
| Dusk     | Dark default — aligned with Dark Neon Fantasy                             |
| Twilight | In `ThemeManager.THEMES`; **hidden** from settings toggle until art ships |

Settings cycles **`UI_CYCLE_THEMES` = dawn/dusk only**. MainMenu tagline double-tap calls `ThemeManager.cycle_background()` (6 PNGs per bucket).

### Performance mode

`SettingsManager.bg_effects_enabled` mirrors web `low-performance.css`:

- Disables background particles
- `ScreenRouter` uses fade-only transitions (no slide)

### Asset paths

| Purpose            | Path                  | In AAB?               |
| ------------------ | --------------------- | --------------------- |
| In-game UI         | `godot/assets/ui/`    | Yes                   |
| Play listing       | `store/` (repo root)  | No                    |
| Godot store copies | `godot/assets/store/` | No — `exclude_filter` |

Game scenes reference **`assets/ui/` only**, never `assets/store/*`.

### Custom backgrounds

`ImagePickerHelper.gd` (not MobileImagePicker) → `SkinPreview.tscn` for pick/apply/cancel.

## Compliance

| Topic                     | Decision                                                      |
| ------------------------- | ------------------------------------------------------------- |
| Privacy policy            | `privacy.html` — see [PRIVACY_HOSTING.md](../PRIVACY_HOSTING.md) |
| Play Data Safety          | No collection, no sharing                                     |
| IARC                      | Puzzle; no violence, gambling, IAP, or ads                    |
| Audience                  | Casual 3+                                                     |
| Save encryption at rest   | Not required — SHA-256 integrity + backup; no secrets in save |
| Kyber / mTLS / zero-trust | N/A — offline consumer game                                   |

## Versioning

| Field         | Current     | Rule                                                |
| ------------- | ----------- | --------------------------------------------------- |
| `versionName` | `2.1.6`     | For code ≥ 15: `2.1.(versionCode - 10)`             |
| `versionCode` | `16`        | Increment by 1 on every Play upload                 |
| Debug suffix  | `2.1.6-dev` | Debug preset package: `com.averixor.lostnumber.dev` |

## Versioning note

Godot is the **sole** Play upload path. Increment `versionCode` by 1 on every upload.
