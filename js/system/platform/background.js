/**
 * Rotating visual skins: background + menu composition variants, auto-advance
 * when the calendar day changes (on main menu enter). State in localStorage key
 * lostNumberBackground for backward compatibility.
 */
const BackgroundRotator = {
  STORAGE_KEY: 'lostNumberBackground',
  LEGACY_SKIN_ALIASES: {
    synthwave: 'skin-1',
    ember: 'skin-3',
    crystal: 'skin-4',
  },
  SKINS: [
    {
      id: 'skin-1',
      nameKey: 'visual_skin_1',
      background: './assets/images/menu-skin-1.png',
      gameTheme: 'dusk',
      artwork: 'mockup',
      titleFrame: 'none',
      quickRow: 'circles',
      primaryBtn: 'pill',
    },
    {
      id: 'skin-2',
      nameKey: 'visual_skin_2',
      background: './assets/images/menu-skin-2.png',
      gameTheme: 'dusk',
      artwork: 'mockup',
      titleFrame: 'diamond',
      quickRow: 'circles',
      primaryBtn: 'pill',
    },
    {
      id: 'skin-3',
      nameKey: 'visual_skin_3',
      background: './assets/images/menu-skin-3.png',
      gameTheme: 'dawn',
      artwork: 'mockup',
      titleFrame: 'arc',
      quickRow: 'boxed',
      primaryBtn: 'pill',
    },
    {
      id: 'skin-4',
      nameKey: 'visual_skin_4',
      background: './assets/images/menu-skin-4.png',
      gameTheme: 'dusk',
      artwork: 'mockup',
      titleFrame: 'none',
      quickRow: 'circles',
      primaryBtn: 'skew',
    },
    {
      id: 'skin-5',
      nameKey: 'visual_skin_5',
      background: './assets/images/menu-skin-5.png',
      gameTheme: 'dawn',
      artwork: 'mockup',
      titleFrame: 'arc',
      quickRow: 'boxed',
      primaryBtn: 'pill',
    },
    {
      id: 'skin-6',
      nameKey: 'visual_skin_6',
      background: './assets/images/menu-skin-6.png',
      gameTheme: 'dusk',
      artwork: 'mockup',
      titleFrame: 'none',
      quickRow: 'boxed',
      primaryBtn: 'pill',
    },
  ],
  DAY_MS: 24 * 60 * 60 * 1000,

  get IMAGES() {
    return this.SKINS.map((skin) => skin.background);
  },

  getTodayKey() {
    const d = new Date();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${d.getFullYear()}-${m}-${day}`;
  },

  /** Deterministic starting index for first install (no stored state). */
  getDailyIndex() {
    const d = new Date();
    const dayNumber = Math.floor(
      Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()) / this.DAY_MS,
    );
    return dayNumber % this.IMAGES.length;
  },

  normalizeIndex(index) {
    const len = this.SKINS.length;
    if (!len) return 0;
    const n = Number(index);
    if (!Number.isFinite(n)) return 0;
    return ((n % len) + len) % len;
  },

  getSkin(index) {
    return this.SKINS[this.normalizeIndex(index)] || this.SKINS[0];
  },

  getSkinIndex(value) {
    if (typeof value === 'string') {
      const skinId = this.LEGACY_SKIN_ALIASES[value] || value;
      const byId = this.SKINS.findIndex((skin) => skin.id === skinId);
      if (byId >= 0) return byId;
    }
    return this.normalizeIndex(value);
  },

  getCurrentSkin() {
    const el = document.getElementById('appBackground');
    const index = el?.dataset?.bgIndex;
    return this.getSkin(index ?? this.resolveIndex({ advanceOnNewDay: false }));
  },

  normalizePreference(value) {
    if (value === 'auto') return { mode: 'auto', index: null };
    const skinId = typeof value === 'string' ? this.LEGACY_SKIN_ALIASES[value] || value : value;
    const bySkinId = this.SKINS.findIndex((skin) => skin.id === skinId);
    if (bySkinId >= 0) {
      return { mode: 'manual', index: bySkinId };
    }
    const n = Number(value);
    if (Number.isFinite(n)) {
      return { mode: 'manual', index: this.normalizeIndex(n) };
    }
    return { mode: 'auto', index: null };
  },

  readStoredState() {
    try {
      const raw = localStorage.getItem(this.STORAGE_KEY);
      if (!raw) return null;
      const parsed = JSON.parse(raw);
      if (!parsed || typeof parsed !== 'object') return null;
      const mode = parsed.mode === 'manual' ? 'manual' : 'auto';
      const index = this.normalizeIndex(parsed.index);
      const manualIndex =
        typeof parsed.manualSkin === 'string'
          ? this.getSkinIndex(parsed.manualSkin)
          : this.normalizeIndex(parsed.manualIndex ?? index);
      return {
        index,
        lastDay: typeof parsed.lastDay === 'string' ? parsed.lastDay : null,
        mode,
        manualIndex,
        manualSkin: this.getSkin(manualIndex).id,
      };
    } catch (_) {
      return null;
    }
  },

  writeStoredState(index, day, options = {}) {
    try {
      const mode = options.mode === 'manual' ? 'manual' : 'auto';
      const safe = this.normalizeIndex(index);
      const manualIndex = this.normalizeIndex(options.manualIndex ?? safe);
      const manualSkin = this.getSkin(manualIndex).id;
      localStorage.setItem(
        this.STORAGE_KEY,
        JSON.stringify({
          index: safe,
          lastDay: day,
          mode,
          manualIndex,
          manualSkin,
        }),
      );
    } catch (_) {}
  },

  /**
   * @param {{ advanceOnNewDay?: boolean }} [options]
   * @returns {number}
   */
  resolveIndex(options = {}) {
    const advanceOnNewDay = options.advanceOnNewDay !== false;
    const today = this.getTodayKey();
    const stored = this.readStoredState();

    if (!stored) {
      return this.getDailyIndex();
    }

    if (stored.mode === 'manual') {
      return stored.manualIndex;
    }

    if (stored.lastDay === today) {
      return stored.index;
    }

    if (!advanceOnNewDay) {
      return stored.index;
    }

    return this.normalizeIndex(stored.index + 1);
  },

  getPreferenceValue() {
    const stored = this.readStoredState();
    if (stored?.mode === 'manual') {
      return stored.manualSkin;
    }
    return 'auto';
  },

  setPreferenceValue(value) {
    const preference = this.normalizePreference(value);
    const today = this.getTodayKey();

    if (preference.mode === 'manual') {
      const index = preference.index;
      this.apply(index);
      this.writeStoredState(index, today, { mode: 'manual', manualIndex: index });
      return index;
    }

    const stored = this.readStoredState();
    const index =
      stored?.mode === 'auto'
        ? this.resolveIndex({ advanceOnNewDay: false })
        : this.getDailyIndex();
    this.apply(index);
    this.writeStoredState(index, today, { mode: 'auto' });
    return index;
  },

  apply(index) {
    const safe = this.normalizeIndex(index);
    const skin = this.getSkin(safe);
    const url = this.resolveImageUrl(skin.background);
    const cssValue = `url("${url}")`;

    try {
      document.documentElement.style.setProperty('--app-bg-image', cssValue);
      document.documentElement.dataset.visualSkin = skin.id;
      document.documentElement.dataset.skinArtwork = skin.artwork || 'native';
      document.documentElement.dataset.titleFrame = skin.titleFrame || 'none';
      document.documentElement.dataset.quickRow = skin.quickRow || 'chips';
      document.documentElement.dataset.primaryBtn = skin.primaryBtn || 'pill';
      document.documentElement.dataset.gameTheme = skin.gameTheme || 'dusk';
    } catch (_) {}

    const el = document.getElementById('appBackground');
    if (el) {
      el.style.backgroundImage = cssValue;
      el.dataset.bgIndex = String(safe);
      el.dataset.visualSkin = skin.id;
      el.dataset.skinArtwork = skin.artwork || 'native';
      el.dataset.bgDay = this.getTodayKey();
    }
  },

  resolveImageUrl(path) {
    try {
      return new URL(path, document.baseURI).href;
    } catch (_) {
      return path;
    }
  },

  /** First paint on load — use stored index for today, or advance if day rolled over. */
  init() {
    const today = this.getTodayKey();
    const stored = this.readStoredState();
    const index = this.resolveIndex({ advanceOnNewDay: true });
    this.apply(index);
    this.writeStoredState(index, today, {
      mode: stored?.mode === 'manual' ? 'manual' : 'auto',
      manualIndex: stored?.manualIndex ?? index,
    });
    return index;
  },

  /** Each main-menu visit: rotate when the calendar day changed since last stored day. */
  onMainMenuEnter() {
    const today = this.getTodayKey();
    const stored = this.readStoredState();
    let index;

    if (!stored) {
      index = this.getDailyIndex();
    } else if (stored.mode === 'manual') {
      index = stored.manualIndex;
    } else if (stored.lastDay === today) {
      index = stored.index;
    } else {
      index = this.normalizeIndex(stored.index + 1);
    }

    this.apply(index);
    this.writeStoredState(index, today, {
      mode: stored?.mode === 'manual' ? 'manual' : 'auto',
      manualIndex: stored?.manualIndex ?? index,
    });
    return index;
  },
};

if (typeof window !== 'undefined') {
  window.BackgroundRotator = BackgroundRotator;
}
