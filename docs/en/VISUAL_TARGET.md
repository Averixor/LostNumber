---
language: en
title: Lost Number — Visual North Star
version: 2.1.7
last_updated: 2026-10-06
status: canonical
---


This document is the canonical visual acceptance target for Lost Number on Godot
4.

When implementation, historical migration documentation, `VISUAL_PORT_MAP.md`,
legacy web parity, or older screenshots disagree with this document, this
document defines the intended visual result.

The active Godot implementation remains the technical source of truth for what
currently exists. This document defines what the finished UI must look and feel
like.

## Core visual identity

Lost Number is a dark gothic-fantasy game.

The interface must feel physically built into the world rather than drawn on top
of it.

UI elements should resemble objects and structures that could exist inside the
scene:

- carved stone;
- forged or aged metal;
- bronze and gold trim;
- chains;
- horns;
- spikes;
- engraved ornament;
- gothic arches;
- pedestals;
- inset panels;
- gems and magical cores;
- controlled environmental glow.

The target is world-integrated gothic fantasy UI, not modern flat neon UI
placed over fantasy artwork.

Neon and magical light are allowed as accents, illumination, state feedback, and
inner glow.

They must not become the primary structural language of buttons, panels, HUD
elements, or navigation.

---

## Non-negotiable principles

These rules apply to every screen and every visual theme.

A screen does not pass visual acceptance if it violates them, even if the old
web implementation, migration tracker, or earlier Godot version looked that way.

## 1. Integration, not stickers

Every major UI element must visually belong to the environment.

Buttons, panels, HUD bars, wheel segments, navigation controls, dialogs, and
status elements should use theme-appropriate materials and framing.

Avoid:

- floating flat rectangles;
- generic translucent cards;
- universal purple neon outlines;
- modern dashboard-style panels;
- plain rounded mobile buttons;
- decorative PNGs pasted onto otherwise unrelated UI.

A useful test:

> If an element could be moved unchanged onto a completely different theme and
> still look correct, it is probably too generic.

---

## 2. Structure comes from material

The shape and hierarchy of UI should come primarily from:

- carved frames;
- metal borders;
- stone slabs;
- inset channels;
- pedestals;
- ornamental separators;
- physical depth;
- bevels and highlights.

Glow supports the material.

Glow does not replace the material.

---

## 3. Icons must read at phone scale

Reward, bonus, navigation, and status icons must remain clearly recognizable on
a real Android phone without zooming.

For Wheel sectors, the reward icon should occupy roughly 40–55% of the useful
visual height of its sector when composition allows.

Tiny decorative stickers are not acceptable.

---

## 4. Icon and text form one component

An icon and its label belong to the same visual object.

Examples:

- reward icon + `+25 XP`;
- multiplier icon + `×2`;
- break icon + localized break label;
- bonus icon + localized action;
- menu icon + its label.

Do not treat the icon as decoration and the text as a separate unrelated
overlay.

---

## 5. Theme chrome follows the environment

UI chrome must inherit the visual language of the active theme family.

The same generic purple neon interface must not be reused unchanged across
unrelated backgrounds.

Theme profiles define both:

- environment/background;
- interface materials and accents.

The visual relationship between them is part of the theme.

---

## 6. Decoration must preserve usability

Gothic ornament must never reduce usability.

Always preserve:

- readable Ukrainian text;
- readable Russian text;
- readable English text;
- strong foreground/background contrast;
- Android-safe touch targets;
- clear primary and secondary actions;
- uncluttered layouts;
- readable icons;
- readable state feedback.

Fantasy styling is not an excuse for visual noise.

---

## 7. Presentation changes must not alter gameplay

Visual polish must not silently change:

- touch behavior;
- navigation;
- `ScreenRouter`;
- save behavior;
- i18n keys;
- Wheel economy;
- `WheelManager` reward tables;
- gameplay rules.

Visual work changes presentation unless a separate gameplay decision is
explicitly approved.

---

## Theme families

The long-term target is a visual-profile system pairing environment art with
matching UI chrome.

A dedicated `VisualThemeProfile` resource is a future implementation target and
must not be treated as already implemented.

## Hell / Lava

Environment:

- volcanic architecture;
- lava;
- ember light;
- scorched surfaces;
- infernal atmosphere.

UI chrome:

- blackened metal;
- burnt bronze;
- scorched stone;
- horns;
- restrained spikes;
- chains;
- cracks;
- ember-red inner lighting;
- heated gold highlights.

Avoid bright flat red UI rectangles.

Light should appear to come from heat, lava, embers, runes, or heated metal.

---

## Gothic Purple

Environment:

- dark castle;
- cathedral silhouettes;
- cold stone;
- deep purple atmosphere;
- candle or magical lighting.

UI chrome:

- dark metal;
- carved stone;
- bronze filigree;
- pointed gothic forms;
- chains;
- restrained spikes;
- amethyst details;
- violet edge or inner glow.

Purple light should feel embedded into the architecture and materials.

---

## Royal Purple

Environment:

- deep violet;
- regal fantasy;
- palace or royal architecture;
- richer ornamental detail.

UI chrome:

- dark polished metal;
- carved stone;
- gold or brass edging;
- jewel tones;
- heraldic motifs;
- gems;
- royal purple enamel or fabric accents.

This profile may be richer and cleaner than Gothic Purple, but it must remain
dark fantasy rather than modern luxury UI.

---

## Main Menu

The Main Menu must establish the visual language of the entire game.

## Layout

Target hierarchy:

1. centered Lost Number logo;
2. one or two dominant primary actions;
3. compact secondary actions at the bottom.

Primary actions:

- `Нова гра`;
- `Продовжити`, when available.

Do not fill the screen with several equally large rectangular buttons.

## Primary CTA

Primary CTA controls should resemble substantial fantasy objects:

- carved stone plates;
- metal-framed slabs;
- engraved plaques;
- horn or chain details;
- warm inner light;
- pressed/highlight state integrated into the material.

Do not use a plain flat `NeonButton` appearance as the final visual target.

## Secondary navigation

Wheel, Settings, Statistics, About, and similar secondary destinations should
use a compact bottom row.

Preferred presentation:

- circular controls;
- sigils;
- medallions;
- small pedestals;
- carved base/platform.

They should visually sit on or emerge from the environment rather than float
independently.

## Exit / Back

Exit should be integrated into scene chrome.

Preferred forms include:

- corner sigil;
- small metal control;
- carved icon;
- integrated top ornament.

Avoid a full-width Exit bar competing with the main CTA.

---

## Wheel of Fortune

The Wheel is the hero object of the screen.

It must read as a physical magical mechanism inside the environment, not as a
circular UI chart.

## Overall composition

The Wheel should dominate the central visual area.

The castle/lava/royal environment remains visible around it, but the Wheel must
feel anchored into that environment.

A vignette or localized lighting may be used to connect foreground and
background.

## Outer rim

Required direction:

- substantial ornate ring;
- metal or carved construction;
- visible depth;
- theme-specific detailing;
- spikes, horns, chains, runes, filigree, gems, or engraved separators where appropriate.

The outer rim should provide enough visual mass that the Wheel feels like an
artifact rather than a chart.

A subtle rotating/specular highlight is optional.

## Hub

The hub is a focal point.

Suitable directions include:

- demonic crystal;
- metal boss;
- gemstone core;
- rune mechanism;
- engraved medallion.

It should visually belong to the same construction as the rim.

## Pointer

The pointer must be clearly readable and visually substantial.

It should use the same material language as the Wheel.

Avoid a small generic triangle that looks unrelated to the artifact.

## Segments

Segments may have different colors, but their treatment must remain cohesive
with the scene.

Avoid flat presentation resembling a generic pie chart.

Use:

- material shading;
- inset faces;
- subtle texture;
- engraved dividers;
- metal separators;
- controlled gradients;
- theme-derived colors.

## Reward content

Each sector must contain:

Required content: large reward icon + short localized label.
on the same sector.

Icons-only and labels-only are not acceptable for the final polish target.

Examples:

- icon + `+25 XP`;
- icon + `+50 XP`;
- icon + `+75 XP`;
- icon + `+100 XP`;
- icon + `×2`;
- bonus icon + localized bonus name.

Existing approved gothic reward PNGs remain valid.

The current gap is primarily:

- scale;
- composition;
- framing;
- integration.

Do not replace approved icon artwork merely because it was previously displayed
too small.

## Spin control

The Spin control must use the same fantasy construction language as the rest of
the screen.

Preferred:

- stone or metal framed CTA;
- icon + localized text where appropriate;
- visually dominant but physically integrated.

Avoid a generic gold rounded rectangle disconnected from the Wheel.

## Limit indicator

Daily/usage limit information may use a compact framed badge or pill only when
its frame is visually integrated with the theme.

It should not look like an unrelated mobile-app chip.

---

## Gameplay HUD

The HUD must remain readable first, decorative second.

## Top information

Level, target, XP, and progress should sit inside:

- carved frames;
- stone/metal plates;
- inset progress channels.

Progress glow should appear inside the structure rather than as a floating neon
bar.

## Bonuses

Each bonus should contain:

- readable icon;
- short localized label;
- clear enabled/disabled/cooldown state;
- carved or metallic frame.

## Chain feedback

Neon/magical feedback is appropriate here.

Valid/invalid/continuation colors may glow strongly, but the information should
still live inside or visually connect to the HUD structure.

Avoid bare floating text unless it is intentionally transient feedback.

---

## Settings

Settings should feel like a functional extension of the same world.

Use grouped stone/metal panels for:

- audio;
- language;
- visual theme;
- skin/background;
- import-related controls.

Custom toggles should visually belong to those panels.

Do not rely on default Godot checkbox styling as the final result.

## Theme selection

Theme controls should show meaningful visual previews.

## Skin selection

Background/skin selection should use visible thumbnails, ideally as a horizontal
carousel or equivalent touch-friendly presentation.

---

## Tiles and Board

Tiles are part of the world, not flat colored squares.

## Tile face

Target qualities:

- depth;
- inner shadow;
- edge highlight;
- stone/gem/metal impression;
- centered readable number.

## Numbers

High-value numbers may use controlled inner glow.

The palette must remain tied to active theme tokens.

## States

Selected, valid, invalid, frozen, and other states should alter the tile's own
chrome.

Prefer:

- inner glow;
- border;
- rune light;
- inset highlight.

Avoid unrelated floating overlays.

## Board

The board should resemble an inset slab, altar, game table, carved stone
structure, or equivalent theme-integrated surface.

It should not read as a plain rectangle containing tiles.

---

## Implementation direction

Prefer Godot-native visual construction.

Preferred techniques include:

- `NinePatchRect`;
- `TextureButton`;
- `StyleBoxTexture`;
- reusable framed components;
- texture atlases;
- shaders where justified;
- theme tokens for colors and lighting.

Prefer reusable frame atlases per visual family where practical.

Avoid rebuilding every control independently.

Do not introduce WebView, browser runtime, legacy web UI, or JavaScript
dependencies for visual implementation.

---

## Acceptance checklist

A screen may move to visually complete only after device-scale review.

## Global

- [ ] UI feels physically integrated into the scene.
- [ ] No dominant generic flat-neon rectangles.
- [ ] UI chrome matches the active background/theme family.
- [ ] Icons remain readable at phone scale.
- [ ] Ukrainian, Russian, and English remain readable.
- [ ] Touch targets remain usable.
- [ ] Visual changes do not alter gameplay behavior.

## Section: Main Menu

- [ ] Logo is the visual anchor.
- [ ] No more than 1–2 dominant primary CTAs.
- [ ] Primary CTAs use carved stone/metal fantasy framing.
- [ ] Secondary navigation is a compact bottom pedestal/icon row.
- [ ] Exit does not compete visually with the main CTA.

## Wheel

- [ ] Wheel is the hero object.
- [ ] Ornate outer rim is visually substantial.
- [ ] Hub and pointer match the wheel construction.
- [ ] Segment treatment does not resemble a flat pie chart.
- [ ] Every sector contains a large readable reward icon.
- [ ] Every sector contains the required short i18n label.
- [ ] Icon and text read as one composition.
- [ ] Wheel visually belongs to the current environment.
- [ ] Spin control matches the same material language.
- [ ] Wheel economy and `WheelManager` behavior are unchanged.

## Section: Gameplay HUD

- [ ] Progress and target panels use integrated frames.
- [ ] Bonus controls use icon + text.
- [ ] Chain feedback remains readable.
- [ ] HUD does not obscure the board.

## Section: Settings

- [ ] Settings are grouped into integrated panels.
- [ ] Theme/background previews are visible.
- [ ] Skin thumbnails are visible and touch-friendly.

## Tiles

- [ ] Tiles have visible material depth.
- [ ] Numbers remain readable.
- [ ] Tile states are expressed inside tile chrome.
- [ ] Board feels inset into the environment.

---

## Final visual test

Ask this for every major element:

> Does this look like an object that belongs in this exact fantasy environment,
> or like an app control placed on top of a background?

If the answer is the second one, the element is not visually finished.
