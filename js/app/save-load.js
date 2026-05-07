// Save Load: LostNumberGame prototype methods.

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

    // ФИКСАЦИЯ: Восстанавливаем структуру grid, если она была сохранена как массив чисел
    this.fixGridStructure();

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
      // Если grid не существует, создаем новую
      this.gridManager.initGame(this.currentLevel);
      return;
    }

    // Проверяем каждый элемент grid
    for (let x = 0; x < this.GRID_W; x++) {
      if (!this.grid[x] || !Array.isArray(this.grid[x])) {
        this.grid[x] = [];
      }

      for (let y = 0; y < this.GRID_H; y++) {
        let cellData = this.grid[x][y];

        // Если это число, а не объект, преобразуем в объект
        if (typeof cellData === 'number' || cellData === null || cellData === undefined) {
          this.grid[x][y] = {
            number: typeof cellData === 'number' ? cellData : this.generateCellNumber(),
            merged: false,
            frozen: false,
            freezeTurns: 0,
            freezeMaxTurns: 0,
          };
        }
        // Если это объект, но не имеет нужных свойств
        else if (typeof cellData === 'object' && cellData !== null) {
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
    // В случае ошибки создаем новую сетку
    if (this.gridManager) {
      this.gridManager.initGame(this.currentLevel);
    }
  }
};

LostNumberGame.prototype.restoreFromState = function (state) {
  try {
    // Восстанавливаем только игровые данные, НЕ настройки
    this.currentLevel = state.currentLevel || 0;
    this.xp = state.xp || 0;
    this.xpMultiplier = state.xpMultiplier || 1;
    this.xpMultiplierTurns = state.xpMultiplierTurns || 0;
    this.grid = state.grid || [];
    this.bonusInventory = state.bonusInventory || { destroy: 0, shuffle: 0, explosion: 0 };
    this.pendingTransition = state.pendingTransition || null;
    this.maxReachedNumber = state.maxReachedNumber || 8;
    this.carryNumber = state.carryNumber || null;
    this.stats = state.stats || this.defaultStats();
    this.achievements = state.achievements || this.defaultAchievements();
    this.wheelSpinsToday = state.wheelSpinsToday || 0;
    this.lastWheelDay = state.lastWheelDay || this.getTodayKey();

    // ВАЖНО: НЕ восстанавливаем настройки из сохранения
    // Они должны браться из текущих настроек пользователя

    // Восстанавливаем frozenCells
    if (state.frozenCells) {
      this.frozenCells = new Map(Object.entries(state.frozenCells).map(([k, v]) => [Number(k), v]));
    } else {
      this.frozenCells = new Map();
    }

    this.dailyQuests = this.dailyQuestManager.loadDailyQuests();
    this.checkWheelDailyReset();

    if (this.pendingTransition && this.pendingTransition.active) {
      this.currentLevel = Math.min(this.pendingTransition.nextLevel, this.MAX_LEVEL - 1);
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
    throw error; // Пробрасываем дальше
  }
};

LostNumberGame.prototype.saveGameState = function () {
  try {
    // Извлекаем только числа из grid для сохранения
    const gridNumbers = [];
    if (this.grid && Array.isArray(this.grid)) {
      for (let x = 0; x < this.GRID_W; x++) {
        gridNumbers[x] = [];
        for (let y = 0; y < this.GRID_H; y++) {
          gridNumbers[x][y] = this.grid[x][y] ? this.grid[x][y].number : null;
        }
      }
    }

    // ВАЖНО: Сохраняем ТОЛЬКО игровые данные, НЕ настройки
    const state = {
      version: 2,
      currentLevel: this.currentLevel,
      xp: this.xp,
      xpMultiplier: this.xpMultiplier,
      xpMultiplierTurns: this.xpMultiplierTurns,
      grid: gridNumbers,
      bonusInventory: this.bonusInventory,
      pendingTransition: this.pendingTransition,
      maxReachedNumber: this.maxReachedNumber,
      carryNumber: this.carryNumber,
      frozenCells: Object.fromEntries(this.frozenCells),
      stats: this.stats,
      achievements: this.achievements,
      wheelSpinsToday: this.wheelSpinsToday,
      lastWheelDay: this.lastWheelDay,
      // НЕ сохраняем: animationEnabled, soundEnabled, theme, lang
      // Эти настройки хранятся отдельно
    };

    this.storageManager.saveGameState(state);
    this.hasSave = true;

    ErrorHandler.info('Game state saved', { level: this.currentLevel, xp: this.xp });
  } catch (error) {
    ErrorHandler.handle(error, { type: 'save_state' });
    // Не бросаем ошибку дальше - потеря сохранения лучше чем краш игры
  }
};

LostNumberGame.prototype.saveSettings = function () {
  try {
    this.settingsManager.saveSettings();
  } catch (error) {
    ErrorHandler.handle(error, { type: 'save_settings' });
  }
};
