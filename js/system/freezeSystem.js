// ===== API =====
class FreezeSystem {
  constructor(game) {
    this.game = game;
    this.frozen = new Map(); // idx -> { turns, maxTurns, type }
  }

  freezeRandomCell(turns = 5, type = 'wheel') {
    const grid = this.game.grid;
    if (!grid) {
      return { success: false, reason: 'no_grid', turns: 0, idx: null, type };
    }

    const W = this.game.GRID_W;
    const H = this.game.GRID_H;

    const candidates = [];

    for (let x = 0; x < W; x++) {
      for (let y = 0; y < H; y++) {
        const cell = grid[x]?.[y];
        if (!cell) continue;

        const idx = y * W + x;
        if (this.frozen.has(idx)) continue;

        candidates.push({ x, y, idx });
      }
    }

    if (candidates.length === 0) {
      return { success: false, reason: 'no_candidates', turns: 0, idx: null, type };
    }

    const pickIndex =
      typeof this.game.nextRandomInt === 'function'
        ? this.game.nextRandomInt(candidates.length)
        : Math.floor(Math.random() * candidates.length);
    const pick = candidates[pickIndex];
    this.freezeByIdx(pick.idx, turns, type);
    return { success: true, turns, idx: pick.idx, type };
  }

  freezeByIdx(idx, turns = 5, type = 'wheel') {
    if (this.frozen.has(idx)) return false;

    this.frozen.set(idx, {
      turns,
      maxTurns: turns,
      type,
    });

    const x = idx % this.game.GRID_W;
    const y = Math.floor(idx / this.game.GRID_W);

    const cell = this.game.grid?.[x]?.[y];
    if (cell) {
      cell.frozen = true;
      cell.freezeTurns = turns;
      cell.freezeMaxTurns = turns;
      cell.freezeType = type;
    }

    return true;
  }

  // вызывается после правильного хода

  onCorrectMove() {
    return this.updateFrozenCells();
  }

  // Lifecycle hook: вызывается из GridManager.onChainComplete.
  // Делегирует на тот же tick-таймер, что и onCorrectMove, чтобы поведение
  // оставалось предсказуемым: один завершённый ход === один шаг таймеров.

  onChainComplete(chainLength, chainSum) {
    try {
      const before = this.frozen.size;
      const unfrozen = this.updateFrozenCells();
      return {
        success: true,
        changed: before !== this.frozen.size || unfrozen > 0,
        unfrozen,
        chainLength,
        chainSum,
      };
    } catch (error) {
      return {
        success: false,
        changed: false,
        unfrozen: 0,
        reason: 'lifecycle_error',
        message: error && error.message,
      };
    }
  }

  // JSON-safe serialization current freeze map.
  // Возвращает плоский объект, не бросает.

  saveState() {
    try {
      const list = [];
      for (const [idx, data] of this.frozen.entries()) {
        if (!data) continue;
        list.push({
          idx,
          turns: typeof data.turns === 'number' ? data.turns : 0,
          maxTurns: typeof data.maxTurns === 'number' ? data.maxTurns : 0,
          type: data.type || 'wheel',
        });
      }
      return { version: 1, frozenCells: list };
    } catch (error) {
      return { version: 1, frozenCells: [], error: error && error.message };
    }
  }

  // Безопасное восстановление состояния.
  // Принимает null/undefined/invalid без падений; нормализует своё состояние
  // перед применением; восстанавливает только валидные клетки.

  loadState(state) {
    try {
      if (!state || typeof state !== 'object') {
        this.clearAll();
        return { success: false, reason: 'invalid_state', restored: 0, skipped: 0 };
      }

      const list = Array.isArray(state.frozenCells) ? state.frozenCells : null;
      if (!list) {
        this.clearAll();
        return { success: false, reason: 'invalid_state', restored: 0, skipped: 0 };
      }

      this.clearAll();

      const grid = this.game.grid;
      const W = this.game.GRID_W;
      const H = this.game.GRID_H;

      let restored = 0;
      let skipped = 0;

      for (const entry of list) {
        if (!entry || typeof entry !== 'object') {
          skipped++;
          continue;
        }
        const idx = Number(entry.idx);
        const turns = Number(entry.turns);
        if (!Number.isFinite(idx) || idx < 0 || !Number.isFinite(turns) || turns <= 0) {
          skipped++;
          continue;
        }

        const x = idx % W;
        const y = Math.floor(idx / W);
        if (x < 0 || x >= W || y < 0 || y >= H) {
          skipped++;
          continue;
        }
        if (!grid || !grid[x] || !grid[x][y]) {
          skipped++;
          continue;
        }

        const maxTurns =
          Number.isFinite(Number(entry.maxTurns)) && entry.maxTurns > 0
            ? Number(entry.maxTurns)
            : turns;
        const type = entry.type || 'wheel';

        this.frozen.set(idx, { turns, maxTurns, type });
        const cell = grid[x][y];
        cell.frozen = true;
        cell.freezeTurns = turns;
        cell.freezeMaxTurns = maxTurns;
        cell.freezeType = type;
        restored++;
      }

      return { success: true, restored, skipped };
    } catch (error) {
      return {
        success: false,
        reason: 'restore_error',
        restored: 0,
        skipped: 0,
        message: error && error.message,
      };
    }
  }

  updateFrozenCells() {
    let unfrozen = 0;

    for (const [idx, data] of [...this.frozen.entries()]) {
      data.turns--;

      const x = idx % this.game.GRID_W;
      const y = Math.floor(idx / this.game.GRID_W);
      const cell = this.game.grid?.[x]?.[y];

      if (data.turns <= 0) {
        this.frozen.delete(idx);
        if (cell) {
          cell.frozen = false;
          cell.freezeTurns = 0;
          cell.freezeMaxTurns = 0;
          delete cell.freezeType;
        }
        unfrozen++;
      } else {
        if (cell) {
          cell.freezeTurns = data.turns;
        }
      }
    }

    return unfrozen;
  }

  getFreezeData(idx) {
    return this.frozen.get(idx) || null;
  }

  clearAll() {
    for (const [idx] of this.frozen.entries()) {
      const x = idx % this.game.GRID_W;
      const y = Math.floor(idx / this.game.GRID_W);
      const cell = this.game.grid?.[x]?.[y];
      if (cell) {
        cell.frozen = false;
        cell.freezeTurns = 0;
        cell.freezeMaxTurns = 0;
        delete cell.freezeType;
      }
    }
    this.frozen.clear();
  }

  getStats() {
    return {
      currentlyFrozen: this.frozen.size,
    };
  }
}
