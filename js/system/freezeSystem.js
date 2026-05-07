class FreezeSystem {
  constructor(game) {
    this.game = game;
    this.frozen = new Map(); // idx -> { turns, maxTurns, type }
  }

  // ===== API =====

  freezeRandomCell(turns = 5, type = 'wheel') {
    const grid = this.game.grid;
    if (!grid) return false;

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

    if (candidates.length === 0) return false;

    const pick = candidates[Math.floor(Math.random() * candidates.length)];
    this.freezeByIdx(pick.idx, turns, type);
    return true;
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
