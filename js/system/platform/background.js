/**
 * Visual skins: theme-specific clean background art + menu CSS variants.
 * Auto-advance when the calendar day changes (on main menu enter).
 * State in localStorage key lostNumberBackground (per dawn/dusk branch).
 */
const BackgroundRotator = {
  STORAGE_KEY: 'lostNumberBackground',
  LEGACY_SKIN_ALIASES: {
    synthwave: 'skin-1',
    ember: 'skin-3',
    crystal: 'skin-4',
  },
  DARK_BACKGROUNDS: [
    './assets/images/dark/menu-bg-1.png',
    './assets/images/dark/menu-bg-2.png',
    './assets/images/dark/menu-bg-3.png',
    './assets/images/dark/menu-bg-4.png',
    './assets/images/dark/menu-bg-5.png',
    './assets/images/dark/menu-bg-6.png',
  ],
  LIGHT_BACKGROUNDS: [
    './assets/images/light/bg-light-01.png',
    './assets/images/light/bg-light-02.png',
    './assets/images/light/bg-light-03.png',
    './assets/images/light/bg-light-04.png',
    './assets/images/light/bg-light-05.png',
    './assets/images/light/bg-light-06.png',
  ],
  SKINS: [
    {
      id: 'skin-1',
      nameKey: 'visual_skin_1',
      titleFrame: 'none',
      quickRow: 'circles',
      primaryBtn: 'pill',
    },
    {
      id: 'skin-2',
      nameKey: 'visual_skin_2',
      titleFrame: 'diamond',
      quickRow: 'circles',
      primaryBtn: 'pill',
    },
    {
      id: 'skin-3',
      nameKey: 'visual_skin_3',
      titleFrame: 'arc',
      quickRow: 'boxed',
      primaryBtn: 'pill',
    },
    {
      id: 'skin-4',
      nameKey: 'visual_skin_4',
      titleFrame: 'none',
      quickRow: 'circles',
      primaryBtn: 'skew',
    },
    {
      id: 'skin-5',
      nameKey: 'visual_skin_5',
      titleFrame: 'arc',
      quickRow: 'boxed',
      primaryBtn: 'pill',
    },
    {
      id: 'skin-6',
      nameKey: 'visual_skin_6',
      titleFrame: 'none',
      quickRow: 'boxed',
      primaryBtn: 'pill',
    },
  ],
  DAY_MS: 24 * 60 * 60 * 1000,
  _activeGameTheme: 'dusk',

  get IMAGES() {
    return this.getBackgroundsForTheme(this._activeGameTheme);
  },

  normalizeGameTheme(theme) {
    return theme === 'dawn' ? 'dawn' : 'dusk';
  },

  getThemeKind(theme) {
    return this.normalizeGameTheme(theme) === 'dawn' ? 'light' : 'dark';
  },

  getBackgroundsForTheme(theme) {
    return this.getThemeKind(theme) === 'light' ? this.LIGHT_BACKGROUNDS : this.DARK_BACKGROUNDS;
  },

  getDefaultBackgroundPath(theme) {
    return this.getBackgroundsForTheme(theme)[0];
  },

  getBackgroundPath(index, theme) {
    const backgrounds = this.getBackgroundsForTheme(theme);
    const safe = this.normalizeIndex(index, backgrounds.length);
    return backgrounds[safe];
  },

  getTodayKey() {
    const d = new Date();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${d.getFullYear()}-${m}-${day}`;
  },

  getDailyIndex(theme) {
    const backgrounds = this.getBackgroundsForTheme(theme);
    const d = new Date();
    const dayNumber = Math.floor(
      Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()) / this.DAY_MS,
    );
    return dayNumber % backgrounds.length;
  },

  normalizeIndex(index, len) {
    const count = len ?? this.SKINS.length;
    if (!count) return 0;
    const n = Number(index);
    if (!Number.isFinite(n)) return 0;
    return ((n % count) + count) % count;
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
    return this.getSkin(
      index ?? this.resolveIndex(this._activeGameTheme, { advanceOnNewDay: false }),
    );
  },

  createDefaultBranch(theme) {
    const index = this.getDailyIndex(theme);
    const skin = this.getSkin(index);
    return {
      mode: 'auto',
      index,
      lastDay: this.getTodayKey(),
      manualIndex: index,
      manualSkin: skin.id,
      selectedBackground: this.getBackgroundPath(index, theme),
    };
  },

  migrateLegacyState(parsed) {
    const legacy = {
      mode: parsed.mode === 'manual' ? 'manual' : 'auto',
      index: this.normalizeIndex(parsed.index),
      lastDay: typeof parsed.lastDay === 'string' ? parsed.lastDay : null,
      manualIndex: this.normalizeIndex(parsed.manualIndex ?? parsed.index),
      manualSkin:
        typeof parsed.manualSkin === 'string'
          ? parsed.manualSkin
          : this.getSkin(parsed.manualIndex ?? parsed.index).id,
    };
    legacy.selectedBackground = this.getBackgroundPath(legacy.manualIndex, 'dusk');
    return {
      version: 2,
      dawn: this.createDefaultBranch('dawn'),
      dusk: {
        ...legacy,
        selectedBackground: this.getBackgroundPath(legacy.manualIndex, 'dusk'),
      },
      selectedLightBackground: null,
      selectedDarkBackground: legacy.mode === 'manual' ? legacy.manualSkin : null,
    };
  },

  normalizeStoredState(parsed) {
    if (!parsed || typeof parsed !== 'object') return null;

    if (parsed.dawn && parsed.dusk) {
      const dawn = { ...this.createDefaultBranch('dawn'), ...parsed.dawn };
      const dusk = { ...this.createDefaultBranch('dusk'), ...parsed.dusk };
      dawn.index = this.normalizeIndex(dawn.index);
      dusk.index = this.normalizeIndex(dusk.index);
      dawn.manualIndex = this.normalizeIndex(dawn.manualIndex ?? dawn.index);
      dusk.manualIndex = this.normalizeIndex(dusk.manualIndex ?? dusk.index);
      dawn.manualSkin = this.getSkin(dawn.manualIndex).id;
      dusk.manualSkin = this.getSkin(dusk.manualIndex).id;
      dawn.selectedBackground = this.getBackgroundPath(dawn.manualIndex, 'dawn');
      dusk.selectedBackground = this.getBackgroundPath(dusk.manualIndex, 'dusk');
      return {
        version: 2,
        dawn,
        dusk,
        selectedLightBackground:
          typeof parsed.selectedLightBackground === 'string'
            ? parsed.selectedLightBackground
            : parsed.selectedDawnBackground || null,
        selectedDarkBackground:
          typeof parsed.selectedDarkBackground === 'string'
            ? parsed.selectedDarkBackground
            : parsed.selectedDuskBackground || null,
      };
    }

    return this.migrateLegacyState(parsed);
  },

  readStoredState() {
    try {
      const raw = localStorage.getItem(this.STORAGE_KEY);
      if (!raw) return null;
      return this.normalizeStoredState(JSON.parse(raw));
    } catch (_) {
      return null;
    }
  },

  getBranchKey(theme) {
    return this.normalizeGameTheme(theme);
  },

  getBranchState(state, theme) {
    const key = this.getBranchKey(theme);
    return state?.[key] || this.createDefaultBranch(theme);
  },

  writeStoredState(state) {
    try {
      localStorage.setItem(this.STORAGE_KEY, JSON.stringify(state));
    } catch (_) {}
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

  resolveIndex(theme, options = {}) {
    const advanceOnNewDay = options.advanceOnNewDay !== false;
    const today = this.getTodayKey();
    const stored = this.readStoredState();
    const branch = this.getBranchState(stored, theme);

    if (!stored) {
      return this.getDailyIndex(theme);
    }

    if (branch.mode === 'manual') {
      return branch.manualIndex;
    }

    if (branch.lastDay === today) {
      return branch.index;
    }

    if (!advanceOnNewDay) {
      return branch.index;
    }

    return this.normalizeIndex(branch.index + 1);
  },

  getSelectedBackgroundForTheme(theme) {
    const stored = this.readStoredState();
    const branchKey = this.getBranchKey(theme);
    const branch = this.getBranchState(stored, theme);
    const selectedKey = branchKey === 'dawn' ? 'selectedLightBackground' : 'selectedDarkBackground';
    const selectedSkin = stored?.[selectedKey];

    if (branch.mode === 'manual') {
      const index = this.getSkinIndex(branch.manualSkin);
      return this.getBackgroundPath(index, theme);
    }

    if (typeof selectedSkin === 'string' && selectedSkin.startsWith('./assets/')) {
      return selectedSkin;
    }

    if (typeof selectedSkin === 'string') {
      const index = this.getSkinIndex(selectedSkin);
      return this.getBackgroundPath(index, theme);
    }

    const index = this.resolveIndex(theme, { advanceOnNewDay: false });
    return this.getBackgroundPath(index, theme);
  },

  getPreferenceValue(theme) {
    const gameTheme = this.normalizeGameTheme(theme ?? this._activeGameTheme);
    const stored = this.readStoredState();
    const branch = this.getBranchState(stored, gameTheme);
    if (branch.mode === 'manual') {
      return branch.manualSkin;
    }
    return 'auto';
  },

  setPreferenceValue(value, theme) {
    const gameTheme = this.normalizeGameTheme(theme ?? this._activeGameTheme);
    const preference = this.normalizePreference(value);
    const today = this.getTodayKey();
    const stored = this.readStoredState() || {
      version: 2,
      dawn: this.createDefaultBranch('dawn'),
      dusk: this.createDefaultBranch('dusk'),
      selectedLightBackground: null,
      selectedDarkBackground: null,
    };
    const branchKey = this.getBranchKey(gameTheme);
    const branch = { ...this.getBranchState(stored, gameTheme) };

    if (preference.mode === 'manual') {
      const index = preference.index;
      branch.mode = 'manual';
      branch.manualIndex = index;
      branch.manualSkin = this.getSkin(index).id;
      branch.index = index;
      branch.lastDay = today;
      branch.selectedBackground = this.getBackgroundPath(index, gameTheme);
      stored[branchKey] = branch;
      if (branchKey === 'dawn') {
        stored.selectedLightBackground = branch.manualSkin;
      } else {
        stored.selectedDarkBackground = branch.manualSkin;
      }
      this.writeStoredState(stored);
      if (gameTheme === this._activeGameTheme) {
        this.apply(index, gameTheme);
      }
      return index;
    }

    branch.mode = 'auto';
    const index =
      branch.lastDay === today
        ? branch.index
        : this.resolveIndex(gameTheme, { advanceOnNewDay: false });
    branch.index = index;
    branch.manualIndex = index;
    branch.manualSkin = this.getSkin(index).id;
    branch.lastDay = today;
    branch.selectedBackground = this.getBackgroundPath(index, gameTheme);
    stored[branchKey] = branch;
    if (branchKey === 'dawn') {
      stored.selectedLightBackground = null;
    } else {
      stored.selectedDarkBackground = null;
    }
    this.writeStoredState(stored);
    if (gameTheme === this._activeGameTheme) {
      this.apply(index, gameTheme);
    }
    return index;
  },

  applySkinDatasets(skin, theme) {
    const root = document.documentElement;
    root.dataset.visualSkin = skin.id;
    root.dataset.titleFrame = skin.titleFrame || 'none';
    root.dataset.quickRow = skin.quickRow || 'chips';
    root.dataset.primaryBtn = skin.primaryBtn || 'pill';
    root.dataset.backgroundTheme = this.getThemeKind(theme);
    delete root.dataset.skinArtwork;
    delete root.dataset.gameTheme;
  },

  applyBackgroundCss(backgroundPath) {
    const url = this.resolveImageUrl(backgroundPath);
    const cssValue = `url("${url}")`;

    try {
      document.documentElement.style.setProperty('--app-bg-image', cssValue);
      document.documentElement.style.setProperty('--menu-background-image', cssValue);
    } catch (_) {}

    const el = document.getElementById('appBackground');
    if (el) {
      el.style.backgroundImage = cssValue;
      delete el.dataset.skinArtwork;
    }
  },

  apply(index, theme) {
    const gameTheme = this.normalizeGameTheme(theme ?? this._activeGameTheme);
    const safe = this.normalizeIndex(index);
    const skin = this.getSkin(safe);
    const backgroundPath = this.getBackgroundPath(safe, gameTheme);

    this.applyBackgroundCss(backgroundPath);
    this.applySkinDatasets(skin, gameTheme);

    const el = document.getElementById('appBackground');
    if (el) {
      el.dataset.bgIndex = String(safe);
      el.dataset.visualSkin = skin.id;
      el.dataset.bgTheme = this.getThemeKind(gameTheme);
      el.dataset.bgDay = this.getTodayKey();
    }
  },

  syncForGameTheme(theme) {
    const gameTheme = this.normalizeGameTheme(theme);
    this._activeGameTheme = gameTheme;
    const index = this.resolveIndex(gameTheme, { advanceOnNewDay: false });
    this.apply(index, gameTheme);
    return index;
  },

  resolveImageUrl(path) {
    try {
      return new URL(path, document.baseURI).href;
    } catch (_) {
      return path;
    }
  },

  init(gameTheme) {
    const theme = this.normalizeGameTheme(gameTheme || this._activeGameTheme);
    this._activeGameTheme = theme;
    const today = this.getTodayKey();
    const stored = this.readStoredState();
    const index = this.resolveIndex(theme, { advanceOnNewDay: true });
    this.apply(index, theme);

    const next = stored || {
      version: 2,
      dawn: this.createDefaultBranch('dawn'),
      dusk: this.createDefaultBranch('dusk'),
      selectedLightBackground: null,
      selectedDarkBackground: null,
    };
    const branchKey = this.getBranchKey(theme);
    const branch = { ...this.getBranchState(next, theme) };
    branch.index = index;
    branch.lastDay = today;
    branch.manualIndex = branch.mode === 'manual' ? branch.manualIndex : index;
    branch.manualSkin = this.getSkin(branch.manualIndex).id;
    branch.selectedBackground = this.getBackgroundPath(index, theme);
    next[branchKey] = branch;
    this.writeStoredState(next);
    return index;
  },

  onMainMenuEnter(gameTheme) {
    const theme = this.normalizeGameTheme(gameTheme || this._activeGameTheme);
    this._activeGameTheme = theme;
    const today = this.getTodayKey();
    const stored = this.readStoredState();
    const branch = this.getBranchState(stored, theme);
    let index;

    if (!stored) {
      index = this.getDailyIndex(theme);
    } else if (branch.mode === 'manual') {
      index = branch.manualIndex;
    } else if (branch.lastDay === today) {
      index = branch.index;
    } else {
      index = this.normalizeIndex(branch.index + 1);
    }

    this.apply(index, theme);

    const next = stored || {
      version: 2,
      dawn: this.createDefaultBranch('dawn'),
      dusk: this.createDefaultBranch('dusk'),
      selectedLightBackground: null,
      selectedDarkBackground: null,
    };
    const branchKey = this.getBranchKey(theme);
    const updated = { ...this.getBranchState(next, theme) };
    updated.index = index;
    updated.lastDay = today;
    updated.selectedBackground = this.getBackgroundPath(index, theme);
    next[branchKey] = updated;
    this.writeStoredState(next);
    return index;
  },
};

if (typeof window !== 'undefined') {
  window.BackgroundRotator = BackgroundRotator;
}
