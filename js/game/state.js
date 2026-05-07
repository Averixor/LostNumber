class GameState {
  constructor() {
    try {
      this.GRID_W = 5;
      this.GRID_H = 8;
      this.MAX_DAILY_SPINS = 20;

      this.levels = this.generateLevels(40);
      this.MAX_LEVEL = this.levels.length;

      this.currentLevel = 0;
      this.xp = 0;
      this.xpMultiplier = 1;
      this.xpMultiplierTurns = 0;

      this.maxReachedNumber = 8;
      this.carryNumber = null;

      this.grid = [];
      this.selected = [];
      this.isDragging = false;
      this.activeBonus = null;

      this.bonusInventory = {
        destroy: 0,
        shuffle: 0,
        explosion: 0,
      };

      this.frozenCells = new Map();
      this.stats = this.defaultStats();
      this.achievements = this.defaultAchievements();

      this.pendingTransition = null;
      this.hasSave = false;

      this.wheelSpinsToday = 0;
      this.lastWheelDay = this.getTodayKey();

      this.animationEnabled = true;
      this.lang = 'ua';
      this.soundEnabled = true;
      this.theme = 'dusk';

      // Seeded RNG (инициализируется в main.js)
      this.sessionSeed = 0;
      this.dailySeed = 0;
      this.currentSeed = 0;
      this.rng = null;

      this.screenState = 'mainMenu';
      this.gamePhase = 'idle';
      this.setGamePhase('playing');

      this.core = new GameCore(this);

      this.dailyQuests = null;

      ErrorHandler.info('GameState initialized', {
        levels: this.levels.length,
        gridSize: `${this.GRID_W}x${this.GRID_H}`,
      });
    } catch (error) {
      ErrorHandler.handle(error, { type: 'state_constructor' });
      // Устанавливаем значения по умолчанию при ошибке
      this.setDefaults();
    }
  }

  setDefaults() {
    // Значения по умолчанию на случай ошибки инициализации
    this.GRID_W = 5;
    this.GRID_H = 8;
    this.currentLevel = 0;
    this.xp = 0;
    this.grid = [];
    this.bonusInventory = { destroy: 0, shuffle: 0, explosion: 0 };
    this.frozenCells = new Map();
    this.stats = this.defaultStats();
    this.achievements = this.defaultAchievements();
  }

  generateLevels(count) {
    try {
      const levels = [];
      let target = 64;
      let baseNumbers = [2, 4, 8];

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
      // Возвращаем минимальный набор уровней при ошибке
      return [
        { target: 64, numbers: [2, 4, 8], newNumbers: [8, 16, 32] },
        { target: 128, numbers: [2, 4, 8, 16], newNumbers: [16, 32, 64] },
      ];
    }
  }

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
        useAllBonuses: { unlocked: false, progress: 0, max: 5 },
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
      return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
    } catch (error) {
      ErrorHandler.warn('getTodayKey failed', error);
      return '1970-01-01'; // Fallback дата
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

  getAllowedNumbers() {
    try {
      const WINDOW = 9;
      const max = this.maxReachedNumber;

      let arr = [];
      let num = max;

      while (arr.length < WINDOW && num >= 2) {
        arr.unshift(num);
        num /= 2;
      }

      if (arr.length < WINDOW) {
        let current = max;
        while (arr.length < WINDOW) {
          current *= 2;
          arr.push(current);
        }
      }

      return arr;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'get_allowed_numbers', maxReachedNumber: this.maxReachedNumber });
      return [2, 4, 8, 16, 32, 64, 128, 256, 512]; // Fallback значения
    }
  }

  generateCellNumber() {
    try {
      const allowed = this.getAllowedNumbers();
      const levelTarget = this.levels?.[this.currentLevel]?.target;

      const filtered = allowed.filter((n) => n !== this.carryNumber && n !== levelTarget);

      if (filtered.length === 0) {
        // Если нет доступных чисел, вернем минимальное
        return 2;
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
        levelTarget: this.levels?.[this.currentLevel]?.target,
      });
      return 2; // Fallback значение
    }
  }

  pickWeighted(items) {
    try {
      let total = 0;
      for (const it of items) total += it.weight;

      let r = (this.rng ? this.rng.nextFloat() : Math.random()) * total;
      for (const it of items) {
        r -= it.weight;
        if (r <= 0) return it;
      }
      return items[items.length - 1];
    } catch (error) {
      ErrorHandler.handle(error, { type: 'pick_weighted', items });
      // Возвращаем первый элемент при ошибке
      return items && items.length > 0 ? items[0] : { value: 2, weight: 1 };
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
      return String(num); // Просто строковое представление при ошибке
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
      return 'X'; // Простой суффикс при ошибке
    }
  }

  getWheelCost() {
    try {
      const BASE = 25;
      const FREE = 5;
      const STEP = 15;

      if (this.wheelSpinsToday < FREE) return BASE;
      return BASE + (this.wheelSpinsToday - FREE) * STEP;
    } catch (error) {
      ErrorHandler.warn('getWheelCost failed', { wheelSpinsToday: this.wheelSpinsToday, error });
      return BASE;
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
      return len * 2; // Простая формула при ошибке
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
        this.xpMultiplierTurns--;
        if (this.xpMultiplierTurns <= 0) {
          this.xpMultiplier = 1;
        }
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
      return len * 2; // Простая формула при ошибке
    }
  }

  updateDailyQuests(dailyQuests) {
    try {
      this.dailyQuests = dailyQuests;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'update_daily_quests', dailyQuests });
    }
  }

  // === НОВЫЕ МЕТОДЫ ДЛЯ ОБРАБОТКИ ОШИБОК ===

  // Валидация состояния
  validateState() {
    try {
      const issues = [];

      // Проверка текущего уровня
      if (this.currentLevel < 0 || this.currentLevel >= this.MAX_LEVEL) {
        issues.push(`Invalid current level: ${this.currentLevel}`);
      }

      // Проверка XP
      if (this.xp < 0) {
        issues.push(`Negative XP: ${this.xp}`);
      }

      // Проверка сетки
      if (!this.grid || !Array.isArray(this.grid)) {
        issues.push('Grid not initialized');
      } else if (this.grid.length !== this.GRID_W) {
        issues.push(`Grid width mismatch: expected ${this.GRID_W}, got ${this.grid.length}`);
      }

      // Проверка инвентаря бонусов
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

  // Исправление состояния
  repairState() {
    try {
      ErrorHandler.info('Attempting to repair game state');

      let repaired = false;

      // Исправляем текущий уровень
      if (this.currentLevel < 0) {
        this.currentLevel = 0;
        repaired = true;
      } else if (this.currentLevel >= this.MAX_LEVEL) {
        this.currentLevel = this.MAX_LEVEL - 1;
        repaired = true;
      }

      // Исправляем XP
      if (this.xp < 0) {
        this.xp = 0;
        repaired = true;
      }

      // Исправляем инвентарь бонусов
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

      // Исправляем статистику
      if (!this.stats || typeof this.stats !== 'object') {
        this.stats = this.defaultStats();
        repaired = true;
      }

      // Исправляем достижения
      if (!this.achievements || typeof this.achievements !== 'object') {
        this.achievements = this.defaultAchievements();
        repaired = true;
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

  // Создание резервной копии состояния
  createBackup() {
    try {
      const backup = {
        timestamp: Date.now(),
        currentLevel: this.currentLevel,
        xp: this.xp,
        xpMultiplier: this.xpMultiplier,
        xpMultiplierTurns: this.xpMultiplierTurns,
        maxReachedNumber: this.maxReachedNumber,
        carryNumber: this.carryNumber,
        bonusInventory: { ...this.bonusInventory },
        stats: { ...this.stats },
        achievements: JSON.parse(JSON.stringify(this.achievements)),
        wheelSpinsToday: this.wheelSpinsToday,
        lastWheelDay: this.lastWheelDay,
      };

      // Сохраняем сетку (только числа)
      if (this.grid && Array.isArray(this.grid)) {
        backup.grid = [];
        for (let x = 0; x < this.GRID_W; x++) {
          backup.grid[x] = [];
          for (let y = 0; y < this.GRID_H; y++) {
            backup.grid[x][y] = this.grid[x][y]?.number || null;
          }
        }
      }

      // Сохраняем замороженные клетки
      if (this.frozenCells && this.frozenCells.size > 0) {
        backup.frozenCells = Object.fromEntries(this.frozenCells);
      }

      return backup;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'create_backup_failed' });
      return null;
    }
  }

  // Восстановление из резервной копии
  restoreFromBackup(backup) {
    try {
      if (!backup || typeof backup !== 'object') {
        throw new Error('Invalid backup');
      }

      ErrorHandler.info('Restoring from backup', { timestamp: backup.timestamp });

      // Восстанавливаем основные свойства
      this.currentLevel = backup.currentLevel || 0;
      this.xp = backup.xp || 0;
      this.xpMultiplier = backup.xpMultiplier || 1;
      this.xpMultiplierTurns = backup.xpMultiplierTurns || 0;
      this.maxReachedNumber = backup.maxReachedNumber || 8;
      this.carryNumber = backup.carryNumber || null;

      // Восстанавливаем инвентарь
      if (backup.bonusInventory) {
        this.bonusInventory = { ...backup.bonusInventory };
      }

      // Восстанавливаем статистику
      if (backup.stats) {
        this.stats = { ...backup.stats };
      }

      // Восстанавливаем достижения
      if (backup.achievements) {
        this.achievements = JSON.parse(JSON.stringify(backup.achievements));
      }

      // Восстанавливаем колесо
      this.wheelSpinsToday = backup.wheelSpinsToday || 0;
      this.lastWheelDay = backup.lastWheelDay || this.getTodayKey();

      // Восстанавливаем сетку
      if (backup.grid && Array.isArray(backup.grid)) {
        this.grid = [];
        for (let x = 0; x < this.GRID_W; x++) {
          this.grid[x] = [];
          for (let y = 0; y < this.GRID_H; y++) {
            const number = backup.grid[x]?.[y];
            this.grid[x][y] = {
              number: number || this.generateCellNumber(),
              merged: false,
              frozen: false,
              freezeTurns: 0,
              freezeMaxTurns: 0,
            };
          }
        }
      }

      // Восстанавливаем замороженные клетки
      if (backup.frozenCells) {
        this.frozenCells = new Map(Object.entries(backup.frozenCells).map(([k, v]) => [Number(k), v]));
      } else {
        this.frozenCells = new Map();
      }

      ErrorHandler.info('Backup restored successfully');
      return true;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'restore_backup_failed', backup });
      return false;
    }
  }
}
