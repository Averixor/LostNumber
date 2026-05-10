// ==================== GAME CORE ====================
class GameCore {
  constructor(game) {
    this.game = game;
  }

  validateMove(state) {
    try {
      const { selected, grid, chain } = state;
      const isFrozenFn =
        typeof this.game?.isCellFrozen === 'function'
          ? (idx) => this.game.isCellFrozen(idx)
          : (idx) => state.frozenCells?.has(idx);

      // Запрет начинать цепочку с замороженной клетки
      if (selected.length > 0) {
        const firstCell = selected[0];
        const firstIdx = firstCell.y * this.game.GRID_W + firstCell.x;
        if (isFrozenFn(firstIdx)) {
          return { valid: false, reason: 'cell_frozen' };
        }
      }

      if (selected.length < 2) {
        return { valid: false, reason: 'chain_too_short' };
      }

      // Проверка всех клеток в цепочке
      for (let i = 0; i < selected.length; i++) {
        const cell = selected[i];
        const idx = cell.y * this.game.GRID_W + cell.x;

        // Запрет включать замороженные клетки в цепочку
        if (isFrozenFn(idx)) {
          return { valid: false, reason: 'cell_frozen' };
        }

        // Проверка смежности (кроме первой клетки)
        if (i > 0) {
          const prev = selected[i - 1];
          if (!Rules.isAdjacent(prev, cell)) {
            return { valid: false, reason: 'not_adjacent' };
          }

          // Проверка чисел
          const prevNum = grid[prev.x][prev.y].number;
          const currNum = grid[cell.x][cell.y].number;
          const currentSum = chain.numbers.slice(0, i).reduce((a, b) => a + b, 0);

          if (!Rules.isValidNextNumber(currNum, prevNum, currentSum)) {
            return { valid: false, reason: 'invalid_number' };
          }
        }
      }

      const firstNum = chain.numbers[0];
      const sum = chain.sum;

      if (!Rules.isPowerOfTwo(sum) || sum <= firstNum) {
        return { valid: false, reason: 'invalid_sum' };
      }

      return { valid: true };
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'game_logic',
        method: 'validateMove',
        state: {
          selectedLength: state.selected?.length,
          chainLength: state.chain?.numbers?.length,
        },
      });
      return { valid: false, reason: 'validation_error' };
    }
  }

  isAdjacent(a, b) {
    try {
      return Rules.isAdjacent(a, b);
    } catch (error) {
      ErrorHandler.warn('isAdjacent failed', { a, b, error });
      return false;
    }
  }

  isValidNextNumber(next, prev, chainSum) {
    try {
      return Rules.isValidNextNumber(next, prev, chainSum);
    } catch (error) {
      ErrorHandler.warn('isValidNextNumber failed', { next, prev, chainSum, error });
      return false;
    }
  }

  isPowerOfTwo(n) {
    try {
      return Rules.isPowerOfTwo(n);
    } catch (error) {
      ErrorHandler.warn('isPowerOfTwo failed', { n, error });
      return false;
    }
  }

  canFinishChain(chain) {
    try {
      return Rules.canFinishChain(chain);
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'game_logic',
        method: 'canFinishChain',
        chain: { length: chain?.numbers?.length, sum: chain?.sum },
      });
      return false;
    }
  }

  getWheelCost() {
    try {
      const wm = this.game?.wheelManager;
      if (wm && typeof wm.getWheelCost === 'function') {
        return wm.getWheelCost();
      }
      // Fallback: те саме, що в WheelManager (BASE 25, FREE 5, STEP 10).
      const BASE = 25;
      const STEP = 10;
      const FREE = 5;
      const spins = this.game?.wheelSpinsToday || 0;
      return spins < FREE ? BASE : BASE + (spins - FREE) * STEP;
    } catch (error) {
      ErrorHandler.warn('getWheelCost failed', error);
      return 25;
    }
  }

  // === НОВЫЕ МЕТОДЫ ДЛЯ ОБРАБОТКИ ОШИБОК ===

  // Валидация игрового состояния
  validateGameState() {
    try {
      const issues = [];

      if (!this.game.grid) {
        issues.push('Grid not initialized');
      }

      if (!this.game.levels || !Array.isArray(this.game.levels)) {
        issues.push('Levels not properly defined');
      }

      if (this.game.currentLevel < 0 || this.game.currentLevel >= this.game.MAX_LEVEL) {
        issues.push(`Invalid current level: ${this.game.currentLevel}`);
      }

      if (this.game.xp < 0) {
        issues.push('Negative XP');
      }

      if (issues.length > 0) {
        ErrorHandler.warn('Game state validation issues', {
          type: 'state_validation',
          issues,
          currentLevel: this.game.currentLevel,
          xp: this.game.xp,
          gridExists: !!this.game.grid,
        });
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'validation', method: 'validateGameState' });
      return false;
    }
  }

  // Восстановление после ошибки
  recoverFromError(errorType) {
    try {
      ErrorHandler.info('Attempting recovery from error', { errorType });

      switch (errorType) {
        case 'grid_corruption':
          // Пересоздаем сетку
          if (this.game.gridManager && typeof this.game.gridManager.initGame === 'function') {
            this.game.gridManager.initGame(this.game.currentLevel);
            return true;
          }
          break;

        case 'state_corruption':
          // Сбрасываем состояние игры
          this.game.resetRuntimeState();
          return true;

        case 'ui_corruption':
          // Перерисовываем UI
          if (typeof this.game.renderDynamicUI === 'function') {
            this.game.renderDynamicUI();
            return true;
          }
          break;
      }

      return false;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'recovery_failed', originalError: errorType });
      return false;
    }
  }

  // Проверка целостности данных
  checkDataIntegrity() {
    try {
      const checks = {
        grid: this.checkGridIntegrity(),
        state: this.checkStateIntegrity(),
        save: this.checkSaveIntegrity(),
      };

      const failedChecks = Object.entries(checks)
        .filter(([_, passed]) => !passed)
        .map(([key]) => key);

      if (failedChecks.length > 0) {
        ErrorHandler.warn('Data integrity issues', {
          type: 'integrity_check',
          failedChecks,
          details: checks,
        });
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'integrity_check_failed' });
      return false;
    }
  }

  checkGridIntegrity() {
    try {
      if (!this.game.grid || !Array.isArray(this.game.grid)) {
        return false;
      }

      // Проверяем размеры сетки
      if (this.game.grid.length !== this.game.GRID_W) {
        return false;
      }

      for (let x = 0; x < this.game.GRID_W; x++) {
        if (!Array.isArray(this.game.grid[x]) || this.game.grid[x].length !== this.game.GRID_H) {
          return false;
        }

        // Проверяем содержимое клеток
        for (let y = 0; y < this.game.GRID_H; y++) {
          const cell = this.game.grid[x][y];
          if (!cell || typeof cell !== 'object') {
            return false;
          }

          // Пустая клетка: number === null допустимо; undefined/мусор — нет
          if (
            cell.number !== null &&
            cell.number !== undefined &&
            typeof cell.number !== 'number'
          ) {
            return false;
          }

          if (cell.merged === undefined || typeof cell.merged !== 'boolean') {
            return false;
          }

          if (cell.frozen === undefined || typeof cell.frozen !== 'boolean') {
            return false;
          }
        }
      }

      return true;
    } catch (error) {
      return false;
    }
  }

  checkStateIntegrity() {
    try {
      const requiredProps = ['currentLevel', 'xp', 'bonusInventory', 'stats', 'achievements'];

      for (const prop of requiredProps) {
        if (this.game[prop] === undefined) {
          return false;
        }
      }

      // Проверяем типы
      if (typeof this.game.currentLevel !== 'number' || this.game.currentLevel < 0) {
        return false;
      }

      if (typeof this.game.xp !== 'number' || this.game.xp < 0) {
        return false;
      }

      if (!this.game.bonusInventory || typeof this.game.bonusInventory !== 'object') {
        return false;
      }

      return true;
    } catch (error) {
      return false;
    }
  }

  checkSaveIntegrity() {
    try {
      if (!this.game.storageManager) {
        return false;
      }

      const saved = this.game.storageManager.loadGameState();
      if (!saved) {
        return true; // Нет сохранения - это нормально
      }

      // Проверяем основные поля сохранения
      const requiredSaveFields = ['version', 'currentLevel', 'xp', 'grid'];
      for (const field of requiredSaveFields) {
        if (saved[field] === undefined) {
          return false;
        }
      }

      return true;
    } catch (error) {
      return false;
    }
  }
}
