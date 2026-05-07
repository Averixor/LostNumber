// NumberWeights.js — "чувство веса" чисел (эффекты/звуки/вибро)
const NUMBER_WEIGHTS = {
  64: { scale: 1.05, sound: 'light', vibration: 0 },
  128: { scale: 1.08, sound: 'medium', vibration: 30 },
  256: { scale: 1.12, sound: 'heavy', vibration: 50, particle: 'sparkle' },
  512: { scale: 1.16, sound: 'epic', vibration: 80, particle: 'glow', freezeMs: 60 },
  1024: { scale: 1.2, sound: 'legend', vibration: 120, particle: 'star', freezeMs: 120, screenShake: true },
};
