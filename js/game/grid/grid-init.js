// Grid Init: GridManager prototype methods.

GridManager.prototype.initGame = function (levelIndex = 0) {
  try {
    // Валидация уровня
    if (levelIndex < 0 || levelIndex >= this.game.MAX_LEVEL) {
      ErrorHandler.warn('Invalid level index in initGame', {
        levelIndex,
        MAX_LEVEL: this.game.MAX_LEVEL,
      });
      levelIndex = Math.max(0, Math.min(levelIndex, this.game.MAX_LEVEL - 1));
    }

    this.game.currentLevel = levelIndex;
    const level = this.game.levels?.[this.game.currentLevel];

    if (!level) {
      ErrorHandler.warn('Level data not found', { currentLevel: this.game.currentLevel });
      // Создаем fallback уровень
      this.game.levels = this.game.levels || [
        { target: 64, numbers: [2, 4, 8], newNumbers: [8, 16, 32] },
      ];
      return;
    }

    this.game.selected = [];
    Chain.numbers = [];
    Chain.sum = 0;
    this.game.setGamePhase('playing');
    this.game.activeBonus = null;

    // Инициализация сетки с проверкой
    this.game.grid = [];

    for (let x = 0; x < this.game.GRID_W; x++) {
      this.game.grid[x] = [];
      for (let y = 0; y < this.game.GRID_H; y++) {
        let num;
        const genFunc = this.game?.generateCellNumber;

        try {
          do {
            num = genFunc ? genFunc.call(this.game, level) : 2;
          } while (num >= level.target);
        } catch (error) {
          ErrorHandler.warn('Failed to generate cell number', { x, y, error });
          num = 2; // Fallback значение
        }

        this.game.grid[x][y] = {
          number: num,
          merged: false,
          frozen: false,
          freezeTurns: 0,
          freezeMaxTurns: 0,
        };
      }
    }

    // Обработка переносимого числа
    if (this.game.carryNumber) {
      const found = [];

      for (let x = 0; x < this.game.GRID_W; x++) {
        for (let y = 0; y < this.game.GRID_H; y++) {
          if (this.game.grid[x][y].number === this.game.carryNumber) {
            found.push({ x, y });
          }
        }
      }

      if (found.length > 1) {
        for (let i = 1; i < found.length; i++) {
          const p = found[i];
          this.game.grid[p.x][p.y].number = null;
          this.game.grid[p.x][p.y].merged = false;
        }
      }

      if (found.length === 0) {
        try {
          const rx = this.game.nextRandomInt(this.game.GRID_W);
          const ry = this.game.nextRandomInt(this.game.GRID_H);

          this.game.grid[rx][ry].number = this.game.carryNumber;
          this.game.grid[rx][ry].merged = false;
        } catch (error) {
          ErrorHandler.warn('Failed to place carry number', { error });
        }
      }
    }

    this.performFullRender();

    ErrorHandler.info('Game initialized', {
      level: this.game.currentLevel,
      target: level.target,
      gridSize: `${this.game.GRID_W}x${this.game.GRID_H}`,
    });
  } catch (error) {
    ErrorHandler.handle(error, {
      type: 'grid_init',
      levelIndex,
      currentLevel: this.game.currentLevel,
      gridSize: `${this.game.GRID_W}x${this.game.GRID_H}`,
    });

    // Fallback: создаем минимальную рабочую сетку
    this.createFallbackGrid();
  }
};

GridManager.prototype.createFallbackGrid = function () {
  try {
    ErrorHandler.info('Creating fallback grid');

    this.game.grid = [];
    for (let x = 0; x < this.game.GRID_W; x++) {
      this.game.grid[x] = [];
      for (let y = 0; y < this.game.GRID_H; y++) {
        this.game.grid[x][y] = {
          number: 2,
          merged: false,
          frozen: false,
          freezeTurns: 0,
          freezeMaxTurns: 0,
        };
      }
    }

    this.performFullRender();
    return true;
  } catch (error) {
    ErrorHandler.handle(error, { type: 'fallback_grid_failed' });
    return false;
  }
};
