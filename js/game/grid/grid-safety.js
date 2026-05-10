// Grid Safety: GridManager prototype methods.

GridManager.prototype.validateGrid = function () {
  try {
    const issues = [];

    if (!this.game.grid || !Array.isArray(this.game.grid)) {
      issues.push('Grid not initialized');
      return false;
    }

    if (this.game.grid.length !== this.game.GRID_W) {
      issues.push(
        `Grid width mismatch: expected ${this.game.GRID_W}, got ${this.game.grid.length}`,
      );
    }

    for (let x = 0; x < this.game.GRID_W; x++) {
      if (!Array.isArray(this.game.grid[x]) || this.game.grid[x].length !== this.game.GRID_H) {
        issues.push(`Row ${x} invalid: length ${this.game.grid[x]?.length || 'undefined'}`);
        continue;
      }

      for (let y = 0; y < this.game.GRID_H; y++) {
        const cell = this.game.grid[x][y];
        if (!cell || typeof cell !== 'object') {
          issues.push(`Cell [${x},${y}] is not an object`);
          continue;
        }

        if (cell.number === undefined) {
          issues.push(`Cell [${x},${y}] missing number`);
        }

        if (cell.merged === undefined) {
          issues.push(`Cell [${x},${y}] missing merged flag`);
        }

        if (cell.frozen === undefined) {
          issues.push(`Cell [${x},${y}] missing frozen flag`);
        }
      }
    }

    if (issues.length > 0) {
      ErrorHandler.warn('Grid validation failed', {
        type: 'grid_validation',
        issues: issues.slice(0, 5),
        totalIssues: issues.length,
      });
      return false;
    }

    return true;
  } catch (error) {
    ErrorHandler.handle(error, { type: 'grid_validation_error' });
    return false;
  }
};

GridManager.prototype.repairGrid = function () {
  try {
    ErrorHandler.info('Attempting to repair grid');

    let repaired = false;

    if (!this.game.grid || !Array.isArray(this.game.grid)) {
      this.game.grid = [];
      repaired = true;
    }

    for (let x = 0; x < this.game.GRID_W; x++) {
      if (!Array.isArray(this.game.grid[x])) {
        this.game.grid[x] = [];
        repaired = true;
      }

      for (let y = 0; y < this.game.GRID_H; y++) {
        let cellData = this.game.grid[x][y];

        if (!cellData || typeof cellData !== 'object') {
          cellData = {
            number: 2,
            merged: false,
            frozen: false,
            freezeTurns: 0,
            freezeMaxTurns: 0,
          };
          this.game.grid[x][y] = cellData;
          repaired = true;
        } else {
          if (cellData.number === undefined) {
            cellData.number = 2;
            repaired = true;
          }
          if (cellData.merged === undefined) {
            cellData.merged = false;
            repaired = true;
          }
          if (cellData.frozen === undefined) {
            cellData.frozen = false;
            repaired = true;
          }
          if (cellData.freezeTurns === undefined) {
            cellData.freezeTurns = 0;
            repaired = true;
          }
          if (cellData.freezeMaxTurns === undefined) {
            cellData.freezeMaxTurns = 0;
            repaired = true;
          }
        }
      }
    }

    if (repaired) {
      ErrorHandler.info('Grid repaired');
      this.preferSyncOrFullRender();
    }

    return repaired;
  } catch (error) {
    ErrorHandler.handle(error, { type: 'grid_repair_failed' });
    return false;
  }
};

GridManager.prototype.createGridBackup = function () {
  try {
    const backup = {
      timestamp: Date.now(),
      grid: [],
      freezeSystemState: this.game.freezeSystem ? this.game.freezeSystem.saveState() : null,
      frozenCells: this.game.frozenCells ? Object.fromEntries(this.game.frozenCells) : {},
    };

    if (this.game.grid && Array.isArray(this.game.grid)) {
      for (let x = 0; x < this.game.GRID_W; x++) {
        backup.grid[x] = [];
        for (let y = 0; y < this.game.GRID_H; y++) {
          const cell = this.game.grid[x]?.[y];
          backup.grid[x][y] = {
            number: cell?.number ?? null,
            merged: cell?.merged || false,
            frozen: cell?.frozen || false,
            freezeTurns: cell?.freezeTurns || 0,
            freezeMaxTurns: cell?.freezeMaxTurns || 0,
            freezeType: cell?.freezeType,
          };
        }
      }
    }

    return backup;
  } catch (error) {
    ErrorHandler.handle(error, { type: 'grid_backup_failed' });
    return null;
  }
};

GridManager.prototype.restoreGridFromBackup = function (backup) {
  try {
    if (!backup || !backup.grid) {
      throw new Error('Invalid grid backup');
    }

    ErrorHandler.info('Restoring grid from backup');

    this.game.grid = [];
    for (let x = 0; x < this.game.GRID_W; x++) {
      this.game.grid[x] = [];
      for (let y = 0; y < this.game.GRID_H; y++) {
        const cellData = backup.grid[x]?.[y];
        this.game.grid[x][y] = {
          number: cellData?.number ?? 2,
          merged: cellData?.merged || false,
          frozen: cellData?.frozen || false,
          freezeTurns: cellData?.freezeTurns || 0,
          freezeMaxTurns: cellData?.freezeMaxTurns || 0,
          freezeType: cellData?.freezeType,
        };
      }
    }

    if (backup.freezeSystemState && this.game.freezeSystem) {
      this.game.freezeSystem.loadState(backup.freezeSystemState);
    } else if (backup.frozenCells) {
      this.game.frozenCells = new Map(
        Object.entries(backup.frozenCells).map(([k, v]) => [Number(k), v]),
      );
    } else {
      this.game.frozenCells = new Map();
    }

    this.performFullRender();
    ErrorHandler.info('Grid restored from backup');
    return true;
  } catch (error) {
    ErrorHandler.handle(error, { type: 'grid_restore_failed', backup });
    return false;
  }
};

GridManager.prototype.safeExecute = function (methodName, ...args) {
  try {
    if (typeof this[methodName] !== 'function') {
      throw new Error(`Method ${methodName} not found`);
    }

    return this[methodName].apply(this, args);
  } catch (error) {
    ErrorHandler.handle(error, {
      type: 'grid_safe_execute',
      method: methodName,
      args: args,
    });

    if (methodName.includes('init') || methodName.includes('render')) {
      ErrorHandler.info('Attempting grid recovery after error');
      this.repairGrid();
    }

    return null;
  }
};

GridManager.prototype.diagnoseGridState = function () {
  try {
    const state = {
      timestamp: Date.now(),
      gridDimensions: `${this.game.GRID_W || '?'}x${this.game.GRID_H || '?'}`,
      gridExists: !!this.game.grid,
      gridType: this.game.grid ? 'Array' : 'null',
      freezeSystemExists: !!this.game.freezeSystem,
      renderCount: this.renderCount,
      selectedCells: (this.game.selected || []).length,
      emptyCells: this.countEmptyCells(),
      errorId: `LN-${Date.now().toString(36)}-${Math.random().toString(36).substr(2, 4)}`,
    };

    if (this.game.grid && Array.isArray(this.game.grid)) {
      state.gridLength = this.game.grid.length;
      state.firstRowLength = this.game.grid[0] ? this.game.grid[0].length : 'none';
    }

    if (this.game.freezeSystem) {
      state.freezeStats = this.game.freezeSystem.getStats();
    } else {
      state.frozenCellsCount = this.game.frozenCells?.size || 0;
    }

    ErrorHandler.info('Grid diagnosis', state);
    return state;
  } catch (error) {
    ErrorHandler.handle(error, { type: 'grid_diagnosis_failed' });
    return { error: true, message: error.message };
  }
};

GridManager.prototype.emergencyReset = function () {
  try {
    ErrorHandler.warn('Performing emergency grid reset');

    this.game.grid = [];
    for (let x = 0; x < (this.game.GRID_W || 6); x++) {
      this.game.grid[x] = [];
      for (let y = 0; y < (this.game.GRID_H || 6); y++) {
        this.game.grid[x][y] = {
          number: 2,
          merged: false,
          frozen: false,
          freezeTurns: 0,
          freezeMaxTurns: 0,
        };
      }
    }

    if (this.game.freezeSystem) {
      this.game.freezeSystem.clearAll();
    } else {
      this.game.frozenCells = new Map();
    }

    this.game.selected = [];
    Chain.numbers = [];
    Chain.sum = 0;

    this.performFullRender();
    ErrorHandler.info('Emergency reset completed');
    return true;
  } catch (error) {
    ErrorHandler.handle(error, { type: 'emergency_reset_failed' });
    return false;
  }
};
