LostNumberGame.prototype.checkExistingSave = function () {
  try {
    const raw = this.storageManager.loadGameState();
    const continueBtn = document.getElementById('continueBtn');

    if (!raw) {
      this.hasSave = false;
      if (continueBtn) {
        continueBtn.disabled = true;
        continueBtn.style.opacity = '0.5';
      }
      return;
    }

    this.hasSave = true;
    if (continueBtn) {
      continueBtn.disabled = false;
      continueBtn.style.opacity = '1';
    }
  } catch (error) {
    ErrorHandler.handle(error, { type: 'save_check' });
    this.hasSave = false;
  }
};

LostNumberGame.prototype.resumeGame = function () {
  try {
    const data = this.storageManager.loadGameState();

    this.resetRuntimeState();

    if (!data) {
      this.startNewGame();
      return;
    }

    this.restoreFromState(data);

    this.applyLanguage(this.lang || 'ua');
    this.applyTheme();
    if (this.audioManager) {
      this.audioManager.updateSoundStateUI();
    }

    this.setGamePhase('playing');
    this.showScreen('game');

    this.fixGridStructure();
    this._syncFreezeSystemAfterLoad();

    if (this.gridManager) {
      this.gridManager.render();
    }
    if (this.wheelManager) {
      this.wheelManager.updateWheelUI();
    }
  } catch (error) {
    ErrorHandler.handle(error, { type: 'game_resume', data: arguments[0] });
    console.error('Resume fail, starting new:', error);
    this.startNewGame();
  }
};

LostNumberGame.prototype.fixGridStructure = function () {
  try {
    if (!this.grid || !Array.isArray(this.grid)) {
      this.gridManager.initGame(this.currentLevel);
      return;
    }

    for (let x = 0; x < this.GRID_W; x++) {
      if (!this.grid[x] || !Array.isArray(this.grid[x])) {
        this.grid[x] = [];
      }

      for (let y = 0; y < this.GRID_H; y++) {
        const cellData = this.grid[x][y];

        if (typeof cellData === 'number' || cellData === null || cellData === undefined) {
          this.grid[x][y] = {
            number: typeof cellData === 'number' ? cellData : this.generateCellNumber(),
            merged: false,
            frozen: false,
            freezeTurns: 0,
            freezeMaxTurns: 0,
          };
        } else if (typeof cellData === 'object' && cellData !== null) {
          if (cellData.number === undefined) {
            cellData.number = this.generateCellNumber();
          }
          if (cellData.merged === undefined) {
            cellData.merged = false;
          }
          if (cellData.frozen === undefined) {
            cellData.frozen = false;
          }
          if (cellData.freezeTurns === undefined) {
            cellData.freezeTurns = 0;
          }
          if (cellData.freezeMaxTurns === undefined) {
            cellData.freezeMaxTurns = 0;
          }
        }
      }
    }
  } catch (error) {
    ErrorHandler.handle(error, { type: 'grid_fix' });
    if (this.gridManager) {
      this.gridManager.initGame(this.currentLevel);
    }
  }
};

LostNumberGame.prototype.restoreFromState = function (state) {
  try {
    function safeNumber(value, fallback, options = {}) {
      const min = options.min ?? -Infinity;
      const max = options.max ?? Infinity;
      const integer = options.integer === true;

      const number = Number(value);
      if (!Number.isFinite(number)) return fallback;

      const clamped = Math.max(min, Math.min(max, number));
      return integer ? Math.floor(clamped) : clamped;
    }

    function safePlainObject(value, fallback) {
      if (!value || typeof value !== 'object' || Array.isArray(value)) {
        return fallback;
      }

      return value;
    }

    this.currentLevel = safeNumber(state.currentLevel, 0, {
      min: 0,
      integer: true,
    });
    this.xp = safeNumber(state.xp, 0, { min: 0 });
    this.xpMultiplier = safeNumber(state.xpMultiplier, 1, { min: 1 });
    this.xpMultiplierTurns = safeNumber(state.xpMultiplierTurns, 0, {
      min: 0,
      integer: true,
    });

    const gridSchemaVersion = Number(state.gridSchemaVersion) || 1;
    this._lastLoadedGridSchemaVersion = gridSchemaVersion;
    if (gridSchemaVersion >= 2 && Array.isArray(state.grid)) {
      this.grid = this._parseGridV2(state.grid);
    } else {
      this.grid = state.grid || [];
    }

    this.bonusInventory = safePlainObject(state.bonusInventory, {
      destroy: 0,
      shuffle: 0,
      explosion: 0,
    });
    this.pendingTransition = safePlainObject(state.pendingTransition, null);
    this.maxReachedNumber = safeNumber(state.maxReachedNumber, 8, { min: 2 });
    this.carryNumber = state.carryNumber ?? null;
    this.stats = safePlainObject(state.stats, this.defaultStats());
    this.achievements = safePlainObject(state.achievements, this.defaultAchievements());
    this.wheelSpinsToday = safeNumber(state.wheelSpinsToday, 0, {
      min: 0,
      integer: true,
    });
    this.lastWheelDay =
      typeof state.lastWheelDay === 'string' && state.lastWheelDay
        ? state.lastWheelDay
        : this.getTodayKey();

    const frozenCellsSource = safePlainObject(state.frozenCells, null);
    const normalizedFrozenCells = new Map();
    if (frozenCellsSource) {
      const maxIdx = this.GRID_W * this.GRID_H;
      Object.entries(frozenCellsSource).forEach(([key, value]) => {
        const idx = Number(key);
        if (!Number.isInteger(idx) || idx < 0 || idx >= maxIdx) return;
        const turns =
          typeof value === 'number' ? value : typeof value?.turns === 'number' ? value.turns : 0;
        if (turns > 0) {
          normalizedFrozenCells.set(idx, turns);
        }
      });
    }
    this.frozenCells = normalizedFrozenCells;

    this.dailyQuests = this.dailyQuestManager.loadDailyQuests();
    this.checkWheelDailyReset();

    if (this.pendingTransition && this.pendingTransition.active) {
      this.currentLevel = safeNumber(this.pendingTransition.nextLevel, this.currentLevel, {
        min: 0,
        integer: true,
      });
      this.carryNumber = this.pendingTransition.carryNumber ?? null;
      this.pendingTransition = null;
      this.gridManager.initGame(this.currentLevel);
      this.saveGameState();
    } else {
      this.updateTargetInfo();
      this.updateXPBar();
      if (this.bonusManager) {
        this.bonusManager.updateBonusesUI();
      }
      if (this.wheelManager) {
        this.wheelManager.updateWheelUI();
      }
    }
  } catch (error) {
    ErrorHandler.handle(error, { type: 'state_restore', state });
    throw error;
  }
};

LostNumberGame.prototype.saveGameState = function () {
  try {
    const gridV2 = this._serializeGridV2();

    const legacyFrozenCells =
      this.freezeSystem && this.freezeSystem.frozen instanceof Map
        ? Object.fromEntries(
            [...this.freezeSystem.frozen.entries()]
              .filter(([idx, data]) => {
                const i = Number(idx);
                const t = data ? Number(data.turns) : NaN;
                return Number.isFinite(i) && i >= 0 && Number.isFinite(t) && t > 0;
              })
              .map(([idx, data]) => [Number(idx), Number(data.turns)]),
          )
        : this.frozenCells instanceof Map
          ? Object.fromEntries(this.frozenCells)
          : {};

    const state = {
      version: 2,
      gridSchemaVersion: 2,
      currentLevel: this.currentLevel,
      xp: this.xp,
      xpMultiplier: this.xpMultiplier,
      xpMultiplierTurns: this.xpMultiplierTurns,
      grid: gridV2,
      bonusInventory: this.bonusInventory,
      pendingTransition: this.pendingTransition,
      maxReachedNumber: this.maxReachedNumber,
      carryNumber: this.carryNumber,
      frozenCells: legacyFrozenCells,
      stats: this.stats,
      achievements: this.achievements,
      wheelSpinsToday: this.wheelSpinsToday,
      lastWheelDay: this.lastWheelDay,
    };

    this.storageManager.saveGameState(state);
    this.hasSave = true;

    ErrorHandler.info('Game state saved', { level: this.currentLevel, xp: this.xp });
  } catch (error) {
    ErrorHandler.handle(error, { type: 'save_state' });
  }
};

LostNumberGame.prototype._serializeGridV2 = function () {
  const grid = [];
  if (!this.grid || !Array.isArray(this.grid)) return grid;

  for (let x = 0; x < this.GRID_W; x++) {
    grid[x] = [];
    const col = Array.isArray(this.grid[x]) ? this.grid[x] : [];
    for (let y = 0; y < this.GRID_H; y++) {
      const cell = col[y];
      if (!cell || typeof cell !== 'object') {
        grid[x][y] = null;
        continue;
      }
      const obj = {
        value: Number.isFinite(cell.number) ? cell.number : null,
        merged: !!cell.merged,
        frozen: !!cell.frozen,
        freezeTurns:
          Number.isFinite(cell.freezeTurns) && cell.freezeTurns >= 0 ? cell.freezeTurns : 0,
        freezeMaxTurns:
          Number.isFinite(cell.freezeMaxTurns) && cell.freezeMaxTurns >= 0
            ? cell.freezeMaxTurns
            : 0,
      };
      if (cell.freezeType) obj.freezeType = cell.freezeType;
      grid[x][y] = obj;
    }
  }
  return grid;
};

LostNumberGame.prototype._parseGridV2 = function (rawGrid) {
  const grid = [];
  for (let x = 0; x < this.GRID_W; x++) {
    grid[x] = [];
    const col = Array.isArray(rawGrid[x]) ? rawGrid[x] : [];
    for (let y = 0; y < this.GRID_H; y++) {
      const raw = col[y];
      if (!raw || typeof raw !== 'object') {
        grid[x][y] = {
          number: null,
          merged: false,
          frozen: false,
          freezeTurns: 0,
          freezeMaxTurns: 0,
        };
        continue;
      }
      const cell = {
        number: Number.isFinite(raw.value) ? raw.value : null,
        merged: !!raw.merged,
        frozen: !!raw.frozen,
        freezeTurns: Number.isFinite(raw.freezeTurns) && raw.freezeTurns >= 0 ? raw.freezeTurns : 0,
        freezeMaxTurns:
          Number.isFinite(raw.freezeMaxTurns) && raw.freezeMaxTurns >= 0 ? raw.freezeMaxTurns : 0,
      };
      if (raw.freezeType) cell.freezeType = raw.freezeType;
      grid[x][y] = cell;
    }
  }
  return grid;
};

LostNumberGame.prototype._syncFreezeSystemAfterLoad = function () {
  try {
    if (!this.freezeSystem || typeof this.freezeSystem.loadState !== 'function') return;

    const list = [];
    const seen = new Set();

    if (Array.isArray(this.grid)) {
      for (let x = 0; x < this.GRID_W; x++) {
        const col = this.grid[x];
        if (!Array.isArray(col)) continue;
        for (let y = 0; y < this.GRID_H; y++) {
          const cell = col[y];
          if (!cell || typeof cell !== 'object' || !cell.frozen) continue;
          const turns = Number.isFinite(cell.freezeTurns) ? cell.freezeTurns : 0;
          if (turns <= 0) continue;
          const idx = y * this.GRID_W + x;
          list.push({
            idx,
            turns,
            maxTurns: cell.freezeMaxTurns > 0 ? cell.freezeMaxTurns : turns,
            type: cell.freezeType || 'wheel',
          });
          seen.add(idx);
        }
      }
    }

    const schemaVersion = Number(this._lastLoadedGridSchemaVersion) || 1;
    if (schemaVersion < 2 && this.frozenCells instanceof Map) {
      for (const [idxRaw, turnsRaw] of this.frozenCells.entries()) {
        const idx = Number(idxRaw);
        const turns = Number(turnsRaw);
        if (seen.has(idx)) continue;
        if (!Number.isFinite(idx) || idx < 0) continue;
        if (!Number.isFinite(turns) || turns <= 0) continue;
        list.push({ idx, turns, maxTurns: turns, type: 'wheel' });
      }
    }

    this.freezeSystem.loadState({ version: 1, frozenCells: list });
  } catch (error) {
    ErrorHandler.warn('_syncFreezeSystemAfterLoad failed', { error });
  }
};

LostNumberGame.prototype.saveSettings = function () {
  try {
    this.settingsManager.saveSettings();
  } catch (error) {
    ErrorHandler.handle(error, { type: 'save_settings' });
  }
};
