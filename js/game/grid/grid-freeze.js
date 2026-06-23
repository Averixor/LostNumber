GridManager.prototype.updateFrozenCells = function () {
  try {
    if (
      this.game &&
      this.game.freezeSystem &&
      typeof this.game.freezeSystem.updateFrozenCells === 'function'
    ) {
      const changed = this.game.freezeSystem.updateFrozenCells();
      this.updateFrozenStates();
      return changed || 0;
    }

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
            if (!this.game.grid[x][y].freezeMaxTurns)
              this.game.grid[x][y].freezeMaxTurns = Math.max(newTurns, 1);
          }
        }
      }

      if (anyChanged) this.updateFrozenStates();
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
    const W = this.game.GRID_W;
    const H = this.game.GRID_H;

    if (!this.cellCache || this.cellCache.length !== W) return;

    for (let x = 0; x < W; x++) {
      for (let y = 0; y < H; y++) {
        const cell = this.cellCache[x]?.[y];
        const cd = this.game.grid?.[x]?.[y];
        if (cell && cd) {
          this._updateFrozenVisuals(cell, cd, x, y);
        }
      }
    }
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
