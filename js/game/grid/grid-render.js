// Grid Render: GridManager prototype methods.

GridManager.prototype.getCellFromPoint = function (clientX, clientY) {
  try {
    // ✅ Проверка на валидность координат
    if (
      typeof clientX !== 'number' ||
      typeof clientY !== 'number' ||
      isNaN(clientX) ||
      isNaN(clientY)
    ) {
      ErrorHandler.debug('Invalid coordinates in getCellFromPoint', { clientX, clientY });
      return null;
    }

    const el = document.elementFromPoint(clientX, clientY);
    if (!el) return null;

    const cell = el.classList.contains('cell') ? el : el.closest('.cell');
    if (!cell) return null;

    const x = parseInt(cell.dataset.x, 10);
    const y = parseInt(cell.dataset.y, 10);

    // ✅ Дополнительная проверка границ
    if (
      isNaN(x) ||
      isNaN(y) ||
      x < 0 ||
      x >= (this.game.GRID_W || 6) ||
      y < 0 ||
      y >= (this.game.GRID_H || 6)
    ) {
      ErrorHandler.debug('Cell coordinates out of bounds', {
        x,
        y,
        GRID_W: this.game.GRID_W,
        GRID_H: this.game.GRID_H,
      });
      return null;
    }

    // ✅ Проверка существования ячейки в гриде
    if (!this.game.grid || !this.game.grid[x] || this.game.grid[x][y] === undefined) {
      ErrorHandler.debug('Cell data not found in grid', { x, y });
      return null;
    }

    return { x, y };
  } catch (error) {
    ErrorHandler.warn('getCellFromPoint failed', { clientX, clientY, error });
    return null;
  }
};

GridManager.prototype.render = function () {
  if (this.isRendering) {
    ErrorHandler.debug('Already rendering, skipping');
    return;
  }

  this.isRendering = true;

  try {
    const gridDiv = document.getElementById('grid');
    if (!gridDiv) {
      ErrorHandler.warn('Grid div not found!');
      this.isRendering = false;
      return;
    }

    const expectedCells = this.game.GRID_W * this.game.GRID_H;
    if (
      gridDiv.childElementCount === expectedCells &&
      gridDiv.querySelectorAll('.cell-inner').length === expectedCells &&
      this.syncGridDOMFromModel()
    ) {
      return;
    }

    this.performFullRender();
  } catch (error) {
    ErrorHandler.handle(error, { type: 'grid_render' });
  } finally {
    this.isRendering = false;
  }
};

GridManager.prototype.performFullRender = function () {
  try {
    const gridDiv = document.getElementById('grid');
    if (!gridDiv) {
      ErrorHandler.warn('Grid div not found for rendering');
      return;
    }

    // Сохраняем текущее состояние выбранных клеток
    const selectedCells = [...(this.game.selected || [])];

    gridDiv.innerHTML = '';

    for (let y = 0; y < this.game.GRID_H; y++) {
      for (let x = 0; x < this.game.GRID_W; x++) {
        let cellData = this.game.grid?.[x]?.[y];

        // Если данные клетки повреждены, создаем новую
        if (!cellData || typeof cellData !== 'object') {
          cellData = {
            number: 2,
            merged: false,
            frozen: false,
            freezeTurns: 0,
            freezeMaxTurns: 0,
          };

          if (this.game.grid && this.game.grid[x]) {
            this.game.grid[x][y] = cellData;
          }
        }

        let num = cellData.number;
        if (num == null) {
          // ✅ В каноне пустота ПОД льдом может быть реальной пустотой.
          // Но в DOM мы всё равно рисуем клетку, просто без числа.
          num = null;
        }

        const cell = document.createElement('div');
        cell.className = 'cell';
        cell.dataset.x = x;
        cell.dataset.y = y;
        cell.dataset.number = num == null ? '' : num;

        const idx = y * this.game.GRID_W + x;

        // ✅ Используем систему заморозки, если она есть
        let isFrozen = false;
        let freezeTurns = 0;
        let freezeMaxTurns = 0;

        if (this.game.freezeSystem) {
          const freezeData = this.game.freezeSystem.getFreezeData?.(idx);
          if (freezeData) {
            isFrozen = true;
            freezeTurns = freezeData.turns;
            freezeMaxTurns = freezeData.maxTurns;

            // ✅ синхронизируем флаг на клетке, чтобы якорная гравитация работала
            cellData.frozen = true;
            cellData.freezeTurns = freezeTurns;
            cellData.freezeMaxTurns = freezeMaxTurns;
            cellData.freezeType = freezeData.type;
          } else {
            // если в системе нет — снимаем флаг (но аккуратно)
            // cellData.frozen = false;  // можно включить, если нужно
          }
        } else {
          // Fallback для обратной совместимости
          isFrozen = this.game.isCellFrozen(idx) || cellData.frozen;
          freezeTurns = this.game.getFrozenTurns(idx) || cellData.freezeTurns || 5;
          freezeMaxTurns = cellData.freezeMaxTurns || 5;
        }

        if (isFrozen || cellData.frozen) {
          cell.classList.add('frozen');

          const t = cellData.freezeTurns || freezeTurns || 1;
          const mt = cellData.freezeMaxTurns || freezeMaxTurns || 1;
          const opacity = Math.max(0.2, Math.min(1, t / Math.max(1, mt)));

          const snowflake = document.createElement('div');
          snowflake.className = 'snowflake';
          snowflake.textContent = '❄️';
          snowflake.style.opacity = opacity;
          cell.appendChild(snowflake);

          const counter = document.createElement('div');
          counter.className = 'freeze-counter';
          counter.textContent = t;
          cell.appendChild(counter);

          if (cellData.freezeType) {
            cell.dataset.freezeType = cellData.freezeType;
          }
        }

        // Проверяем, выбрана ли клетка
        if (selectedCells.some((s) => s.x === x && s.y === y)) {
          cell.classList.add('selected');
        }

        if (cellData.merged) {
          cell.classList.add('merged');
        }

        const inner = document.createElement('div');
        inner.className = 'cell-inner';
        try {
          inner.textContent = num == null ? '' : this.formatCarryVisual(num);
        } catch (error) {
          inner.textContent = num == null ? '' : num?.toString() || '2';
        }
        cell.appendChild(inner);

        gridDiv.appendChild(cell);
      }
    }

    this.renderCount++;

    if (window.AppEnv?.isDev && this.renderCount % 50 === 0) {
      ErrorHandler.debug('Grid rendered', {
        count: this.renderCount,
        cells: this.game.GRID_W * this.game.GRID_H,
        frozenCells: this.game.getFrozenCount(),
      });
    }
  } catch (error) {
    ErrorHandler.handle(error, {
      type: 'full_render',
      gridW: this.game.GRID_W,
      gridH: this.game.GRID_H,
    });
  }
};

GridManager.prototype.formatCarryVisual = function (num) {
  try {
    if (num === this.game.carryNumber) {
      return `✨${this.game.formatNumber?.(num) || num}✨`;
    }
    return this.game.formatNumber?.(num) || num;
  } catch (error) {
    ErrorHandler.warn('formatCarryVisual failed', { num, error });
    return num?.toString() || '2';
  }
};

GridManager.prototype.syncGridDOMFromModel = function () {
  try {
    const gridDiv = document.getElementById('grid');
    if (!gridDiv) return false;

    const W = this.game.GRID_W;
    const H = this.game.GRID_H;
    const expected = W * H;
    const cells = gridDiv.querySelectorAll('.cell');

    if (cells.length !== expected) return false;
    if (gridDiv.querySelectorAll('.cell-inner').length !== expected) return false;

    const selectedCells = [...(this.game.selected || [])];

    for (let y = 0; y < H; y++) {
      for (let x = 0; x < W; x++) {
        const cellEl = gridDiv.querySelector(`.cell[data-x="${x}"][data-y="${y}"]`);
        if (!cellEl) return false;
        if (!this._syncSingleCellDOM(cellEl, x, y, selectedCells)) return false;
      }
    }

    return true;
  } catch (error) {
    ErrorHandler.warn('syncGridDOMFromModel failed', { error });
    return false;
  }
};

/** After model updates (merge, gravity): avoid rebuilding the whole grid if DOM is intact. */
GridManager.prototype.preferSyncOrFullRender = function () {
  if (this.syncGridDOMFromModel()) return;
  this.performFullRender();
};

GridManager.prototype._syncSingleCellDOM = function (cellEl, x, y, selectedCells) {
  try {
    let cellData = this.game.grid?.[x]?.[y];

    if (!cellData || typeof cellData !== 'object') {
      cellData = {
        number: 2,
        merged: false,
        frozen: false,
        freezeTurns: 0,
        freezeMaxTurns: 0,
      };

      if (this.game.grid && this.game.grid[x]) {
        this.game.grid[x][y] = cellData;
      }
    }

    let num = cellData.number;
    if (num == null) {
      num = null;
    }

    cellEl.dataset.number = num == null ? '' : num;

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

        cellData.frozen = true;
        cellData.freezeTurns = freezeTurns;
        cellData.freezeMaxTurns = freezeMaxTurns;
        cellData.freezeType = freezeData.type;
      }
    } else {
      isFrozen = this.game.isCellFrozen(idx) || cellData.frozen;
      freezeTurns = this.game.getFrozenTurns(idx) || cellData.freezeTurns || 5;
      freezeMaxTurns = cellData.freezeMaxTurns || 5;
    }

    const showFreeze = !!(isFrozen || cellData.frozen);

    cellEl.classList.toggle('frozen', showFreeze);
    cellEl.querySelectorAll('.snowflake, .freeze-counter').forEach((el) => el.remove());

    if (showFreeze) {
      const t = cellData.freezeTurns || freezeTurns || 1;
      const mt = cellData.freezeMaxTurns || freezeMaxTurns || 1;
      const opacity = Math.max(0.2, Math.min(1, t / Math.max(1, mt)));

      const snowflake = document.createElement('div');
      snowflake.className = 'snowflake';
      snowflake.textContent = '❄️';
      snowflake.style.opacity = String(opacity);

      const counter = document.createElement('div');
      counter.className = 'freeze-counter';
      counter.textContent = String(t);

      const innerBefore = cellEl.querySelector('.cell-inner');
      if (innerBefore) {
        cellEl.insertBefore(snowflake, innerBefore);
        cellEl.insertBefore(counter, innerBefore);
      } else {
        cellEl.appendChild(snowflake);
        cellEl.appendChild(counter);
      }

      if (cellData.freezeType) {
        cellEl.dataset.freezeType = cellData.freezeType;
      } else {
        delete cellEl.dataset.freezeType;
      }
    } else {
      delete cellEl.dataset.freezeType;
    }

    const isSel = selectedCells.some((s) => s.x === x && s.y === y);
    cellEl.classList.toggle('selected', isSel);
    if (!isSel) {
      cellEl.classList.remove('chain-preview-valid', 'chain-preview-invalid');
    }
    cellEl.classList.toggle('merged', !!cellData.merged);

    let inner = cellEl.querySelector('.cell-inner');
    if (!inner) {
      inner = document.createElement('div');
      inner.className = 'cell-inner';
      cellEl.appendChild(inner);
    }
    inner.textContent = num == null ? '' : this.formatCarryVisual(num);

    return true;
  } catch (error) {
    ErrorHandler.warn('_syncSingleCellDOM failed', { x, y, error });
    return false;
  }
};
