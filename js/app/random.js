// Random: LostNumberGame prototype methods.

LostNumberGame.prototype.initSeededRandom = function (forceNew = false) {
  try {
    const KEY = 'lostNumberSessionSeed';
    let seed = 0;

    if (!forceNew) {
      try {
        const saved = localStorage.getItem(KEY);
        if (saved && /^\d+$/.test(saved)) seed = parseInt(saved, 10) >>> 0;
      } catch (_) {}
    }

    if (!seed) {
      try {
        seed =
          typeof SeededRandom !== 'undefined' && SeededRandom.makeSessionSeed
            ? SeededRandom.makeSessionSeed()
            : (Date.now() & 0xffffffff) >>> 0;
      } catch (_) {
        seed = (Date.now() & 0xffffffff) >>> 0;
      }
      try {
        localStorage.setItem(KEY, String(seed >>> 0));
      } catch (_) {}
    }

    this.currentSeed = seed >>> 0;
    this.rng = new SeededRandom(this.currentSeed);

    // daily seed (локальная дата, одинаковая для всех сегодня)
    try {
      const d = new Date();
      const yyyy = d.getFullYear();
      const mm = String(d.getMonth() + 1).padStart(2, '0');
      const dd = String(d.getDate()).padStart(2, '0');
      const dailyKey = `${yyyy}-${mm}-${dd}|daily|lostnumber-v1`;
      this.dailySeed =
        typeof SeededRandom !== 'undefined' && SeededRandom.hashToSeed
          ? SeededRandom.hashToSeed(dailyKey)
          : this.currentSeed ^ 0x9e3779b9;
      this.dailyRng = new SeededRandom(this.dailySeed);
    } catch (_) {
      this.dailySeed = (this.currentSeed ^ 0x9e3779b9) >>> 0;
      this.dailyRng = new SeededRandom(this.dailySeed);
    }

    // пробрасываем в state (его используют grid/wheel)
    try {
      if (this.state) {
        this.state.rng = this.rng;
        this.state.currentSeed = this.currentSeed;
      }
    } catch (_) {}
  } catch (error) {
    ErrorHandler.handle(error, { type: 'rng_init', forceNew });
    // Fallback на Math.random если SeededRandom сломался
    this.rng = {
      nextFloat: () => Math.random(),
      nextInt: (max) => Math.floor(Math.random() * max),
    };
  }
};

// Facade RNG: единая точка входа для gameplay-кода.
// Не читать state.rng напрямую — использовать только этот метод.
LostNumberGame.prototype.nextRandomInt = function (maxExclusive) {
  const max = Math.max(1, maxExclusive | 0);
  try {
    if (this.rng && typeof this.rng.nextInt === 'function') {
      return this.rng.nextInt(max);
    }
  } catch (error) {
    ErrorHandler.warn('nextRandomInt failed', { error, maxExclusive });
  }
  return Math.floor(Math.random() * max);
};

LostNumberGame.prototype.nextRandomFloat = function () {
  try {
    if (this.rng && typeof this.rng.nextFloat === 'function') {
      return this.rng.nextFloat();
    }
  } catch (error) {
    ErrorHandler.warn('nextRandomFloat failed', { error });
  }
  return Math.random();
};

LostNumberGame.prototype.resetSeed = function () {
  try {
    localStorage.removeItem('lostNumberSessionSeed');
    this.initSeededRandom(true);
    this.showMessage?.(`Seed: ${this.currentSeed}`);
    if (this.debugOverlay && this.debugOverlay.update) this.debugOverlay.update();
  } catch (error) {
    ErrorHandler.handle(error, { type: 'debug_resetSeed' });
  }
};
