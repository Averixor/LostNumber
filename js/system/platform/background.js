/**
 * Rotating app backgrounds: 3 images, auto-advance when the calendar day changes
 * (on main menu enter). State in localStorage key lostNumberBackground.
 */
const BackgroundRotator = {
  STORAGE_KEY: 'lostNumberBackground',
  IMAGES: [
    './assets/images/background.png',
    './assets/images/background-alt.png',
    './assets/images/background-alt2.png',
  ],
  DAY_MS: 24 * 60 * 60 * 1000,

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
    const len = this.IMAGES.length;
    if (!len) return 0;
    const n = Number(index);
    if (!Number.isFinite(n)) return 0;
    return ((n % len) + len) % len;
  },

  readStoredState() {
    try {
      const raw = localStorage.getItem(this.STORAGE_KEY);
      if (!raw) return null;
      const parsed = JSON.parse(raw);
      if (!parsed || typeof parsed !== 'object') return null;
      return {
        index: this.normalizeIndex(parsed.index),
        lastDay: typeof parsed.lastDay === 'string' ? parsed.lastDay : null,
      };
    } catch (_) {
      return null;
    }
  },

  writeStoredState(index, day) {
    try {
      localStorage.setItem(
        this.STORAGE_KEY,
        JSON.stringify({
          index: this.normalizeIndex(index),
          lastDay: day,
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

    if (stored.lastDay === today) {
      return stored.index;
    }

    if (!advanceOnNewDay) {
      return stored.index;
    }

    return this.normalizeIndex(stored.index + 1);
  },

  apply(index) {
    const safe = this.normalizeIndex(index);
    const url = this.resolveImageUrl(this.IMAGES[safe]);
    const cssValue = `url("${url}")`;

    try {
      document.documentElement.style.setProperty('--app-bg-image', cssValue);
    } catch (_) {}

    const el = document.getElementById('appBackground');
    if (el) {
      el.style.backgroundImage = cssValue;
      el.dataset.bgIndex = String(safe);
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
    const index = this.resolveIndex({ advanceOnNewDay: true });
    this.apply(index);
    this.writeStoredState(index, today);
    return index;
  },

  /** Each main-menu visit: rotate when the calendar day changed since last stored day. */
  onMainMenuEnter() {
    const today = this.getTodayKey();
    const stored = this.readStoredState();
    let index;

    if (!stored) {
      index = this.getDailyIndex();
    } else if (stored.lastDay === today) {
      index = stored.index;
    } else {
      index = this.normalizeIndex(stored.index + 1);
    }

    this.apply(index);
    this.writeStoredState(index, today);
    return index;
  },
};

if (typeof window !== 'undefined') {
  window.BackgroundRotator = BackgroundRotator;
}
