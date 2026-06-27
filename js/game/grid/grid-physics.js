// @ts-check

GridManager.prototype.shuffleGrid = function () {
  try {
    const all = [];
    for (let x = 0; x < this.game.GRID_W; x++) {
      for (let y = 0; y < this.game.GRID_H; y++) {
        const cell = this.game.grid[x]?.[y];
        if (cell && cell.number !== null && cell.number !== undefined) {
          all.push(cell.number);
        } else {
          all.push(2);
        }
      }
    }

    for (let i = all.length - 1; i > 0; i--) {
      const j = this.game.nextRandomInt(i + 1);
      [all[i], all[j]] = [all[j], all[i]];
    }

    let k = 0;
    for (let x = 0; x < this.game.GRID_W; x++) {
      for (let y = 0; y < this.game.GRID_H; y++) {
        if (this.game.grid[x]) {
          const cell = this.game.grid[x][y];
          cell.number = all[k++];
          cell.merged = false;
          cell.frozen = false;
          cell.freezeTurns = 0;
          cell.freezeMaxTurns = 0;
          cell.freezeType = null;
        }
      }
    }

    if (this.game.freezeSystem) {
      this.game.freezeSystem.clearAll();
    } else {
      this.game.frozenCells?.clear();
    }

    this.preferSyncOrFullRender();

    ErrorHandler.info('Grid shuffled');
    return true;
  } catch (error) {
    ErrorHandler.handle(error, { type: 'grid_shuffle' });
    return false;
  }
};

/**
 * @returns {number}
 */
GridManager.prototype._genSpawnNumber = function () {
  const genFunc = this.game?.generateCellNumber;
  const level =
    typeof this.game.getLevelConfig === 'function'
      ? this.game.getLevelConfig(this.game.currentLevel)
      : this.game.levels?.[this.game.currentLevel];

  try {
    let newNum = genFunc ? genFunc.call(this.game, level) : 2;
    if (level?.target) {
      let guard = 0;
      while (newNum >= level.target && guard++ < 50) {
        newNum = genFunc ? genFunc.call(this.game, level) : 2;
      }
      if (newNum >= level.target) newNum = 2;
    }
    return newNum;
  } catch (_) {
    return 2;
  }
};

/**
 * @param {number} x
 * @param {number} y
 * @returns {boolean}
 */
GridManager.prototype._isCellFrozen = function (x, y) {
  const W = this.game.GRID_W;
  const idx = y * W + x;
  if (this.game.freezeSystem && typeof this.game.freezeSystem.getFreezeData === 'function') {
    return !!this.game.freezeSystem.getFreezeData(idx);
  }
  return !!this.game.grid?.[x]?.[y]?.frozen;
};

/**
 * Collapse each column and spawn new tiles in empty top cells.
 */
GridManager.prototype._settleAllColumns = function () {
  const W = this.game.GRID_W;
  const H = this.game.GRID_H;
  const grid = this.game.grid;
  const genNewNumber = () => this._genSpawnNumber();

  const isFrozenAt = (x, y) => this._isCellFrozen(x, y);

  for (let x = 0; x < W; x++) {
    if (!grid[x]) continue;

    const frozenYs = [];
    for (let y = 0; y < H; y++) {
      if (isFrozenAt(x, y)) frozenYs.push(y);
    }
    frozenYs.sort((a, b) => a - b);

    const settleSegment = (segTop, segBottom, spawnMode) => {
      if (segBottom < segTop) return;

      const nums = [];
      for (let y = segBottom; y >= segTop; y--) {
        const cell = grid[x][y];
        if (cell && cell.number !== null && cell.number !== undefined) {
          nums.push(cell.number);
        }
      }

      for (let y = segTop; y <= segBottom; y++) {
        if (!grid[x][y]) {
          grid[x][y] = {
            number: null,
            merged: false,
            frozen: false,
            freezeTurns: 0,
            freezeMaxTurns: 0,
          };
        }
        if (isFrozenAt(x, y)) continue;
        grid[x][y].number = null;
        grid[x][y].merged = false;
      }

      let writeY = segBottom;
      for (const n of nums) {
        while (writeY >= segTop && isFrozenAt(x, writeY)) writeY--;
        if (writeY < segTop) break;
        grid[x][writeY].number = n;
        grid[x][writeY].merged = false;
        writeY--;
      }

      if (spawnMode === 'spawn') {
        while (writeY >= segTop) {
          if (!isFrozenAt(x, writeY)) {
            grid[x][writeY].number = genNewNumber();
            grid[x][writeY].merged = false;
          }
          writeY--;
        }
      }
    };

    if (frozenYs.length === 0) {
      settleSegment(0, H - 1, 'spawn');
      continue;
    }

    const firstFrozen = frozenYs[0];
    settleSegment(0, firstFrozen - 1, 'spawn');

    for (let i = 0; i < frozenYs.length - 1; i++) {
      const segTop = frozenYs[i] + 1;
      const segBottom = frozenYs[i + 1] - 1;
      settleSegment(segTop, segBottom, 'no_spawn');
    }

    const lastFrozen = frozenYs[frozenYs.length - 1];
    settleSegment(lastFrozen + 1, H - 1, 'no_spawn');
  }
};

/**
 * @param {GridPoint[]} removedCells
 * @returns {boolean}
 */
GridManager.prototype.applyLocalGravity = function (removedCells) {
  try {
    if (!removedCells || !Array.isArray(removedCells)) {
      ErrorHandler.warn('Invalid removedCells in applyLocalGravity', { removedCells });
      return false;
    }

    const removedMap = {};
    removedCells.forEach((c) => {
      if (c && typeof c.x === 'number' && typeof c.y === 'number') {
        if (!removedMap[c.x]) removedMap[c.x] = new Set();
        removedMap[c.x].add(c.y);
      }
    });

    const W = this.game.GRID_W;
    const H = this.game.GRID_H;
    const grid = this.game.grid;

    const isFrozenAt = (x, y) => this._isCellFrozen(x, y);

    for (let x = 0; x < W; x++) {
      for (let y = 0; y < H; y++) {
        if (removedMap[x]?.has(y)) {
          if (!grid[x] || !grid[x][y]) continue;
          if (isFrozenAt(x, y)) continue;
          grid[x][y].number = null;
          grid[x][y].merged = false;
        }
      }
    }

    this._settleAllColumns();
    this.applyPressureTransfer(2, 8);
    this._settleAllColumns();

    this.clearMergeAnimationState?.();
    this.preferSyncOrFullRender();
    return true;
  } catch (error) {
    ErrorHandler.handle(error, {
      type: 'gravity_application_anchor',
      removedCells: removedCells?.length,
    });
    return false;
  }
};

/**
 * @param {number} [requiredEmptyDepth]
 * @param {number} [maxMovesPerTurn]
 * @returns {number}
 */
GridManager.prototype.applyPressureTransfer = function (
  requiredEmptyDepth = 2,
  maxMovesPerTurn = 8,
) {
  try {
    const grid = this.game.grid;
    const W = this.game.GRID_W;
    const H = this.game.GRID_H;
    const genFunc = this.game?.generateCellNumber;
    const level =
      typeof this.game.getLevelConfig === 'function'
        ? this.game.getLevelConfig(this.game.currentLevel)
        : this.game.levels?.[this.game.currentLevel];

    let moves = 0;
    const affectedColumns = new Set();

    while (moves < maxMovesPerTurn) {
      let moved = false;

      for (let sx = 0; sx < W && !moved; sx++) {
        if (!grid[sx]) continue;

        let srcHasFrozen = false;
        for (let y = 0; y < H; y++) {
          if (this._isCellFrozen(sx, y)) {
            srcHasFrozen = true;
            break;
          }
        }
        if (srcHasFrozen) continue;

        for (let y = H - 1; y >= 0 && !moved; y--) {
          const srcCell = grid[sx][y];
          if (!srcCell || srcCell.number == null) continue;
          if (this._isCellFrozen(sx, y)) continue;

          const candidates = [];
          const lx = sx - 1;
          const rx = sx + 1;

          if (lx >= 0) {
            const depth = this.countEmptyBelow(lx, y);
            if (depth >= requiredEmptyDepth && !this._isCellFrozen(lx, y))
              candidates.push({ tx: lx, depth });
          }
          if (rx < W) {
            const depth = this.countEmptyBelow(rx, y);
            if (depth >= requiredEmptyDepth && !this._isCellFrozen(rx, y))
              candidates.push({ tx: rx, depth });
          }

          if (candidates.length === 0) continue;

          candidates.sort((a, b) => b.depth - a.depth);
          const tx = candidates[0].tx;

          if (grid[tx][y].number != null) continue;

          grid[tx][y].number = srcCell.number;
          srcCell.number = null;
          affectedColumns.add(tx);
          affectedColumns.add(sx);

          for (let yy = y; yy > 0; yy--) {
            grid[sx][yy].number = grid[sx][yy - 1].number;
          }

          let newNum;
          try {
            newNum = genFunc ? genFunc.call(this.game, level) : 2;
            if (level?.target) {
              let guard = 0;
              while (newNum >= level.target && guard++ < 50) {
                newNum = genFunc ? genFunc.call(this.game, level) : 2;
              }
              if (newNum >= level.target) newNum = 2;
            }
          } catch (_) {
            newNum = 2;
          }
          grid[sx][0].number = newNum;

          moved = true;
          moves++;
        }
      }

      if (!moved) break;
    }

    for (const cx of affectedColumns) {
      if (!grid[cx]) continue;
      const nums = [];
      for (let y = H - 1; y >= 0; y--) {
        const cell = grid[cx][y];
        if (cell && cell.number != null && !this._isCellFrozen(cx, y)) {
          nums.push(cell.number);
        }
      }
      let writeY = H - 1;
      for (let y = H - 1; y >= 0; y--) {
        if (this._isCellFrozen(cx, y)) continue;
        grid[cx][y].number = null;
        grid[cx][y].merged = false;
      }
      for (const n of nums) {
        while (writeY >= 0 && this._isCellFrozen(cx, writeY)) writeY--;
        if (writeY < 0) break;
        grid[cx][writeY].number = n;
        writeY--;
      }
      while (writeY >= 0) {
        while (writeY >= 0 && this._isCellFrozen(cx, writeY)) writeY--;
        if (writeY < 0) break;
        grid[cx][writeY].number = this._genSpawnNumber();
        grid[cx][writeY].merged = false;
        writeY--;
      }
    }

    return moves;
  } catch (error) {
    ErrorHandler.handle(error, { type: 'pressure_transfer_failed' });
    return 0;
  }
};

/**
 * @param {number} x
 * @param {number} y
 * @returns {number}
 */
GridManager.prototype.countEmptyBelow = function (x, y) {
  try {
    if (x < 0 || x >= this.game.GRID_W) return 0;
    const grid = this.game.grid;

    let depth = 0;
    for (let yy = y; yy < this.game.GRID_H; yy++) {
      const cell = grid?.[x]?.[yy];
      if (!cell) break;
      if (cell.number != null) break;
      depth++;
    }
    return depth;
  } catch (e) {
    return 0;
  }
};

GridManager.prototype.countEmptyCells = function () {
  try {
    let c = 0;
    for (let x = 0; x < this.game.GRID_W; x++) {
      for (let y = 0; y < this.game.GRID_H; y++) {
        const cell = this.game.grid?.[x]?.[y];
        if (!cell || cell.number === null || cell.number === undefined || cell.number === 0) {
          c++;
        }
      }
    }
    return c;
  } catch (error) {
    ErrorHandler.warn('countEmptyCells failed', error);
    return 0;
  }
};
