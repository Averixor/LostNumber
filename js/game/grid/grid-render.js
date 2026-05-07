// Grid Render: GridManager prototype methods.

GridManager.prototype.getCellFromPoint = function (clientX, clientY) {
  try {
    // ✅ Проверка на валидность координат
    if (typeof clientX !== 'number' || typeof clientY !== 'number' || isNaN(clientX) || isNaN(clientY)) {
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
    if (isNaN(x) || isNaN(y) || x < 0 || x >= (this.game.GRID_W || 6) || y < 0 || y >= (this.game.GRID_H || 6)) {
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
          isFrozen = this.game.frozenCells?.has(idx) || cellData.frozen;
          freezeTurns = this.game.frozenCells?.get(idx) || cellData.freezeTurns || 5;
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
        frozenCells: this.game.freezeSystem
          ? this.game.freezeSystem.getStats().currentlyFrozen
          : this.game.frozenCells?.size || 0,
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
