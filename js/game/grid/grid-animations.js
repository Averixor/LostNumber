GridManager.prototype.animateCarryAppear = function (x, y) {
  try {
    const cell = this.cellCache?.[x]?.[y];
    if (!cell) return;

    cell.classList.add('carry');
    setTimeout(() => {
      try {
        cell.classList.remove('carry');
      } catch (e) {}
    }, 500);
  } catch (error) {
    ErrorHandler.warn('animateCarryAppear failed', { x, y, error });
  }
};

GridManager.prototype.animatePopping = function (cells, callback) {
  try {
    if (!this.game.animationEnabled) {
      if (callback) callback();
      return;
    }

    cells.forEach((s) => {
      const cell = this.cellCache?.[s.x]?.[s.y];
      if (cell) cell.classList.add('popping');
    });

    setTimeout(() => {
      try {
        if (callback) callback();
      } catch (error) {
        if (callback) callback();
      }
    }, 275);
  } catch (error) {
    if (callback) callback();
  }
};

GridManager.prototype.animateGravity = function (removedCells, callback) {
  try {
    if (!this.game.animationEnabled) {
      if (callback) callback();
      return;
    }

    const removedMap = {};
    removedCells?.forEach((c) => {
      if (c && typeof c.x === 'number' && typeof c.y === 'number') {
        if (!removedMap[c.x]) removedMap[c.x] = [];
        removedMap[c.x].push(c.y);
      }
    });

    const W = this.game.GRID_W;
    const H = this.game.GRID_H;
    const movedCells = [];

    for (let x = 0; x < W; x++) {
      const ys = removedMap[x] ? removedMap[x].slice().sort((a, b) => a - b) : [];
      if (!ys.length) continue;

      for (let y = 0; y < H; y++) {
        if (ys.includes(y)) continue;

        let holesBelow = 0;
        for (let i = 0; i < ys.length; i++) {
          if (ys[i] > y) holesBelow++;
        }

        if (holesBelow > 0) {
          const cell = this.cellCache?.[x]?.[y];
          if (cell) {
            cell.style.willChange = 'transform';
            cell.style.transition = 'transform 0.25s cubic-bezier(0.4, 0, 0.2, 1)';
            cell.style.transform = `translateY(${holesBelow * 100}%)`;
            movedCells.push(cell);
          }
        }
      }
    }

    setTimeout(() => {
      try {
        movedCells.forEach((cell) => {
          cell.style.transition = '';
          cell.style.transform = '';
          cell.style.willChange = '';
        });
        if (callback) callback();
      } catch (error) {
        if (callback) callback();
      }
    }, 260);
  } catch (error) {
    if (callback) callback();
  }
};
