# Visual Port Map — Godot visual implementation status

> Historical note: the former browser/JS implementation has been removed from the
> repository. References to Web/CSS/JS below are retained only to document migration
> history and provenance of behavior or assets.
>
> **Web parity is not a visual acceptance criterion.**
>
> Canonical visual acceptance target:
> `docs/en/VISUAL_TARGET.md`
>
> When this tracker conflicts with `VISUAL_TARGET.md`, the visual target wins.
> Current Godot code remains the technical source of truth for what is actually
> implemented.

---

## Purpose

This file tracks the implementation state of visual systems in the active Godot
version of Lost Number.

It answers two separate questions:

1. Has the functionality / presentation been migrated into Godot?
2. Does the current Godot presentation meet the approved visual target?

These are intentionally separate.

A screen may be fully migrated and still require substantial visual work.

---

## Status model

### Implementation status

- **TODO** — no meaningful Godot implementation yet.
- **PARTIAL** — Godot implementation exists but is incomplete.
- **DONE** — required runtime functionality exists in Godot.

### Visual acceptance

- **NOT REVIEWED** — visual result has not been evaluated against
  `docs/en/VISUAL_TARGET.md`.
- **NEEDS POLISH** — usable implementation exists but does not yet meet the
  approved visual language.
- **TARGET PARTIAL** — meaningful target styling is present, but one or more
  acceptance requirements remain.
- **ACCEPTED** — passes the current PO visual target at device scale.

`DONE` implementation does not imply `ACCEPTED` visual quality.

---

## Canonical visual rule

Lost Number uses world-integrated gothic-fantasy UI.

Final UI should appear physically connected to the current environment through:

- carved stone;
- forged / aged metal;
- bronze or gold trim;
- horns;
- chains;
- spikes;
- engraved ornament;
- gothic framing;
- inset panels;
- pedestals;
- gems / magical cores;
- controlled inner or environmental glow.

Flat neon rectangles floating over castle, lava, or royal artwork are not an
accepted final style.

Glow is an accent and state-feedback mechanism, not the structural language of
the interface.

---

## Gothic Crystal — first vertical slice

The Gothic Crystal runtime kit is a Godot-native visual implementation.

Current architecture:

- `VisualSkin.gd` defines background/palette and semantic UI styles;
- `gothic_crystal.tres` registers the component kit;
- `ThemeManager.visual_skin_id` selects the kit independently from background
  brightness/profile state;
- `LnUi` queries semantic styles from the active kit;
- procedural `StyleBoxFlat` rendering remains a fallback, not the visual target;
- `BackgroundLayer` remains the single App-shell background layer;
- Gothic Crystal is currently scoped intentionally to approved runtime areas;
- `Tile` keeps runtime labels and states while adding material/frame layers;
- low-effects mode removes expensive particles, multi-pass glow and optional
  tweens while preserving frame readability and state communication;
- all runtime text remains real Godot `Label` content using uk/ru/en i18n.

The current Gothic Crystal slice is useful as an architectural foundation, but
it is not permission to treat generic procedural neon controls as visually
finished.

---

## Screen status

| Screen | Godot target | Implementation | Visual acceptance |
| --- | --- | ---: | ---: |
| Main Menu | `godot/scenes/MainMenu.tscn` | DONE | TARGET PARTIAL |
| Game | `Game.tscn` + `GameHud.tscn` | DONE | TARGET PARTIAL |
| Settings | `Settings.tscn` | DONE | TARGET PARTIAL |
| Skin Preview | `SkinPreview.tscn` | PARTIAL | TARGET PARTIAL |
| Background Preview | `BackgroundPreview.tscn` | PARTIAL | TARGET PARTIAL |
| About | `About.tscn` | DONE | TARGET PARTIAL |
| Achievements | `Achievements.tscn` | DONE | TARGET PARTIAL |
| Stats | `Stats.tscn` | DONE | TARGET PARTIAL |
| Daily Quests | `DailyQuests.tscn` | DONE | TARGET PARTIAL |
| Wheel | `Wheel.tscn` | DONE | TARGET PARTIAL |
| Boot | `Boot.tscn` | DONE | TARGET PARTIAL |
| App shell / navigation | `App.tscn` + `ScreenRouter.gd` | DONE | N/A |

---

## Main Menu

### Runtime state

Existing Godot implementation includes:

- primary Play / Continue flow;
- Settings / Stats / About navigation;
- bottom navigation/dock functionality;
- SVG icon support;
- feature-stub overlays;
- background cycling;
- entrance animation;
- ScreenRouter navigation.

This means the menu functionality is migrated.

### Visual target

The menu is **not considered visually complete merely because web parity was
reached**.

Target composition:

- centered Lost Number logo as the main visual anchor;
- no more than 1–2 dominant primary CTAs;
- primary buttons built as substantial stone / metal fantasy controls;
- secondary actions presented as a compact bottom row;
- round controls, medallions, sigils or pedestal-based navigation;
- Exit integrated into chrome rather than competing as a large button;
- UI materials matching the active environment/theme family.

Legacy-style flat `NeonButton` bars are fallback / transitional presentation,
not final acceptance.

#### Current visual status

Status: TARGET PARTIAL

---

## Wheel — Колесо фортуни

### Wheel: Runtime state

Current Godot implementation includes:

- `Wheel.tscn`;
- canvas-based wheel rendering;
- spin animation;
- result flow;
- dimmed result presentation;
- `WheelManager` runtime integration.

Implementation remains **PARTIAL** because presentation work is still being
iterated.

### Canonical visual target

The Wheel is the hero object of this screen.

It must feel like a physical fantasy mechanism placed inside the scene, not a
generic circular chart.

Required direction:

#### Rim

- large, substantial outer construction;
- carved / forged depth;
- bronze, gold, dark metal or stone depending on profile;
- theme-specific spikes, horns, chains, runes, filigree or gems;
- no thin generic circle acting as the entire frame.

#### Hub

- visually dominant central boss;
- crystal, demonic core, metal boss, rune mechanism or equivalent;
- same material language as the rim.

#### Pointer

- visually substantial;
- integrated with the wheel construction;
- not a generic floating triangle.

#### Segments

Segments may use different colors, but must not resemble flat pie-chart wedges.

Prefer:

- inset material surfaces;
- subtle texture;
- engraved or metal separators;
- theme-derived color variation;
- controlled gradients;
- integrated lighting.

#### Reward content

Each segment must contain:

Required content: large reward icon + short localized label

Examples:

- `+25 XP`;
- `+50 XP`;
- `+75 XP`;
- `+100 XP`;
- `×2`;
- localized shuffle / break / explosion label.

Approved gothic reward PNGs remain valid.

The problem to solve is primarily:

- scale;
- layout;
- framing;
- integration.

Do not replace approved reward art merely because previous implementations
displayed it too small.

#### Spin action

Spin must use the same material language as the wheel and surrounding scene.

A generic rounded gold or neon rectangle is not sufficient final styling.

#### Limit indicator

A compact limit badge is acceptable when framed and styled as part of the same
visual system.

It must not read as a modern mobile-app pill pasted below the wheel.

#### Functional boundary

Wheel polish must not change:

- reward table;
- payout economy;
- daily limit behavior;
- `WheelManager`;
- save behavior.

#### Wheel visual status

Status: TARGET PARTIAL

---

## Game / HUD

Current Godot implementation contains:

- top HUD;
- XP progress;
- target panel;
- bonus row;
- chain feedback;
- board;
- tiles;
- chain rendering.

The implementation is functional but visually mixed.

### Target

- stone / metal framed level, target and XP sections;
- progress fill inside a carved/inset channel;
- bonus controls using icon + short label inside the same frame;
- chain feedback allowed to use stronger magical/neon color;
- glow must live inside or around physical UI structure;
- no bare dashboard-style bars as final presentation.

#### Game HUD visual status

Status: TARGET PARTIAL

---

## Board and Tiles

### Existing runtime

Current implementation includes:

- 5×8 board;
- tile palette;
- selected / valid / invalid states;
- chain line rendering;
- carry state;
- tile animation;
- frozen-state presentation;
- preview bubble;
- chain-sum logic.

### Board and Tiles: Target

Board:

- inset stone slab / altar / game-table impression;
- clear separation from the background;
- not a plain rectangular panel.

Tile:

- visible depth;
- inner shadow;
- edge highlight;
- stone, metal, crystal or gem-inset material impression;
- centered number;
- high-value inner glow where appropriate.

States:

- selection and validity should modify the tile's own chrome;
- use border, inner glow, rune light or material change;
- avoid unrelated floating overlays.

---

## Theme integration

Current runtime theme/background architecture and the future visual-profile
target are separate concepts.

Current systems must not be misrepresented as though the full
`VisualThemeProfile` architecture already exists.

### Long-term target profiles

#### Hell / Lava

Background language:

- volcanic;
- infernal;
- ember-lit.

Chrome:

- burnt bronze;
- scorched stone;
- blackened metal;
- heated gold;
- restrained red/orange inner light;
- horns / chains / cracks where appropriate.

#### Gothic Purple

Background language:

- dark castle;
- cathedral;
- violet atmosphere.

Chrome:

- dark metal;
- stone;
- bronze filigree;
- amethyst;
- violet inner or edge light;
- gothic arches / chains / restrained spikes.

#### Royal Purple

Background language:

- regal dark fantasy;
- deep violet;
- richer decoration.

Chrome:

- gold / brass;
- polished dark metal;
- jewel tones;
- heraldic forms;
- royal purple material accents.

A component should not remain visually identical across all three families
except where deliberate reuse is approved.

---

## Settings

Runtime functionality currently includes:

- scrolling settings;
- pinned Back control;
- dawn/dusk user theme cycle;
- component kit preview;
- background preview;
- custom image import.

### Settings: Visual target

- controls grouped inside stone / metal panels;
- custom theme-integrated toggles;
- visible theme previews;
- clear background / skin thumbnails;
- Back control consistent with other scene-integrated navigation.

Generic neon rows are transitional UI.

#### Settings visual status

Status: TARGET PARTIAL

---

## Background and visual-kit separation

Component kit and background selection are intentionally separate concerns.

A component kit may define:

- panel frame;
- button frame;
- tile material;
- HUD chrome;
- wheel chrome;
- semantic styling.

A background choice selects the environment variant.

Future profile architecture may pair these more strongly, but current runtime
behavior must not be silently changed during visual polish.

---

## Store graphics vs runtime assets

| Purpose | Path | Runtime export |
| --- | --- | ---: |
| Store / listing graphics | repository `store/` | No |
| Godot store copies | `godot/assets/store/` | No |
| Test helpers | `godot/scripts/tests/` | No |
| Runtime game UI | `godot/assets/ui/` | Yes |

Runtime scenes must not reference `assets/store/*`.

Only runtime UI assets belong under `godot/assets/ui/`.

---

## Icons

Current runtime icon sources include the Godot UI icon tree.

Existing gothic Wheel reward images are approved as source artwork.

Final visual acceptance depends on:

- adequate rendered size;
- silhouette readability;
- correct framing;
- proper contrast;
- integration with the active material profile.

A good icon displayed as a tiny sticker is still a visual failure.

---

## i18n

All visible runtime labels remain real localized UI text.

Supported locales:

- Ukrainian;
- Russian;
- English.

Visual polish must preserve:

- localization keys;
- placeholder behavior;
- readable text width;
- readable labels at phone scale.

Do not bake user-facing language into decorative art.

The current tracker reports **305 keys per locale**. Treat this as a repository
snapshot and re-check current locale files before quoting it as a release fact.

---

## Overlays and modal components

| Component | Runtime status | Visual acceptance |
| --- | ---: | ---: |
| Victory Overlay | TODO | NOT REVIEWED |
| Level Overlay | PARTIAL | NEEDS POLISH |
| Wheel result flow | PARTIAL | TARGET PARTIAL |
| Confirm Dialog | TODO | NOT REVIEWED |
| System Toast | TODO | NOT REVIEWED |
| Feature Stub Overlay | DONE | TARGET PARTIAL |
| Screen Transition | DONE | NOT REVIEWED |

New overlay components should use the same world-integrated visual rules.

Do not introduce generic modal cards as final styling.

Reusable UI components belong under:

`godot/scenes/components/`

---

## Low-effects requirements

Low-effects mode may disable or simplify:

- particles;
- repeated glow passes;
- expensive shader effects;
- optional gameplay tweens;
- decorative motion.

It must preserve:

- material framing;
- readable text;
- icon readability;
- state distinction;
- functional hierarchy.

Performance mode must not fall back to visually broken or unstyled default
controls.

---

## Acceptance gate

A screen may be marked **ACCEPTED** only after comparison against
`docs/en/VISUAL_TARGET.md` on a real phone-scale layout.

### Global

- [ ] UI feels integrated with the environment.
- [ ] No dominant generic flat-neon rectangles.
- [ ] Material/chrome matches the active theme family.
- [ ] Icons are readable without zooming.
- [ ] uk/ru/en text remains readable.
- [ ] Touch targets remain usable.
- [ ] Visual polish does not change gameplay or saves.

### Acceptance gate: Main Menu

- [ ] Centered logo is the visual anchor.
- [ ] No more than 1–2 large primary CTAs.
- [ ] Primary controls use carved stone/metal construction.
- [ ] Secondary actions use compact pedestal/medallion navigation.
- [ ] Exit does not visually compete with Play / Continue.

### Wheel

- [ ] Wheel dominates the screen composition.
- [ ] Ornate outer rim has real visual mass.
- [ ] Hub and pointer belong to the same construction.
- [ ] Segments do not resemble a generic pie chart.
- [ ] Reward icons are large and readable.
- [ ] Every sector has a short localized label.
- [ ] Icon + text form one composition.
- [ ] Wheel feels physically present in the environment.
- [ ] Spin control uses matching material language.
- [ ] Wheel economy remains unchanged.

### Game

- [ ] HUD uses integrated frames.
- [ ] Board feels inset into the scene.
- [ ] Tiles have visible material depth.
- [ ] Bonus controls contain icon + text.
- [ ] Chain feedback remains immediately readable.

### Acceptance gate: Settings

- [ ] Controls are grouped into integrated panels.
- [ ] Theme/background previews are visible.
- [ ] Skin/background thumbnails remain touch-friendly.

---

## Final visual question

For every major UI element ask:

> Does this look like an object that belongs inside this exact fantasy
> environment, or like an app control placed on top of a background?

If it looks like the second, visual work is not finished.
