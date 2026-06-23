/**
 * Alternating app backgrounds: one deterministic background per local calendar day.
 */
const BackgroundRotator = {
  IMAGES: ['./assets/images/background.png', './assets/images/background-alt.png'],
  DAY_MS: 24 * 60 * 60 * 1000,

  getTodayKey() {
    const d = new Date();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${d.getFullYear()}-${m}-${day}`;
  },

  getDailyIndex() {
    const d = new Date();
    const dayNumber = Math.floor(
      Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()) / this.DAY_MS,
    );
    return dayNumber % this.IMAGES.length;
  },

  apply(index) {
    const safe = index === 1 ? 1 : 0;
    const url = this.IMAGES[safe];
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

  init() {
    const index = this.getDailyIndex();
    this.apply(index);
    return index;
  },

  onMainMenuEnter() {
    return this.init();
  },
};

if (typeof window !== 'undefined') {
  window.BackgroundRotator = BackgroundRotator;
}
