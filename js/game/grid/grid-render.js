GridManager.prototype._findLargestTilePosition = function () {
  const W = this.game.GRID_W;
  const H = this.game.GRID_H;
  let maxNum = -Infinity;
  let position = null;

  for (let y = 0; y < H; y++) {
    for (let x = 0; x < W; x++) {
      const num = this.game.grid?.[x]?.[y]?.number;
      if (num == null || !Number.isFinite(Number(num))) continue;
      if (num > maxNum) {
        maxNum = num;
        position = { x, y };
      }
    }
  }

  return position;
};

GridManager.prototype._updateLargestTileMarkers = function () {
  const W = this.game.GRID_W;
  const H = this.game.GRID_H;
  const largest = this._findLargestTilePosition();

  if (!this.cellCache || this.cellCache.length !== W) return;

  for (let x = 0; x < W; x++) {
    if (!this.cellCache[x] || this.cellCache[x].length !== H) return;
    for (let y = 0; y < H; y++) {
      const cellEl = this.cellCache[x][y];
      if (!cellEl) continue;

      const isLargest = !!(largest && largest.x === x && largest.y === y);
      cellEl.classList.toggle('tile--largest', isLargest);

      let crown = cellEl.querySelector('.tile-crown');
      if (isLargest) {
        if (!crown) {
          crown = document.createElement('img');
          crown.className = 'tile-crown';
          crown.src = 'assets/icons/neon/icons/tile-crown.svg';
          crown.alt = '';
          crown.setAttribute?.('aria-hidden', 'true');
          crown.draggable = false;
          cellEl.appendChild(crown);
        }
      } else if (crown) {
        crown.remove();
      }
    }
  }
};

GridManager.prototype._applyCellDisplayClasses = function (cell, num) {
  const readable = num != null && num >= 8192;
  const compact = num != null && num >= 1024;
  cell.classList.toggle('cell-value-readable', readable);
  cell.classList.toggle('cell-value-compact', compact);
};

GridManager.prototype.getCellFromPoint = function (clientX, clientY) {
  try {
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

    if (
      isNaN(x) ||
      isNaN(y) ||
      x < 0 ||
      x >= (this.game.GRID_W || 5) ||
      y < 0 ||
      y >= (this.game.GRID_H || 8)
    ) {
      return null;
    }

    return { x, y };
  } catch (error) {
    ErrorHandler.warn('getCellFromPoint failed', { clientX, clientY, error });
    return null;
  }
};

GridManager.prototype.render = function () {
  if (this.isRendering) return;
  this.isRendering = true;

  try {
    const gridDiv = document.getElementById('grid');
    if (!gridDiv) {
      this.isRendering = false;
      return;
    }

    const expectedCells = this.game.GRID_W * this.game.GRID_H;
    const cacheValid =
      this.cellCache &&
      this.cellCache.length === this.game.GRID_W &&
      this.cellCache[0]?.length === this.game.GRID_H;

    if (cacheValid && gridDiv.childElementCount === expectedCells && this.syncGridDOMFromModel()) {
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
    if (!gridDiv) return;

    const selectedCells = [...(this.game.selected || [])];
    gridDiv.innerHTML = '';
    this.cellCache = [];

    for (let x = 0; x < this.game.GRID_W; x++) {
      this.cellCache[x] = [];
    }

    const fragment = document.createDocumentFragment();

    for (let y = 0; y < this.game.GRID_H; y++) {
      for (let x = 0; x < this.game.GRID_W; x++) {
        let cellData = this.game.grid?.[x]?.[y];

        if (!cellData || typeof cellData !== 'object') {
          cellData = {
            number: null,
            merged: false,
            frozen: false,
            freezeTurns: 0,
            freezeMaxTurns: 0,
          };
          if (this.game.grid && this.game.grid[x]) {
            this.game.grid[x][y] = cellData;
          }
        }

        const num = cellData.number;
        const cell = document.createElement('div');
        cell.className = 'cell';
        cell.dataset.x = x.toString();
        cell.dataset.y = y.toString();
        cell.dataset.number = num == null ? '' : num.toString();
        this._applyCellDisplayClasses(cell, num);

        const inner = document.createElement('div');
        inner.className = 'cell-inner';
        if (num === this.game.carryNumber) {
          inner.classList.add('carry-special');
        }
        inner.textContent = num == null ? '' : this.formatCarryVisual(num);
        cell.appendChild(inner);

        this._updateFrozenVisuals(cell, cellData, x, y);

        if (selectedCells.some((s) => s.x === x && s.y === y)) {
          cell.classList.add('selected');
        }

        if (cellData.merged) {
          cell.classList.add('merged');
        }

        this.cellCache[x][y] = cell;
        fragment.appendChild(cell);
      }
    }

    gridDiv.appendChild(fragment);
    this._updateLargestTileMarkers();
    this.renderCount++;
  } catch (error) {
    ErrorHandler.handle(error, {
      type: 'full_render',
      gridW: this.game.GRID_W,
      gridH: this.game.GRID_H,
    });
  }
};

GridManager.prototype._updateFrozenVisuals = function (cellEl, cellData, x, y) {
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
      cellData.freezeType = freezeData.type;
    }
  } else {
    isFrozen = this.game.isCellFrozen(idx) || cellData.frozen;
    freezeTurns = this.game.getFrozenTurns(idx) || cellData.freezeTurns || 5;
    freezeMaxTurns = cellData.freezeMaxTurns || 5;
  }

  const showFreeze = !!(isFrozen || cellData.frozen);
  cellEl.classList.toggle('frozen', showFreeze);

  let snowflake = cellEl.querySelector('.snowflake');
  let counter = cellEl.querySelector('.freeze-counter');

  if (showFreeze) {
    const t = cellData.freezeTurns || freezeTurns || 1;
    const mt = cellData.freezeMaxTurns || freezeMaxTurns || 1;
    const opacity = Math.max(0.2, Math.min(1, t / Math.max(1, mt)));

    if (!snowflake) {
      snowflake = document.createElement('div');
      snowflake.className = 'snowflake';
      const slot = document.createElement('span');
      slot.className = 'freeze-icon-slot';
      slot.setAttribute('data-ln-icon', 'lock');
      snowflake.appendChild(slot);
      cellEl.insertBefore(snowflake, cellEl.firstChild);
      if (typeof LostNumberIcons !== 'undefined') {
        LostNumberIcons.mount(slot, 'lock');
      }
    }
    snowflake.style.opacity = String(opacity);

    if (!counter) {
      counter = document.createElement('div');
      counter.className = 'freeze-counter';
      cellEl.insertBefore(counter, cellEl.firstChild);
    }
    counter.textContent = String(t);

    if (cellData.freezeType) {
      cellEl.dataset.freezeType = cellData.freezeType;
    } else {
      delete cellEl.dataset.freezeType;
    }
  } else {
    if (snowflake) snowflake.remove();
    if (counter) counter.remove();
    delete cellEl.dataset.freezeType;
  }
};

GridManager.prototype.syncGridDOMFromModel = function () {
  try {
    const W = this.game.GRID_W;
    const H = this.game.GRID_H;

    if (!this.cellCache || this.cellCache.length !== W) return false;

    const selectedCells = [...(this.game.selected || [])];

    for (let x = 0; x < W; x++) {
      if (!this.cellCache[x] || this.cellCache[x].length !== H) return false;
      for (let y = 0; y < H; y++) {
        const cellEl = this.cellCache[x][y];
        if (!cellEl) return false;
        this._syncSingleCellDOM(cellEl, x, y, selectedCells);
      }
    }

    this._updateLargestTileMarkers();
    return true;
  } catch (error) {
    ErrorHandler.warn('syncGridDOMFromModel failed', { error });
    return false;
  }
};

GridManager.prototype.preferSyncOrFullRender = function () {
  if (this.syncGridDOMFromModel()) return;
  this.performFullRender();
};

GridManager.prototype._syncSingleCellDOM = function (cellEl, x, y, selectedCells) {
  try {
    let cellData = this.game.grid?.[x]?.[y];

    if (!cellData || typeof cellData !== 'object') {
      cellData = {
        number: null,
        merged: false,
        frozen: false,
        freezeTurns: 0,
        freezeMaxTurns: 0,
      };
    }

    const num = cellData.number;
    const numStr = num == null || num === undefined ? '' : num.toString();

    cellEl.classList.remove('popping', 'carry');
    cellEl.style.transform = '';
    cellEl.style.transition = '';
    cellEl.style.willChange = '';

    if (cellEl.dataset.number !== numStr) {
      cellEl.dataset.number = numStr;
      this._applyCellDisplayClasses(cellEl, num);

      const inner = cellEl.querySelector('.cell-inner');
      if (inner) {
        inner.textContent = num == null ? '' : this.formatCarryVisual(num);
        inner.classList.toggle('carry-special', num === this.game.carryNumber);
      }
    }

    this._updateFrozenVisuals(cellEl, cellData, x, y);

    const isSel = selectedCells.some((s) => s.x === x && s.y === y);
    cellEl.classList.toggle('selected', isSel);
    if (!isSel) {
      cellEl.classList.remove('chain-preview-valid', 'chain-preview-invalid');
    }
    cellEl.classList.toggle('merged', !!cellData.merged);

    return true;
  } catch (error) {
    ErrorHandler.warn('_syncSingleCellDOM failed', { x, y, error });
    return false;
  }
};

GridManager.prototype.formatCarryVisual = function (num) {
  try {
    return this.game.formatNumber?.(num) || num;
  } catch (error) {
    return num?.toString() || '2';
  }
};
