// Grid Physics: GridManager prototype methods.

GridManager.prototype.shuffleGrid = function () {
  try {
    const ctx = this.game?.getContext?.() || this.game?.context || {};
    const state = ctx.state || this.game?.state || this.game;
    const all = [];
    for (let x = 0; x < this.game.GRID_W; x++) {
      for (let y = 0; y < this.game.GRID_H; y++) {
        const cell = this.game.grid[x]?.[y];
        if (cell && cell.number !== null && cell.number !== undefined) {
          all.push(cell.number);
        } else {
          all.push(2); // Fallback значение
        }
      }
    }

    // Безопасное перемешивание
    for (let i = all.length - 1; i > 0; i--) {
      const rng = state && state.rng ? state.rng : null;
      const j = rng ? rng.nextInt(i + 1) : Math.floor(Math.random() * (i + 1));
      [all[i], all[j]] = [all[j], all[i]];
    }

    let k = 0;
    for (let x = 0; x < this.game.GRID_W; x++) {
      for (let y = 0; y < this.game.GRID_H; y++) {
        if (this.game.grid[x]) {
          // ✅ не ломаем флаги — оставляем объект, меняем только number/merged
          const cell = this.game.grid[x][y];
          cell.number = all[k++];
          cell.merged = false;
          cell.frozen = cell.frozen || false;
          cell.freezeTurns = cell.freezeTurns || 0;
          cell.freezeMaxTurns = cell.freezeMaxTurns || 0;
        }
      }
    }

    if (this.game.freezeSystem) {
      this.game.freezeSystem.clearAll(); // ✅ Используем систему заморозки
    } else {
      this.game.frozenCells?.clear(); // Fallback
    }

    this.performFullRender();

    ErrorHandler.info('Grid shuffled');
    return true;
  } catch (error) {
    ErrorHandler.handle(error, { type: 'grid_shuffle' });
    return false;
  }
};

GridManager.prototype.applyLocalGravity = function (removedCells) {
  try {
    const ctx = this.game?.getContext?.() || this.game?.context || {};
    const state = ctx.state || this.game?.state || this.game;
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

    const genFunc = this.game.generateCellNumber || state?.generateCellNumber;
    const level = this.game.levels?.[this.game.currentLevel];

    const genNewNumber = () => {
      let newNum = genFunc ? genFunc.call(this.game) : 2;
      if (level && level.target) {
        // защита от бесконечного цикла
        let guard = 0;
        while (newNum >= level.target && guard++ < 50) {
          newNum = genFunc ? genFunc.call(this.game) : 2;
        }
        if (newNum >= level.target) newNum = 2;
      }
      return newNum;
    };

    const isFrozenAt = (x, y) => {
      const idx = y * W + x;
      if (this.game.freezeSystem && typeof this.game.freezeSystem.getFreezeData === 'function') {
        return !!this.game.freezeSystem.getFreezeData(idx);
      }
      return !!grid?.[x]?.[y]?.frozen;
    };

    // 1) Сначала “удаляем” числа (фризовые клетки сюда не попадают, но на всякий)
    for (let x = 0; x < W; x++) {
      for (let y = 0; y < H; y++) {
        if (removedMap[x]?.has(y)) {
          if (!grid[x] || !grid[x][y]) continue;
          if (isFrozenAt(x, y)) continue; // замороженные не удаляем
          grid[x][y].number = null;
          grid[x][y].merged = false;
        }
      }
    }

    // 2) Якорная гравитация по колонкам (поддержка нескольких frozen в одном столбе)
    for (let x = 0; x < W; x++) {
      if (!grid[x]) continue;

      // собираем все frozen Y в колонке
      const frozenYs = [];
      for (let y = 0; y < H; y++) {
        if (isFrozenAt(x, y)) frozenYs.push(y);
      }
      frozenYs.sort((a, b) => a - b);

      // helper: применить гравитацию в сегменте [segTop..segBottom]
      // spawnMode:
      //   - 'spawn' => пустоты сверху сегмента заполняем новыми числами
      //   - 'no_spawn' => пустоты остаются null (сегмент "мертв" до разморозки)
      const settleSegment = (segTop, segBottom, spawnMode) => {
        if (segBottom < segTop) return;

        const nums = [];
        for (let y = segBottom; y >= segTop; y--) {
          const cell = grid[x][y];
          if (cell && cell.number !== null && cell.number !== undefined) {
            nums.push(cell.number);
          }
        }

        // очищаем сегмент
        for (let y = segTop; y <= segBottom; y++) {
          if (!grid[x][y]) {
            grid[x][y] = { number: null, merged: false, frozen: false, freezeTurns: 0, freezeMaxTurns: 0 };
          }
          // frozen внутри сегмента невозможны (мы сегменты режем по frozen), но на всякий
          if (isFrozenAt(x, y)) continue;
          grid[x][y].number = null;
          grid[x][y].merged = false;
          // не трогаем frozen-мета здесь; визуал синхронизирует updateFrozenCells()
        }

        // осаживаем вниз
        let writeY = segBottom;
        for (const n of nums) {
          while (writeY >= segTop && isFrozenAt(x, writeY)) writeY--; // защита
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
        } else {
          // no_spawn: оставляем null сверху сегмента
          // ничего не делаем
        }
      };

      if (frozenYs.length === 0) {
        // обычная колонка: всё осаживаем + спавним сверху
        settleSegment(0, H - 1, 'spawn');
        continue;
      }

      // ТОП-сегмент (только он спавнит новые числа)
      const firstFrozen = frozenYs[0];
      settleSegment(0, firstFrozen - 1, 'spawn');

      // МИД-сегменты между frozen (без спавна)
      for (let i = 0; i < frozenYs.length - 1; i++) {
        const segTop = frozenYs[i] + 1;
        const segBottom = frozenYs[i + 1] - 1;
        settleSegment(segTop, segBottom, 'no_spawn');
      }

      // НИЖНИЙ сегмент под последним frozen (без спавна)
      const lastFrozen = frozenYs[frozenYs.length - 1];
      settleSegment(lastFrozen + 1, H - 1, 'no_spawn');
    }

    // 3) ✅ После якорной гравитации делаем “подсыпку” (pressure transfer), чтобы поле не умирало
    // Режим: переносим максимум несколько раз за ход
    this.applyPressureTransfer(2, 8);

    this.performFullRender();
    return true;
  } catch (error) {
    ErrorHandler.handle(error, {
      type: 'gravity_application_anchor',
      removedCells: removedCells?.length,
    });
    return false;
  }
};

GridManager.prototype.applyPressureTransfer = function (requiredEmptyDepth = 2, maxMovesPerTurn = 8) {
  try {
    const ctx = this.game?.getContext?.() || this.game?.context || {};
    const state = ctx.state || this.game?.state || this.game;
    const grid = this.game.grid;
    const W = this.game.GRID_W;
    const H = this.game.GRID_H;
    const genFunc = this.game.generateCellNumber || state?.generateCellNumber;
    const level = this.game.levels?.[this.game.currentLevel];

    let moves = 0;

    // делаем несколько переносов за ход, но ограниченно
    while (moves < maxMovesPerTurn) {
      let moved = false;

      // ищем "живой" столб (без frozen) как источник
      for (let sx = 0; sx < W && !moved; sx++) {
        if (!grid[sx]) continue;

        // источник должен быть живым: без frozen (иначе мы нарушим якорь)
        let srcHasFrozen = false;
        for (let y = 0; y < H; y++) {
          if (grid[sx][y]?.frozen) {
            srcHasFrozen = true;
            break;
          }
        }
        if (srcHasFrozen) continue;

        // снизу вверх: "нижний блок решает"
        for (let y = H - 1; y >= 0 && !moved; y--) {
          const srcCell = grid[sx][y];
          if (!srcCell || srcCell.number == null) continue;

          // смотрим влево/вправо
          const candidates = [];
          const lx = sx - 1;
          const rx = sx + 1;

          if (lx >= 0) {
            const depth = this.countEmptyBelow(lx, y);
            if (depth >= requiredEmptyDepth && !grid[lx][y]?.frozen) candidates.push({ tx: lx, depth });
          }
          if (rx < W) {
            const depth = this.countEmptyBelow(rx, y);
            if (depth >= requiredEmptyDepth && !grid[rx][y]?.frozen) candidates.push({ tx: rx, depth });
          }

          if (candidates.length === 0) continue;

          // выбираем сторону: больше пустоты = приоритет
          candidates.sort((a, b) => b.depth - a.depth);
          const tx = candidates[0].tx;

          // целевая клетка должна быть пустая
          if (grid[tx][y].number != null) continue;

          // ✅ переносим блок в бок
          grid[tx][y].number = srcCell.number;
          srcCell.number = null;

          // ✅ "схлопывание" источника: всё выше спускается на 1
          for (let yy = y; yy > 0; yy--) {
            grid[sx][yy].number = grid[sx][yy - 1].number;
          }

          // ✅ спавним сверху В ЖИВОМ столбе
          let newNum = genFunc ? genFunc.call(this.game) : 2;
          if (level?.target) {
            while (newNum >= level.target) {
              newNum = genFunc ? genFunc.call(this.game) : 2;
            }
          }
          grid[sx][0].number = newNum;

          moved = true;
          moves++;
        }
      }

      if (!moved) break;
    }

    return moves;
  } catch (error) {
    ErrorHandler.handle(error, { type: 'pressure_transfer_failed' });
    return 0;
  }
};

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
