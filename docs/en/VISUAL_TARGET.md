---
language: en
title: Lost Number — Visual North Star
version: 2.1.6
last_updated: 2026-07-12
branch: fix/ui-polish-round-2
status: canonical
---

# Lost Number — Visual North Star

**Canonical visual target** for Lost Number (Godot 4.5 Android). When implementation, `VISUAL_PORT_MAP.md`, or web parity docs disagree with this file, **this file wins** for acceptance criteria — then update code and trackers.

**Reference mockups:** PO-approved gothic-fantasy screenshots (Jul 2026) — hell/lava, gothic purple (dusk), royal purple variants. Same layout principles across themes; only palette and background art change.

**Related docs:**

| Doc                                                                  | Role                                |
| -------------------------------------------------------------------- | ----------------------------------- |
| [SOURCE_OF_TRUTH.md](./SOURCE_OF_TRUTH.md)                           | Version, ship decisions             |
| [docs/archive/VISUAL_PORT_MAP.md](../archive/VISUAL_PORT_MAP.md) | Web → Godot port **status** tracker (historical) |
| [WHEEL_ICON_PROMPTS.md](./WHEEL_ICON_PROMPTS.md)                     | AI prompts for wheel segment PNGs   |

---

## Current vs target gap

Snapshot from APK on `fix/ui-polish-round-2` (Jul 2026) vs PO mockups.

| Area               | Current (shipped feel)                                                                                                                                                    | Target (mockups)                                                                                                                                                                                                                     | Gap severity |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------ |
| **Wheel**          | Flat brown/green segments; small crystal PNG icons feel pasted on; does not blend with purple castle background — reads as a foreign body                                 | Ornate rim (spikes, gold/bronze), demonic/crystal hub; segments colored but cohesive with scene; **large** readable reward icons **on** segments; text labels (+25 XP, ×2, Розбити) integrated; wheel feels part of the castle scene | **Critical** |
| **Main menu**      | Purple neon flat `NeonButton` bars; Exit at top as plain button; wheel entry has tiny butterfly-like icon; bottom-heavy dock; does not match gothic stone/lava references | Logo centered; 1–2 primary **stone-framed** buttons (Нова гра / Продовжити); bottom row of **circular/pedestal** icons (wheel, settings, stats, about) — not 3 huge stacked neon bars + separate dock                                | **Critical** |
| **Gameplay HUD**   | Functional layout; bonus row has small icons on buttons (post-`aa3adae`); bars and actions still read as flat neon UI                                                     | Stone-framed progress bars; action buttons with clear icon + text in carved frames; numbers on tiles with inner glow                                                                                                                 | **High**     |
| **Settings**       | Scroll list with neon toggles; skin picker exists but thumbnails not prominent                                                                                            | Toggle rows in stone panels; skin carousel with **visible thumbnails**                                                                                                                                                               | **Medium**   |
| **Tiles**          | ThemeTokens palette, chain highlight — readable but flat compared to mockups                                                                                              | Numbers with inner glow; tile faces feel carved/stone or gem-inset, consistent with HUD chrome                                                                                                                                       | **Medium**   |
| **Theme cohesion** | `dawn`/`dusk` backgrounds; UI chrome mostly generic neon (`NeonButton`, flat panels)                                                                                      | Theme profiles (hell/lava, gothic purple, royal purple): **background and UI chrome share palette** — not floating rectangles on unrelated art                                                                                       | **High**     |
| **Iconography**    | Wheel/bonus icons exist as gothic PNGs but displayed too small; HUD icons recently added, still undersized                                                                | Icons large enough to read at phone scale; integrated into frames, not floating stickers                                                                                                                                             | **High**     |

---

## Незмінні принципи (non-negotiable)

Ці правила застосовуються до **всіх** екранів і тем. Порушення = не приймається PO, навіть якщо web parity або старий код каже інакше.

1. **Інтеграція, а не наклейки.** Кожен UI-елемент (кнопка, сегмент колеса, панель HUD) має виглядати частиною сцени — камінь, метал, ланцюги, роги, різьблені рамки. Заборонено «плоскі неонові прямокутники», що парять над фоном замку/лави.

2. **Читабельність іконок.** Іконка нагороди на колесі та бонусах має бути **великою** в межах свого контейнера (орієнтир mockup: ~40–55% висоти сегмента для wheel, не ~20px sticker). Силует має читатися на темному сегменті без збільшення.

3. **Текст + іконка разом.** Підписи (+25 XP, ×2, Розбити, Нова гра) — у тій самій рамці, що й іконка, не окремим дрібним шаром. Один ієрархічний блок на кнопку/сегмент.

4. **Один шрифт на екран.** Один сімейний стиль (display для заголовків, body для підписів) без змішування випадкових розмірів/ваг. Контраст достатній для OLED і яскравого фону.

5. **Хром відповідає темі.** Палітра рамок, свічення й акцентів береться з активного **theme profile** (фон + UI), а не з універсального фіолетового неону для всього.

6. **Ієрархія головного меню.** Логотип — центр уваги; 1–2 первинні CTA; другорядні дії — компактний нижній ряд піедесталів/круглих кнопок, не три великі смуги + окремий важкий dock.

7. **Колесо — герой екрана.** Ободок, ступиця, сегменти й іконки — єдиний арт-об'єкт; фон замку видно навколо, але колесо не виглядає імпортованим PNG поверх UI.

8. **Без регресу функцій.** Візуальна поліровка не змінює touch targets, i18n keys, навігацію `ScreenRouter`, логіку `WheelManager` — лише презентацію.

---

## Per-screen targets

### MainMenu

| Element     | Target                                                                                                                                                                   |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Layout      | Centered logo; primary column: **Нова гра**, **Продовжити** (if save); secondary: single bottom row of round/pedestal actions                                            |
| Buttons     | Stone/metal carved frames with horn or chain accents; warm inner glow on hover/press — not flat `NeonButton` fill                                                        |
| Wheel entry | Distinct wheel icon on pedestal — large, ornate, matches wheel screen art language                                                                                       |
| Exit / back | Integrated into chrome (e.g. top corner sigil), not a full-width neon bar at top                                                                                         |
| Dock        | Replace bottom-heavy multi-row dock with mockup row: wheel · settings · stats · about (premium/tournaments/achievements/daily as stubs or smaller tier-2 if PO confirms) |
| Background  | Full-bleed theme background; UI sits **in** the scene (parallax optional later)                                                                                          |

**Godot refs:** `godot/scenes/MainMenu.tscn`, `NeonButton.tscn`, `ThemeManager.gd`

### Wheel (Колесо фортуни)

| Element           | Target                                                                                                                                             |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Rim               | Ornate outer ring: spikes, gold/bronze, possibly rotating subtle highlight                                                                         |
| Hub               | Demonic crystal or metal boss — focal point, matches gothic fantasy                                                                                |
| Segments          | Colored wedges cohesive with scene (not flat MS Paint green/brown); optional sector labels on rim                                                  |
| Icons             | Large gothic PNGs per [WHEEL_ICON_PROMPTS.md](./WHEEL_ICON_PROMPTS.md) — **display** at mockup scale (target ~48–64px logical on phone, not ~36px) |
| Labels            | Integrated text: +25 XP, +50 XP, …, ×2, explosion/shuffle/break names via i18n                                                                     |
| Spin control      | Stone-framed **Крутити** (or icon+text) at bottom; matches menu button language                                                                    |
| Scene integration | Wheel centered; castle/lava background visible; vignette ties wheel to environment                                                                 |

**Godot refs:** `godot/scenes/Wheel.tscn`, `WheelCanvas` / wheel draw code, `godot/assets/ui/icons/wheel/`

**Icon note:** Gothic PNG assets are **approved**; gap is **frame + scale + composition**, not art style change.

### GameHud

| Element      | Target                                                                                          |
| ------------ | ----------------------------------------------------------------------------------------------- |
| Top bar      | Stone-framed level/goal/XP; progress bar carved channel with fill glow                          |
| Target panel | Readable goal number in framed panel; matches mockup hierarchy                                  |
| Bonus row    | Each bonus: carved frame, **icon + short label**, clear available/disabled/cooldown states      |
| Chain HUD    | Neon accent allowed **inside** stone frame for valid/invalid chain sum — not bare floating text |
| Spacing      | No clutter; safe areas for notched phones                                                       |

**Godot refs:** `godot/scenes/GameHud.tscn`, `GameHud.gd`

### Settings

| Element       | Target                                                                             |
| ------------- | ---------------------------------------------------------------------------------- |
| Panels        | Rows grouped in stone panels (audio, theme, skin, import stub)                     |
| Toggles       | Custom toggle art in frame — not default Godot checkbox alone                      |
| Theme picker  | Visible preview of dawn/dusk/(future twilight); labels match profile name          |
| Skin carousel | Horizontal thumbnails of `background_index` skins — tap to preview → `SkinPreview` |
| Back          | Pinned bottom stone button consistent with other screens                           |

**Godot refs:** `godot/scenes/Settings.tscn`, `SkinPreview.tscn`, `ThemeManager.UI_CYCLE_THEMES`

### Tiles

| Element | Target                                                                                  |
| ------- | --------------------------------------------------------------------------------------- |
| Face    | Rounded cell with depth (inner shadow + highlight); number centered                     |
| Number  | Inner glow on digits for high values; palette from `ThemeTokens` per theme profile      |
| States  | Selected / valid chain / invalid / frozen — clear border or glow **within** tile chrome |
| Board   | Grid panel feels inset stone slab, not flat rectangle                                   |

**Godot refs:** `godot/scenes/components/Tile.tscn`, `Tile.gd`, `ThemeTokens.gd`, `Board.gd`

---

## Theme profiles (future: `VisualThemeProfile`)

Today: `ThemeManager` exposes `dawn`, `dusk`, `twilight` (twilight hidden in UI); backgrounds in `godot/assets/ui/backgrounds/`.

**Target:** Named **VisualThemeProfile** resources pairing:

| Profile              | Background mood             | UI chrome accents                           |
| -------------------- | --------------------------- | ------------------------------------------- |
| Hell / lava          | Orange-red embers, volcanic | Bronze, burnt gold, red inner glow          |
| Gothic purple (dusk) | Purple castle, candlelit    | Amethyst, bronze filigree, violet edge glow |
| Royal purple         | Deeper violet, regal        | Gold rim, jewel tones                       |

Each profile supplies: background asset set, `ThemeTokens` overrides, button frame style, wheel rim palette, HUD bar style. User-facing theme toggle cycles profiles; skin carousel picks variant within profile.

**Status:** Not implemented as `VisualThemeProfile` resource yet — document as north star; implement in UI polish phases after frame assets land.

---

## Acceptance checklist (PO / QA)

Use with mockup screenshots side-by-side on device:

- [ ] Main menu: ≤2 large primary CTAs; bottom icon row; no dominant neon bars
- [ ] Wheel: ornate rim visible; icons readable without squinting; labels on segments
- [ ] Wheel does not look like separate asset pasted on castle BG
- [ ] Game HUD: stone-framed bars and bonus buttons with icon+text
- [ ] Settings: skin thumbnails visible in carousel
- [ ] Tiles: numbers readable with glow; grid feels inset
- [ ] Active theme: UI chrome palette matches background family

---

## Implementation notes (non-code)

- Prefer **nine-patch / TextureButton / StyleBoxTexture** carved frames over flat `StyleBoxFlat` neon.
- Reuse one **frame atlas** per theme profile where possible.
- `VISUAL_PORT_MAP.md` status should move to **DONE** only when this checklist passes for that screen.
- New art: follow [WHEEL_ICON_PROMPTS.md](./WHEEL_ICON_PROMPTS.md); wheel **frame** art needs separate PO brief (rim, hub, pointer).

---

_Last aligned with PO mockups and `fix/ui-polish-round-2` APK review — 2026-07-12._
