GridManager.prototype.animateCarryAppear = function (x, y) {
  try {
    const gridDiv = document.getElementById('grid');
    if (!gridDiv) return;

    const cell = gridDiv.querySelector(`.cell[data-x="${x}"][data-y="${y}"]`);
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

    const gridDiv = document.getElementById('grid');
    if (!gridDiv) {
      if (callback) callback();
      return;
    }

    cells.forEach((s) => {
      try {
        const cell = gridDiv.querySelector(`.cell[data-x="${s.x}"][data-y="${s.y}"]`);
        if (cell) cell.classList.add('popping');
      } catch (e) {}
    });

    setTimeout(() => {
      try {
        if (callback) callback();
      } catch (error) {
        ErrorHandler.warn('Popping callback failed', error);
      }
    }, 270);
  } catch (error) {
    ErrorHandler.handle(error, { type: 'animate_popping', cellsCount: cells?.length });
    if (callback) callback();
  }
};

GridManager.prototype.animateGravity = function (removedCells, callback) {
  try {
    if (!this.game.animationEnabled) {
      if (callback) callback();
      return;
    }

    const gridDiv = document.getElementById('grid');
    if (!gridDiv) {
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

    for (let x = 0; x < this.game.GRID_W; x++) {
      const ys = removedMap[x] ? removedMap[x].slice().sort((a, b) => a - b) : [];
      if (!ys.length) continue;

      for (let y = 0; y < this.game.GRID_H; y++) {
        const isRemoved = ys.includes(y);
        if (isRemoved) continue;

        let holesBelow = 0;
        ys.forEach((ry) => {
          if (ry > y) holesBelow++;
        });

        if (holesBelow > 0) {
          try {
            const cell = gridDiv.querySelector(`.cell[data-x="${x}"][data-y="${y}"]`);
            if (cell) {
              cell.style.transition = 'transform 0.25s ease';
              cell.style.transform = `translateY(${holesBelow * 100}%)`;
            }
          } catch (e) {}
        }
      }
    }

    setTimeout(() => {
      try {
        const cells = gridDiv.querySelectorAll('.cell');
        cells.forEach((c) => {
          try {
            c.style.transition = '';
            c.style.transform = '';
          } catch (e) {}
        });
        if (callback) callback();
      } catch (error) {
        ErrorHandler.warn('Gravity cleanup failed', error);
        if (callback) callback();
      }
    }, 260);
  } catch (error) {
    ErrorHandler.handle(error, { type: 'animate_gravity', removedCells: removedCells?.length });
    if (callback) callback();
  }
};
