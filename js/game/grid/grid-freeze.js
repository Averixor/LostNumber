// Grid Freeze: GridManager prototype methods.

GridManager.prototype.updateFrozenCells = function () {
  try {
    // ✅ Новая система
    if (this.game && this.game.freezeSystem && typeof this.game.freezeSystem.updateFrozenCells === 'function') {
      const changed = this.game.freezeSystem.updateFrozenCells();
      if (typeof this.updateFrozenStates === 'function') this.updateFrozenStates();
      return changed || 0;
    }

    // 🧯 Fallback: старая карта frozenCells (idx -> turns)
    if (this.game && this.game.frozenCells && typeof this.game.frozenCells.entries === 'function') {
      let anyChanged = 0;
      for (const [idx, turns] of this.game.frozenCells.entries()) {
        const newTurns = (turns || 0) - 1;
        const x = idx % this.game.GRID_W;
        const y = Math.floor(idx / this.game.GRID_W);

        if (newTurns <= 0) {
          this.game.frozenCells.delete(idx);
          if (this.game.grid?.[x]?.[y]) {
            this.game.grid[x][y].frozen = false;
            this.game.grid[x][y].freezeTurns = 0;
            this.game.grid[x][y].freezeMaxTurns = 0;
            delete this.game.grid[x][y].freezeType;
          }
          anyChanged = 1;
        } else {
          this.game.frozenCells.set(idx, newTurns);
          if (this.game.grid?.[x]?.[y]) {
            this.game.grid[x][y].frozen = true;
            this.game.grid[x][y].freezeTurns = newTurns;
            if (!this.game.grid[x][y].freezeMaxTurns) this.game.grid[x][y].freezeMaxTurns = Math.max(newTurns, 1);
          }
        }
      }

      if (anyChanged && typeof this.updateFrozenStates === 'function') this.updateFrozenStates();
      return anyChanged;
    }

    return 0;
  } catch (error) {
    ErrorHandler.handle(error, { type: 'grid_updateFrozenCells' });
    return 0;
  }
};

GridManager.prototype.updateFrozenStates = function () {
  try {
    const gridDiv = document.getElementById('grid');
    if (!gridDiv) return;

    const cells = gridDiv.querySelectorAll('.cell');
    cells.forEach((cell) => {
      try {
        const x = parseInt(cell.dataset.x);
        const y = parseInt(cell.dataset.y);
        const idx = y * this.game.GRID_W + x;

        let isFrozen = false;
        let freezeTurns = 0;
        let freezeMaxTurns = 0;

        if (this.game.freezeSystem) {
          const freezeData = this.game.freezeSystem.getFreezeData?.(idx);
          if (freezeData) {
            isFrozen = true;
            freezeTurns = freezeData.turns;
            freezeMaxTurns = freezeData.maxTurns;

            // ✅ синхронизируем на данные клетки
            const cd = this.game.grid?.[x]?.[y];
            if (cd) {
              cd.frozen = true;
              cd.freezeTurns = freezeTurns;
              cd.freezeMaxTurns = freezeMaxTurns;
              cd.freezeType = freezeData.type;
            }
          }
        } else {
          isFrozen = this.game.frozenCells?.has(idx);
          if (isFrozen) {
            freezeTurns = this.game.frozenCells.get(idx);
            const cellData = this.game.grid?.[x]?.[y];
            freezeMaxTurns = cellData?.freezeMaxTurns || 5;
          }
        }

        if (isFrozen) {
          cell.classList.add('frozen');

          const counter = cell.querySelector('.freeze-counter');
          if (counter) {
            counter.textContent = freezeTurns;
          }

          const snowflake = cell.querySelector('.snowflake');
          if (snowflake) {
            snowflake.style.opacity = Math.max(0.2, freezeTurns / Math.max(1, freezeMaxTurns));
          } else {
            const snowflake = document.createElement('div');
            snowflake.className = 'snowflake';
            snowflake.textContent = '❄️';
            snowflake.style.opacity = Math.max(0.2, freezeTurns / Math.max(1, freezeMaxTurns));
            cell.appendChild(snowflake);
          }
        } else {
          cell.classList.remove('frozen');
          const snowflake = cell.querySelector('.snowflake');
          const counter = cell.querySelector('.freeze-counter');
          if (snowflake) snowflake.remove();
          if (counter) counter.remove();
        }
      } catch (error) {}
    });
  } catch (error) {
    ErrorHandler.warn('updateFrozenStates failed', error);
  }
};

GridManager.prototype.initFreezeSystem = function () {
  try {
    if (!this.game.freezeSystem) {
      this.game.freezeSystem = new FreezeSystem(this.game);
      ErrorHandler.info('FreezeSystem initialized');
    }
    return this.game.freezeSystem;
  } catch (error) {
    ErrorHandler.handle(error, { type: 'init_freeze_system' });
    return null;
  }
};

GridManager.prototype.onCorrectMove = function () {
  try {
    if (this.game.freezeSystem) {
      const result = this.game.freezeSystem.onCorrectMove();
      this.updateFrozenStates();
      return result;
    }

    return { unfrozen: 0 };
  } catch (error) {
    ErrorHandler.warn('onCorrectMove failed', error);
    return { unfrozen: 0, error: error.message };
  }
};

GridManager.prototype.onChainComplete = function (chainLength, chainSum) {
  try {
    if (this.game.freezeSystem) {
      const result = this.game.freezeSystem.onChainComplete(chainLength, chainSum);
      this.updateFrozenStates();
      return result;
    }

    return { unfrozen: 0, affected: 0 };
  } catch (error) {
    ErrorHandler.warn('onChainComplete failed', error);
    return { unfrozen: 0, affected: 0, error: error.message };
  }
};
