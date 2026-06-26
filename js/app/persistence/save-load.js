// @ts-check
/// <reference path="../core/LostNumberGame.js" />

LostNumberGame.prototype.validateAndRepairLoadedState = function () {
  let repaired = false;

  try {
    if (this.state && typeof this.state.validateState === 'function') {
      if (!this.state.validateState()) {
        this.showMessage(this.t('game_corrupted'));
        if (typeof this.state.repairState === 'function') {
          repaired = this.state.repairState() || repaired;
        }
      }
    }

    if (this.gridManager && typeof this.gridManager.validateGrid === 'function') {
      if (!this.gridManager.validateGrid()) {
        this.showMessage(this.t('grid_corrupted'));
        if (typeof this.gridManager.repairGrid === 'function') {
          repaired = this.gridManager.repairGrid() || repaired;
        }
      }
    }

    if (repaired) {
      this.showMessage(this.t('state_repaired'));
      this.saveGameState({ force: true });
    }
  } catch (error) {
    ErrorHandler.handle(error, { type: 'state_restore' });
  }

  return repaired;
};

LostNumberGame.prototype.checkStorageHealth = function () {
  try {
    if (this.storageManager?.isStorageDegraded?.()) {
      this.showMessage(this.t('storage_degraded'));
    }
  } catch (_) {}
};

LostNumberGame.prototype.updateContinueButton = function (hasSave) {
  const enabled = hasSave === true;
  const continueBtn = /** @type {HTMLButtonElement | null} */ (
    document.getElementById('continueBtn')
  );
  if (!continueBtn) return;

  continueBtn.disabled = !enabled;
  continueBtn.setAttribute('aria-disabled', enabled ? 'false' : 'true');
};

LostNumberGame.prototype.checkExistingSave = function () {
  try {
    const raw = this.storageManager.loadGameState();

    if (!raw) {
      this.hasSave = false;
      this.updateContinueButton(false);
      return;
    }

    this.hasSave = true;
    this.updateContinueButton(true);
  } catch (error) {
    ErrorHandler.handle(error, { type: 'save_check' });
    this.hasSave = false;
    this.updateContinueButton(false);
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
    this.validateAndRepairLoadedState();

    this.applyLanguage(this.lang || 'ua');
    this.applyTheme();
    if (this.audioManager) {
      this.audioManager.updateSoundStateUI();
    }

    this.setGamePhase('playing');
    this.showScreen('game');

    this.fixGridStructure();
    this._syncFreezeSystemAfterLoad();

    if (
      this.gridManager &&
      typeof this.gridManager.countEmptyCells === 'function' &&
      this.gridManager.countEmptyCells() > 0 &&
      typeof this.gridManager._settleAllColumns === 'function'
    ) {
      this.gridManager._settleAllColumns();
    }

    if (this.gridManager) {
      this.gridManager.render();
    }
    if (this.wheelManager) {
      this.wheelManager.updateWheelUI();
    }

    if (this._levelSkipResumeMessage) {
      this.showMessage(this._levelSkipResumeMessage);
      this._levelSkipResumeMessage = null;
    }

    this.checkStorageHealth();
  } catch (error) {
    ErrorHandler.handle(error, { type: 'game_resume' });
    const ok = confirm(this.t('confirm_resume_failed'));
    if (ok) {
      this.storageManager.clearSave();
      this.hasSave = false;
      this.startNewGame();
    } else {
      this.showScreen('mainMenu');
      this.checkExistingSave();
    }
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
          const fallbackNumber =
            typeof cellData === 'number' ? cellData : this.getMinimumSpawnTile(this.currentLevel);
          this.grid[x][y] = {
            number: fallbackNumber,
            merged: false,
            frozen: false,
            freezeTurns: 0,
            freezeMaxTurns: 0,
          };
        } else if (typeof cellData === 'object' && cellData !== null) {
          if (cellData.number === undefined) {
            cellData.number = this.getMinimumSpawnTile(this.currentLevel);
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

/**
 * @param {SaveData} state
 */
LostNumberGame.prototype.restoreFromState = function (state) {
  try {
    /**
     * @param {unknown} value
     * @param {number} fallback
     * @param {{ min?: number, max?: number, integer?: boolean }} [options]
     */
    function safeNumber(value, fallback, options = {}) {
      const min = options.min ?? -Infinity;
      const max = options.max ?? Infinity;
      const integer = options.integer === true;

      const number = Number(value);
      if (!Number.isFinite(number)) return fallback;

      const clamped = Math.max(min, Math.min(max, number));
      return integer ? Math.floor(clamped) : clamped;
    }

    /**
     * @template T
     * @param {unknown} value
     * @param {T} fallback
     * @returns {Record<string, unknown> | T}
     */
    function safePlainObject(value, fallback) {
      if (!value || typeof value !== 'object' || Array.isArray(value)) {
        return fallback;
      }

      return /** @type {Record<string, unknown>} */ (value);
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
      const completedLevelNumber =
        (typeof this.pendingTransition.completedLevelIndex === 'number'
          ? this.pendingTransition.completedLevelIndex
          : this.currentLevel) + 1;
      this._levelSkipResumeMessage = this.formatTemplate('level_skip_resume', {
        level: completedLevelNumber,
      });

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

LostNumberGame.prototype.isSaveSnapshotBlocked = function () {
  const phase = this.gamePhase;
  return phase === 'animating' || phase === 'transitioning' || !!this._postMergeEffectsPending;
};

LostNumberGame.prototype.flushDeferredSaveActions = function () {
  try {
    if (this.isSaveSnapshotBlocked()) return;

    const shouldSave = !!this._deferredSaveRequested;
    const screen = this._deferredNavigateScreen;
    const showToast = !!this._deferredSaveToast;

    this._deferredSaveRequested = false;
    this._deferredNavigateScreen = null;
    this._deferredSaveToast = false;

    if (shouldSave) {
      this.saveGameState({ force: true });
      if (showToast && typeof this.showMessage === 'function') {
        this.showMessage(this.t('save_done'));
      }
    }

    if (screen && typeof this.showScreen === 'function') {
      this.setGamePhase('blocked');
      this.showScreen(screen);
    }
  } catch (error) {
    ErrorHandler.handle(error, { type: 'deferred_save_flush' });
  }
};

LostNumberGame.prototype.requestSaveGameState = function (options = {}) {
  if (this.isSaveSnapshotBlocked()) {
    this._deferredSaveRequested = true;
    if (options.showToast) {
      this._deferredSaveToast = true;
    }
    return false;
  }
  this.saveGameState({ force: true });
  if (options.showToast && typeof this.showMessage === 'function') {
    this.showMessage(this.t('save_done'));
  }
  return true;
};

LostNumberGame.prototype.requestSaveAndExitToMenu = function () {
  if (this.isSaveSnapshotBlocked()) {
    this._deferredSaveRequested = true;
    this._deferredNavigateScreen = 'mainMenu';
    return false;
  }
  this.setGamePhase('blocked');
  this.saveGameState({ force: true });
  this.showScreen('mainMenu');
  return true;
};

LostNumberGame.prototype.repairMergeGridState = function (removedCells) {
  try {
    const gm = this.gridManager;
    if (!gm) return;

    gm.clearMergeAnimationState?.();

    if (removedCells?.length && typeof gm.applyLocalGravity === 'function') {
      gm.applyLocalGravity(removedCells);
    } else if (typeof gm._settleAllColumns === 'function') {
      gm._settleAllColumns();
    }

    if (
      typeof gm.countEmptyCells === 'function' &&
      gm.countEmptyCells() > 0 &&
      typeof gm.repairGrid === 'function'
    ) {
      gm.repairGrid();
    } else if (
      typeof gm.countEmptyCells === 'function' &&
      gm.countEmptyCells() > 0 &&
      typeof gm._settleAllColumns === 'function'
    ) {
      gm._settleAllColumns();
    }

    gm.render?.();
  } catch (error) {
    ErrorHandler.handle(error, { type: 'merge_repair', removedCells: removedCells?.length });
  }
};

LostNumberGame.prototype.saveGameState = function (options) {
  const force = !!(options && options.force);

  if (!force && this.isSaveSnapshotBlocked()) {
    this._deferredSaveRequested = true;
    return;
  }

  if (
    !force &&
    this.screenState === 'game' &&
    this.gridManager &&
    typeof this.gridManager.countEmptyCells === 'function' &&
    this.gridManager.countEmptyCells() > 0
  ) {
    this._deferredSaveRequested = true;
    return;
  }

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

    /** @type {SaveData} */
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
    this.updateContinueButton(true);
    this.checkStorageHealth();

    ErrorHandler.info('Game state saved', { level: this.currentLevel, xp: this.xp });
  } catch (error) {
    ErrorHandler.handle(error, { type: 'save_state' });
  }
};

/**
 * @returns {(SerializedGridCell | null)[][]}
 */
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

/**
 * @param {unknown} rawGrid
 * @returns {LostNumberCell[][]}
 */
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
