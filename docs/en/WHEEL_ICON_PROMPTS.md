# Wheel of Fortune — AI icon generation prompts

Generate **one square icon per wheel segment** for Lost Number (Godot Android).
Style: **dark gothic fantasy**, purple-neon accents on stone/bronze, cohesive with the in-game dusk castle background — **not** flat cyberpunk neon.

**Export:** transparent PNG, **64×64** or **128×128** game-ready (512×512 master OK).

## Shared style (prepend to every prompt)

```
Dark gothic fantasy game icon for Lost Number puzzle game, muted amethyst and violet tones,
antique bronze rim accents, subtle purple neon edge glow, candlelit stone atmosphere,
painted illustration, bold readable silhouette at 64px, centered subject,
transparent background, square 128x128, no text, no watermark, no UI frame
```

---

## Segments

### 1. Explosion 3×3 (`explosion`)

```
{SHARED STYLE}, magical blast erupting from a 3x3 grid of cracked stone tiles,
arcane purple shockwave and ember shards, board explosion bonus emblem
```

### 2. Shuffle (`shuffle`)

```
{SHARED STYLE}, two curved gothic arrows forming a reshuffle sigil over dark slate,
tiles mixing motif, elegant minimal shuffle bonus emblem
```

### 3. Break / Destroy (`destroy`)

```
{SHARED STYLE}, single stone tile shattered by a dark crystal strike or bronze chisel,
break-destroy bonus emblem, sharp high-contrast silhouette
```

### 4. +25 XP (`xp25`)

```
{SHARED STYLE}, small amethyst crystal shard with faint gold sparkle,
modest XP reward jewel for fortune wheel segment
```

### 5. +50 XP (`xp50`)

```
{SHARED STYLE}, polished amethyst crystal cluster with thin bronze filigree,
medium XP reward jewel for fortune wheel segment
```

### 6. +75 XP (`xp75`)

```
{SHARED STYLE}, radiant ruby-violet gem in a small bronze bezel,
rich XP reward jewel for fortune wheel segment
```

### 7. +100 XP (`xp100`)

```
{SHARED STYLE}, large royal purple-gold faceted gem, ornate but readable at small size,
top-tier XP bounty emblem for fortune wheel segment
```

### 8. ×2 XP multiplier (`xp_multiplier`)

```
{SHARED STYLE}, twin overlapping crystal shards with golden ring halo suggesting double power,
XP multiplier charm emblem, no literal text characters
```

---

## Usage notes

- Keep the subject **large in frame** (minimal empty margin) for legibility on dark wheel sectors.
- Prefer **cool purple / bronze** over saturated rainbow or flat neon.
- Drop finished PNGs into `godot/assets/ui/icons/wheel/` when ready.
- Wire via `WheelCanvas.set_sector_icon_slot()` — until then the wheel uses **text labels only**.
