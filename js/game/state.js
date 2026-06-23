// @ts-check

class GameState {
  constructor() {
    try {
      this.GRID_W = 5;
      this.GRID_H = 8;
      this.MAX_DAILY_SPINS = 20;

      this.MANUAL_LEVEL_COUNT = 40;
      /** @type {LevelConfig[]} */
      this.levels = this.generateLevels(this.MANUAL_LEVEL_COUNT);
      this.MAX_LEVEL = this.levels.length;

      this.currentLevel = 0;
      this.xp = 0;
      this.xpMultiplier = 1;
      this.xpMultiplierTurns = 0;

      this.maxReachedNumber = 8;
      this.carryNumber = null;

      /** @type {LostNumberCell[][]} */
      this.grid = [];
      /** @type {GridPoint[]} */
      this.selected = [];
      this.isDragging = false;
      /** @type {BonusType | null} */
      this.activeBonus = null;

      /** @type {BonusInventory} */
      this.bonusInventory = {
        destroy: 0,
        shuffle: 0,
        explosion: 0,
      };

      /** @type {Map<number, unknown>} */
      this.frozenCells = new Map();
      this.stats = this.defaultStats();
      this.achievements = this.defaultAchievements();

      /** @type {PendingTransition | null} */
      this.pendingTransition = null;
      this.hasSave = false;

      this.wheelSpinsToday = 0;
      this.lastWheelDay = this.getTodayKey();

      this.animationEnabled = true;
      this.lang = 'ua';
      this.soundEnabled = true;
      this.musicEnabled = true;
      this.sfxVolume = 0.5;
      this.musicVolume = 0.3;
      this.musicTrack = 'ambient';
      this.theme = 'dusk';
      this.liteVisualMode = 'auto';

      this.sessionSeed = 0;
      this.dailySeed = 0;
      this.currentSeed = 0;
      this.rng = null;

      this.screenState = 'mainMenu';
      this.gamePhase = 'idle';

      this.core = new GameCore(this);

      /** @type {unknown} */
      this.dailyQuests = null;

      ErrorHandler.info('GameState initialized', {
        levels: this.levels.length,
        gridSize: `${this.GRID_W}x${this.GRID_H}`,
      });
    } catch (error) {
      ErrorHandler.handle(error, { type: 'state_constructor' });
      this.setDefaults();
    }
  }

  setDefaults() {
    this.GRID_W = 5;
    this.GRID_H = 8;
    this.currentLevel = 0;
    this.xp = 0;
    /** @type {LostNumberCell[][]} */
    this.grid = [];
    this.bonusInventory = { destroy: 0, shuffle: 0, explosion: 0 };
    this.frozenCells = new Map();
    this.stats = this.defaultStats();
    this.achievements = this.defaultAchievements();
    this.liteVisualMode = 'auto';
  }

  /**
   * @param {number} count
   * @returns {LevelConfig[]}
   */
  generateLevels(count) {
    try {
      const levels = [];
      let target = 64;
      const baseNumbers = [2, 4, 8];

      for (let i = 0; i < count; i++) {
        const numbers = [...baseNumbers];
        const newNumbers = this.generateNewNumbers(target);

        levels.push({ target, numbers, newNumbers });

        target *= 2;

        if (i % 3 === 2 && baseNumbers.length < 7) {
          baseNumbers.push(baseNumbers[baseNumbers.length - 1] * 2);
        }
      }

      return levels;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'levels_generation', count });
      return [
        { target: 64, numbers: [2, 4, 8], newNumbers: [8, 16, 32] },
        { target: 128, numbers: [2, 4, 8, 16], newNumbers: [16, 32, 64] },
      ];
    }
  }

  /**
   * @param {number} target
   * @returns {number[]}
   */
  generateNewNumbers(target) {
    try {
      const arr = [];
      let num = target / 8;
      for (let i = 0; i < 8; i++) {
        if (num <= target) {
          arr.unshift(num);
          num *= 2;
        }
      }
      return arr;
    } catch (error) {
      ErrorHandler.warn('generateNewNumbers failed', { target, error });
      return [target / 4, target / 2, target];
    }
  }

  /**
   * @param {number} levelIndex
   * @returns {number}
   */
  getProceduralTarget(levelIndex) {
    const idx = Math.max(0, Math.floor(Number(levelIndex) || 0));
    const manualMax = this.MANUAL_LEVEL_COUNT || this.levels?.length || 40;

    if (idx < manualMax && this.levels[idx] && Number.isFinite(this.levels[idx].target)) {
      return this.levels[idx].target;
    }

    const MAX_SAFE_POWER_OF_TWO = 2 ** 52;
    const doubled = 64 * 2 ** idx;
    if (Number.isSafeInteger(doubled) && doubled >= 64 && doubled <= MAX_SAFE_POWER_OF_TWO) {
      return Math.floor(doubled);
    }

    return MAX_SAFE_POWER_OF_TWO;
  }

  /**
   * @param {number} levelIndex
   * @param {number} target
   * @returns {number[]}
   */
  buildLevelNumbers(levelIndex, target) {
    const idx = Math.max(0, Math.floor(Number(levelIndex) || 0));
    const baseNumbers = [2, 4, 8];
    let n = 8;
    const maxLen = Math.min(7, Math.floor(idx / 3) + 1);

    while (baseNumbers.length < maxLen) {
      n *= 2;
      if (!Number.isFinite(n) || n > target) {
        break;
      }
      baseNumbers.push(n);
    }

    return baseNumbers;
  }

  /**
   * @param {number} levelIndex
   * @returns {LevelConfig}
   */
  generateProceduralLevel(levelIndex) {
    const idx = Math.max(0, Math.floor(Number(levelIndex) || 0));
    const manualMax = this.MANUAL_LEVEL_COUNT || this.levels?.length || 40;

    if (idx < manualMax && this.levels[idx]) {
      return {
        target: this.levels[idx].target,
        numbers: this.levels[idx].numbers?.slice() || [2, 4, 8],
        newNumbers:
          this.levels[idx].newNumbers?.slice() || this.generateNewNumbers(this.levels[idx].target),
      };
    }

    const target = this.getProceduralTarget(idx);
    const safeTarget =
      Number.isFinite(target) && target > 0 ? target : this.levels[0]?.target || 64;

    return {
      target: safeTarget,
      numbers: this.buildLevelNumbers(idx, safeTarget),
      newNumbers: this.generateNewNumbers(safeTarget),
    };
  }

  /**
   * @param {number} levelIndex
   * @returns {LevelConfig}
   */
  getLevelConfig(levelIndex) {
    try {
      const idx = Math.max(0, Math.floor(Number(levelIndex) || 0));
      const config = this.generateProceduralLevel(idx);
      const target = Number(config.target);

      if (!Number.isFinite(target) || target <= 0) {
        const fallback = this.levels[0]?.target || 64;
        return {
          target: fallback,
          numbers: this.levels[0]?.numbers?.slice() || [2, 4, 8],
          newNumbers: this.generateNewNumbers(fallback),
        };
      }

      return {
        target,
        numbers: Array.isArray(config.numbers) ? config.numbers : [2, 4, 8],
        newNumbers: Array.isArray(config.newNumbers)
          ? config.newNumbers
          : this.generateNewNumbers(target),
      };
    } catch (error) {
      ErrorHandler.warn('getLevelConfig failed', { levelIndex, error });
      return { target: 64, numbers: [2, 4, 8], newNumbers: [8, 16, 32] };
    }
  }

  defaultStats() {
    try {
      return {
        gamesPlayed: 0,
        levelsCompleted: 0,
        highestLevel: 0,
        totalXP: 0,
        totalMerges: 0,
        longestChain: 0,
        bonusesUsed: 0,
        wheelSpins: 0,
      };
    } catch (error) {
      ErrorHandler.warn('defaultStats failed', error);
      return {
        gamesPlayed: 0,
        levelsCompleted: 0,
        highestLevel: 0,
        totalXP: 0,
        totalMerges: 0,
        longestChain: 0,
        bonusesUsed: 0,
        wheelSpins: 0,
      };
    }
  }

  defaultAchievements() {
    try {
      return {
        firstGame: { unlocked: false, progress: 0, max: 1 },
        level10: { unlocked: false, progress: 0, max: 10 },
        level25: { unlocked: false, progress: 0, max: 25 },
        xp1000: { unlocked: false, progress: 0, max: 1000 },
        xp5000: { unlocked: false, progress: 0, max: 5000 },
        chain5: { unlocked: false, progress: 0, max: 5 },
        chain10: { unlocked: false, progress: 0, max: 10 },
        useAllBonuses: { unlocked: false, progress: 0, max: 3 },
        spinWheel: { unlocked: false, progress: 0, max: 1 },
        spinWheel10: { unlocked: false, progress: 0, max: 10 },
      };
    } catch (error) {
      ErrorHandler.warn('defaultAchievements failed', error);
      return {
        firstGame: { unlocked: false, progress: 0, max: 1 },
      };
    }
  }

  getTodayKey() {
    try {
      const d = new Date();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      return `${d.getFullYear()}-${month}-${day}`;
    } catch (error) {
      ErrorHandler.warn('getTodayKey failed', error);
      return '1970-01-01';
    }
  }

  setGamePhase(phase) {
    try {
      this.gamePhase = phase;

      if (phase === 'playing') this.gameState = 'playing';
      else if (phase === 'win') this.gameState = 'win';
      else if (phase === 'transitioning') this.gameState = 'transition';
      else if (phase === 'menu') this.gameState = 'menu';
      else this.gameState = 'blocked';

      ErrorHandler.debug('Game phase changed', { phase, gameState: this.gameState });
    } catch (error) {
      ErrorHandler.handle(error, { type: 'set_game_phase', phase });
    }
  }

  resetRuntimeState() {
    try {
      this.isDragging = false;
      this.activeBonus = null;
      this.selected = [];
      Chain.numbers = [];
      Chain.sum = 0;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'reset_runtime_state' });
    }
  }

  _floorPowerOfTwo(n) {
    const v = Number(n);
    if (!Number.isFinite(v) || v < 2) {
      return 2;
    }
    const exp = Math.floor(Math.log2(v));
    const p = Math.pow(2, Math.max(0, exp));
    return Number.isFinite(p) && p >= 2 ? p : 2;
  }

  getMinimumTileForLevel(levelIndex, target) {
    const idx = Math.max(0, Math.floor(Number(levelIndex) || 0));
    const humanLevel = idx + 1;
    let raw = 2;

    if (humanLevel <= 6) {
      raw = 2;
    } else if (humanLevel <= 11) {
      raw = 4;
    } else if (humanLevel <= 15) {
      raw = 8;
    } else {
      const bracket = Math.floor((humanLevel - 16) / 4);
      const exponent = Math.min(4 + bracket, 52);
      const stepped = Math.pow(2, exponent);
      raw = Number.isFinite(stepped) && stepped >= 16 ? stepped : 16;
    }

    const safeTarget =
      target != null && Number.isFinite(Number(target)) && Number(target) > 0
        ? Number(target)
        : this.getLevelConfig(idx).target;

    return this._capMinimumTileToTarget(raw, safeTarget);
  }

  _capMinimumTileToTarget(rawMin, target) {
    let minTile = this._floorPowerOfTwo(rawMin);
    if (!Number.isFinite(target) || target <= 4096) {
      return minTile;
    }

    const capValue = target / 4096;
    const capTile = this._floorPowerOfTwo(capValue);
    if (capTile < minTile) {
      minTile = capTile;
    }
    if (!Number.isFinite(minTile) || minTile < 2) {
      return 2;
    }
    if (minTile > Number.MAX_SAFE_INTEGER) {
      return this._floorPowerOfTwo(Number.MAX_SAFE_INTEGER);
    }
    return minTile;
  }

  getMinimumSpawnTile(levelIndex) {
    const idx = Math.max(0, Math.floor(Number(levelIndex) || 0));
    const target = this.getLevelConfig(idx).target;
    return this.getMinimumTileForLevel(idx, target);
  }

  getAllowedNumbers() {
    try {
      const WINDOW = 9;
      const levelIndex = Math.max(0, Math.floor(Number(this.currentLevel) || 0));
      const minSpawn = this.getMinimumSpawnTile(levelIndex);
      const max = Math.max(this.maxReachedNumber, minSpawn);

      const arr = [];
      let num = max;

      while (arr.length < WINDOW && num >= minSpawn) {
        arr.unshift(num);
        num /= 2;
      }

      while (arr.length > 0 && arr[0] < minSpawn) {
        arr.shift();
      }

      if (arr.length === 0 || arr[0] > minSpawn) {
        arr.unshift(minSpawn);
      }

      if (arr.length < WINDOW) {
        let current = arr.length ? arr[arr.length - 1] : minSpawn;
        while (arr.length < WINDOW) {
          current *= 2;
          if (!Number.isFinite(current)) {
            break;
          }
          arr.push(current);
        }
      }

      return arr.filter((n) => Number.isFinite(n) && n >= 2);
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'get_allowed_numbers',
        maxReachedNumber: this.maxReachedNumber,
      });
      return [2, 4, 8, 16, 32, 64, 128, 256, 512];
    }
  }

  generateCellNumber() {
    try {
      const allowed = this.getAllowedNumbers();
      const levelTarget = this.getLevelConfig(this.currentLevel).target;

      const minSpawn = this.getMinimumSpawnTile(this.currentLevel);
      const filtered = allowed.filter(
        (n) => n >= minSpawn && n !== this.carryNumber && n !== levelTarget,
      );

      if (filtered.length === 0) {
        return minSpawn;
      }

      const items = filtered.map((value, index) => ({
        value,
        weight: 1 / 2 ** index,
      }));

      return this.pickWeighted(items).value;
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'generate_cell_number',
        allowed: this.getAllowedNumbers(),
        carryNumber: this.carryNumber,
        levelTarget: this.getLevelConfig(this.currentLevel).target,
      });
      return 2;
    }
  }

  _nextRandomFloat() {
    try {
      if (this.rng && typeof this.rng.nextFloat === 'function') {
        return this.rng.nextFloat();
      }
    } catch (error) {
      ErrorHandler.warn('GameState._nextRandomFloat failed', { error });
    }
    return Math.random();
  }

  pickWeighted(items) {
    const fallbackItem = () =>
      items && items.length > 0 && items[0] && typeof items[0] === 'object' && 'value' in items[0]
        ? items[0]
        : { value: 2, weight: 1 };

    try {
      if (!items || !Array.isArray(items) || items.length === 0) {
        return { value: 2, weight: 1 };
      }

      let total = 0;
      for (const it of items) {
        const w = Number(it?.weight);
        if (Number.isFinite(w) && w > 0) total += w;
      }

      if (total <= 0) {
        return fallbackItem();
      }

      let r = this._nextRandomFloat() * total;
      for (const it of items) {
        const w = Number(it?.weight);
        if (!Number.isFinite(w) || w <= 0) continue;
        r -= w;
        if (r <= 0) return it;
      }

      for (let i = items.length - 1; i >= 0; i--) {
        const it = items[i];
        const w = Number(it?.weight);
        if (Number.isFinite(w) && w > 0) return it;
      }

      return fallbackItem();
    } catch (error) {
      ErrorHandler.handle(error, { type: 'pick_weighted', items });
      try {
        return fallbackItem();
      } catch {
        return { value: 2, weight: 1 };
      }
    }
  }

  formatNumber(num) {
    try {
      if (!Number.isFinite(num)) return '∞';
      if (num <= 0) return '0';

      if (num < 1000) {
        const lang = this.lang === 'ua' ? 'uk' : this.lang;
        return num.toLocaleString(lang);
      }

      const baseSuffixes = ['K', 'M', 'B', 'T', 'Qa', 'Qi', 'Sx', 'Sp', 'Oc', 'No', 'Dc'];

      const tier = Math.floor(Math.log10(num) / 3);

      let suffix;
      if (tier - 1 < baseSuffixes.length) {
        suffix = baseSuffixes[tier - 1];
      } else {
        suffix = this.generateAASuffix(tier - baseSuffixes.length);
      }

      const scaled = num / 10 ** (tier * 3);

      let formatted;
      if (scaled < 10) {
        formatted = scaled.toFixed(2);
      } else if (scaled < 100) {
        formatted = scaled.toFixed(1);
      } else {
        formatted = Math.floor(scaled).toString();
      }

      formatted = formatted.replace(/\.0+$|(\.\d*[1-9])0+$/, '$1');

      return formatted + suffix;
    } catch (error) {
      ErrorHandler.warn('formatNumber failed', { num, error });
      return String(num);
    }
  }

  generateAASuffix(index) {
    try {
      let result = '';
      index++;

      while (index > 0) {
        index--;
        result = String.fromCharCode(97 + (index % 26)) + result;
        index = Math.floor(index / 26);
      }

      return result;
    } catch (error) {
      ErrorHandler.warn('generateAASuffix failed', { index, error });
      return 'X';
    }
  }

  getWheelCost() {
    try {
      const BASE = 25;
      const FREE = 5;
      const STEP = 10;
      const spins = this.wheelSpinsToday || 0;
      return spins < FREE ? BASE : BASE + (spins - FREE) * STEP;
    } catch (error) {
      ErrorHandler.warn('getWheelCost failed', { wheelSpinsToday: this.wheelSpinsToday, error });
      return 25;
    }
  }

  checkWheelDailyReset() {
    try {
      const today = this.getTodayKey();
      if (this.lastWheelDay !== today) {
        this.lastWheelDay = today;
        this.wheelSpinsToday = 0;
        ErrorHandler.info('Wheel daily reset', { today });
      }
    } catch (error) {
      ErrorHandler.handle(error, { type: 'wheel_daily_reset' });
    }
  }

  baseXPByLen(len) {
    try {
      return Rules.baseXPByLen(len);
    } catch (error) {
      ErrorHandler.warn('baseXPByLen failed', { len, error });
      return len * 2;
    }
  }

  levelXPMult() {
    try {
      return 1 + (this.currentLevel + 1) * 0.06;
    } catch (error) {
      ErrorHandler.warn('levelXPMult failed', { currentLevel: this.currentLevel, error });
      return 1;
    }
  }

  calculateXP(len) {
    try {
      const base = this.baseXPByLen(len);
      let xp = Math.max(0, Math.round(base * this.levelXPMult()));
      if (this.xpMultiplier > 1 && this.xpMultiplierTurns > 0) {
        xp = Math.round(xp * this.xpMultiplier);
      }

      return xp;
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'calculate_xp',
        len,
        base: this.baseXPByLen(len),
        multiplier: this.xpMultiplier,
        turns: this.xpMultiplierTurns,
      });
      return len * 2;
    }
  }

  updateDailyQuests(dailyQuests) {
    try {
      this.dailyQuests = dailyQuests;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'update_daily_quests', dailyQuests });
    }
  }

  validateState() {
    try {
      const issues = [];

      if (this.currentLevel < 0 || !Number.isFinite(this.currentLevel)) {
        issues.push(`Invalid current level: ${this.currentLevel}`);
      }

      if (this.xp < 0) {
        issues.push(`Negative XP: ${this.xp}`);
      }

      if (!this.grid || !Array.isArray(this.grid)) {
        issues.push('Grid not initialized');
      } else if (this.grid.length !== this.GRID_W) {
        issues.push(`Grid width mismatch: expected ${this.GRID_W}, got ${this.grid.length}`);
      }

      if (!this.bonusInventory || typeof this.bonusInventory !== 'object') {
        issues.push('Bonus inventory corrupted');
      } else {
        const requiredBonuses = ['destroy', 'shuffle', 'explosion'];
        for (const bonus of requiredBonuses) {
          if (typeof this.bonusInventory[bonus] !== 'number' || this.bonusInventory[bonus] < 0) {
            issues.push(`Invalid bonus count for ${bonus}: ${this.bonusInventory[bonus]}`);
          }
        }
      }

      if (issues.length > 0) {
        ErrorHandler.warn('State validation failed', {
          type: 'state_validation',
          issues,
          currentLevel: this.currentLevel,
          xp: this.xp,
          gridSize: this.grid ? `${this.grid.length}x${this.grid[0]?.length}` : 'none',
        });
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'state_validation_error' });
      return false;
    }
  }

  repairState() {
    try {
      ErrorHandler.info('Attempting to repair game state');

      let repaired = false;

      if (this.currentLevel < 0) {
        this.currentLevel = 0;
        repaired = true;
      } else if (!Number.isFinite(this.currentLevel)) {
        this.currentLevel = 0;
        repaired = true;
      }

      if (this.xp < 0) {
        this.xp = 0;
        repaired = true;
      }

      if (!this.bonusInventory || typeof this.bonusInventory !== 'object') {
        this.bonusInventory = { destroy: 0, shuffle: 0, explosion: 0 };
        repaired = true;
      } else {
        const defaultBonuses = { destroy: 0, shuffle: 0, explosion: 0 };
        for (const key in defaultBonuses) {
          if (typeof this.bonusInventory[key] !== 'number' || this.bonusInventory[key] < 0) {
            this.bonusInventory[key] = defaultBonuses[key];
            repaired = true;
          }
        }
      }

      if (!this.stats || typeof this.stats !== 'object') {
        this.stats = this.defaultStats();
        repaired = true;
      } else {
        const defaultStats = this.defaultStats();
        for (const key of Object.keys(defaultStats)) {
          const v = this.stats[key];
          if (typeof v !== 'number' || !Number.isFinite(v) || v < 0) {
            this.stats[key] = defaultStats[key];
            repaired = true;
          }
        }
      }

      if (!this.achievements || typeof this.achievements !== 'object') {
        this.achievements = this.defaultAchievements();
        repaired = true;
      } else {
        const defaultAchievements = this.defaultAchievements();
        for (const key of Object.keys(defaultAchievements)) {
          const cur = this.achievements[key];
          const tmpl = defaultAchievements[key];
          if (!cur || typeof cur !== 'object') {
            this.achievements[key] = { ...tmpl };
            repaired = true;
            continue;
          }
          if (typeof cur.unlocked !== 'boolean') {
            cur.unlocked = !!tmpl.unlocked;
            repaired = true;
          }
          if (
            typeof cur.progress !== 'number' ||
            !Number.isFinite(cur.progress) ||
            cur.progress < 0
          ) {
            cur.progress = tmpl.progress;
            repaired = true;
          }
          if (typeof cur.max !== 'number' || !Number.isFinite(cur.max) || cur.max <= 0) {
            cur.max = tmpl.max;
            repaired = true;
          }
        }
      }

      if (repaired) {
        ErrorHandler.info('Game state repaired', {
          currentLevel: this.currentLevel,
          xp: this.xp,
          bonusInventory: this.bonusInventory,
        });
      }

      return repaired;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'state_repair_failed' });
      return false;
    }
  }
}
