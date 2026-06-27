LostNumberGame.prototype.ensureGridEventListeners = function () {
  try {
    const grid = document.getElementById('grid');
    if (!grid) return;

    const hasListeners = grid._listenersAttached || false;

    if (!hasListeners) {
      const onDown = (e) => this.handlePointerDown(e);
      const onMove = (e) => this.handlePointerMove(e);
      const onUp = (e) => this.handlePointerUp(e);
      const onCancel = (e) => this.handlePointerCancel(e);
      const onLeave = (e) => this.handleGridPointerLeave(e);

      grid.addEventListener('pointerdown', onDown, { passive: false });
      grid.addEventListener('pointermove', onMove, { passive: false });
      grid.addEventListener('pointerup', onUp, { passive: false });
      grid.addEventListener('pointercancel', onCancel, { passive: false });
      grid.addEventListener('pointerleave', onLeave, { passive: true });

      grid._lnHandlers = { onDown, onMove, onUp, onCancel, onLeave };

      grid._listenersAttached = true;
    }
  } catch (error) {
    ErrorHandler.handle(error, { type: 'ui_setup', method: 'ensureGridEventListeners' });
  }
};

LostNumberGame.prototype.setupUI = function () {
  try {
    this.menuManager.setupMainMenu();
    this.settingsManager.setupSettings();
    this.overlayManager.setupOverlays();

    const bindClickOnce = (element, handler) => {
      if (!element) return;
      if (element._lnClickBound) return;
      element.addEventListener('click', handler);
      element._lnClickBound = true;
    };

    const bonusWheelBtn = document.getElementById('bonus-wheel');
    bindClickOnce(bonusWheelBtn, () => {
      this.audioManager.playTap();
      this.wheelManager.handleWheel();
    });

    const bonusDestroyBtn = document.getElementById('bonus-destroy');
    bindClickOnce(bonusDestroyBtn, () => {
      this.audioManager.playTap();
      this.bonusManager.activateBonus('destroy');
    });

    const bonusShuffleBtn = document.getElementById('bonus-shuffle');
    bindClickOnce(bonusShuffleBtn, () => {
      this.audioManager.playTap();
      this.bonusManager.activateBonus('shuffle');
    });

    const bonusExplosionBtn = document.getElementById('bonus-explosion');
    bindClickOnce(bonusExplosionBtn, () => {
      this.audioManager.playTap();
      this.bonusManager.activateBonus('explosion');
    });

    const footerHomeBtn = document.getElementById('footerHomeBtn');
    bindClickOnce(footerHomeBtn, () => {
      this.audioManager.playTap();
      this.requestSaveAndExitToMenu();
    });

    const footerSoundBtn = document.getElementById('footerSoundBtn');
    bindClickOnce(footerSoundBtn, () => {
      this.audioManager.playTap();
      this.soundEnabled = !this.soundEnabled;
      this.audioManager.setSoundEnabled(this.soundEnabled);
      this.audioManager.updateSoundStateUI();
      this.saveSettings();
    });

    const footerSaveBtn = document.getElementById('footerSaveBtn');
    bindClickOnce(footerSaveBtn, () => {
      this.audioManager.playTap();
      this.requestSaveGameState({ showToast: true });
    });

    this.ensureGridEventListeners();
  } catch (error) {
    ErrorHandler.handle(error, { type: 'ui_setup' });
  }
};

LostNumberGame.prototype.canAcceptGridInput = function () {
  return this.gamePhase === 'playing';
};

LostNumberGame.prototype.handlePointerDown = function (e) {
  try {
    if (!this.canAcceptGridInput()) return;

    const posCell = this.gridManager.getCellFromPoint(e.clientX, e.clientY);
    if (!posCell) return;

    const idx = posCell.y * this.GRID_W + posCell.x;
    if (this.isCellFrozen(idx)) {
      this.audioManager?.playError?.();
      this.showMessage(this.t('cell_frozen'));
      return;
    }

    if (this.activeBonus === 'destroy') {
      if (this.getBonusCount('destroy') <= 0) {
        this.audioManager?.playError?.();
        this.showMessage(this.t('no_bonus'));
        return;
      }
      this.bonusManager.useDestroyBonus(posCell.x, posCell.y);
      return;
    }
    if (this.activeBonus === 'explosion') {
      if (this.getBonusCount('explosion') <= 0) {
        this.audioManager?.playError?.();
        this.showMessage(this.t('no_bonus'));
        return;
      }
      this.bonusManager.useExplosionBonus(posCell.x, posCell.y);
      return;
    }

    const cellNumber = this.grid?.[posCell.x]?.[posCell.y]?.number;
    if (cellNumber == null || !Number.isFinite(Number(cellNumber))) {
      return;
    }

    this.isDragging = true;
    this._bubblePointerX = e.clientX;
    this._bubblePointerY = e.clientY;
    const grid = document.getElementById('grid');
    if (grid && typeof grid.setPointerCapture === 'function') {
      try {
        grid.setPointerCapture(e.pointerId);
      } catch (_) {}
    }
    this.selected = [posCell];
    Chain.numbers = [cellNumber];
    updateChainSum();
    this.audioManager?.playChainLink?.();
    this._applySelectionHighlight?.(null, posCell);
    try {
      this.updatePreviewBubble();
    } catch (e) {
      ErrorHandler.warn('updatePreviewBubble on pointerdown failed', e);
    }
  } catch (error) {
    ErrorHandler.handle(error, { type: 'pointer_down', clientX: e.clientX, clientY: e.clientY });
  }
};

LostNumberGame.prototype.handlePointerMove = function (e) {
  try {
    if (!this.isDragging || this.activeBonus) return;

    if (!this.canAcceptGridInput()) {
      this.resetChain();
      return;
    }

    this._bubblePointerX = e.clientX;
    this._bubblePointerY = e.clientY;
    e.preventDefault();

    const posCell = this.gridManager.getCellFromPoint(e.clientX, e.clientY);
    if (!posCell) {
      this._releaseGridPointerCapture(e);
      this.resetChain();
      return;
    }

    const idx = posCell.y * this.GRID_W + posCell.x;
    if (this.isCellFrozen(idx)) return;

    const len = this.selected.length;
    if (len === 0) return;

    if (len >= 2) {
      const prev = this.selected[len - 2];
      if (prev.x === posCell.x && prev.y === posCell.y) {
        const removed = this.selected.pop();
        Chain.numbers.pop();
        updateChainSum();
        this._schedulePreviewBubbleUpdate?.();
        if (removed) this._applySelectionHighlight?.(removed, null);
        return;
      }
    }

    if (this.selected.some((s) => s.x === posCell.x && s.y === posCell.y)) {
      return;
    }

    const last = this.selected[len - 1];
    if (!this.core.isAdjacent(last, posCell)) return;

    const newNum = this.grid[posCell.x][posCell.y].number;
    const prevNum = Chain.numbers[Chain.numbers.length - 1];
    const currentSum = Chain.sum;

    if (!this.core.isValidNextNumber(newNum, prevNum, currentSum)) return;

    this.selected.push(posCell);
    Chain.numbers.push(newNum);
    updateChainSum();
    this.audioManager?.playChainLink?.();

    this._schedulePreviewBubbleUpdate?.();
    this._applySelectionHighlight?.(null, posCell);
  } catch (error) {
    ErrorHandler.handle(error, { type: 'pointer_move', clientX: e.clientX, clientY: e.clientY });
  }
};

LostNumberGame.prototype._releaseGridPointerCapture = function (e) {
  const grid = document.getElementById('grid');
  if (!grid || !e || e.pointerId == null) return;
  try {
    if (typeof grid.hasPointerCapture === 'function' && grid.hasPointerCapture(e.pointerId)) {
      grid.releasePointerCapture(e.pointerId);
    }
  } catch (_) {}
};

LostNumberGame.prototype.handlePointerCancel = function (e) {
  try {
    if (!this.isDragging) return;
    this._releaseGridPointerCapture(e);
    this.resetChain();
  } catch (error) {
    ErrorHandler.handle(error, { type: 'pointer_cancel' });
  }
};

LostNumberGame.prototype.handleGridPointerLeave = function (e) {
  try {
    if (!this.isDragging || this.activeBonus) return;
    this._releaseGridPointerCapture(e);
    this.resetChain();
  } catch (error) {
    ErrorHandler.handle(error, { type: 'pointer_leave' });
  }
};

LostNumberGame.prototype.handlePointerUp = function (e) {
  try {
    if (!this.isDragging) return;

    if (!this.canAcceptGridInput()) {
      this._releaseGridPointerCapture(e);
      this.resetChain();
      return;
    }

    this.isDragging = false;
    this._bubblePointerX = null;
    this._bubblePointerY = null;
    this.hidePreviewBubble();
    this._releaseGridPointerCapture(e);

    const posCell = this.gridManager.getCellFromPoint(e.clientX, e.clientY);
    if (!posCell) {
      this.resetChain();
      return;
    }

    if (this.core.canFinishChain(Chain)) {
      this.mergeChain();
    } else {
      this.resetChain('invalid');
    }
  } catch (error) {
    ErrorHandler.handle(error, { type: 'pointer_up' });
  }
};

LostNumberGame.prototype.clearSelectionHighlight = function (selectedCells) {
  try {
    const gridDiv = document.getElementById('grid');
    if (!gridDiv) return;

    selectedCells.forEach((cell) => {
      const cellEl = gridDiv.querySelector(`.cell[data-x="${cell.x}"][data-y="${cell.y}"]`);
      if (cellEl) {
        cellEl.classList.remove('selected', 'chain-preview-valid', 'chain-preview-invalid');
      }
    });
  } catch (error) {
    ErrorHandler.warn('clearSelectionHighlight failed', error);
  }
};

LostNumberGame.prototype.resetChain = function (reason = null) {
  try {
    this.isDragging = false;
    this._bubblePointerX = null;
    this._bubblePointerY = null;

    document
      .querySelectorAll('.cell.selected, .cell.highlight')
      .forEach((el) => el.classList.remove('selected', 'highlight'));

    const oldSelected = [...this.selected];
    this.selected = [];
    Chain.numbers = [];
    Chain.sum = 0;

    this.hidePreviewBubble();

    this.clearSelectionHighlight(oldSelected);

    if (reason === 'invalid') {
      if (this.audioManager) {
        if (typeof this.audioManager.playError === 'function') {
          this.audioManager.playError();
        }
      }
      this.showMessage(this.t('chain_invalid'));
    }
  } catch (error) {
    ErrorHandler.handle(error, { type: 'reset_chain', reason });
  }
};

LostNumberGame.prototype._schedulePreviewBubbleUpdate = function () {
  try {
    if (this._previewBubbleRaf) return;
    this._previewBubbleRaf = requestAnimationFrame(() => {
      this._previewBubbleRaf = 0;
      try {
        this.updatePreviewBubble();
      } catch (e) {
        ErrorHandler.warn('updatePreviewBubble in rAF failed', e);
      }
    });
  } catch (error) {
    ErrorHandler.warn('_schedulePreviewBubbleUpdate failed', error);
  }
};

LostNumberGame.prototype._applySelectionHighlight = function (removed, added) {
  try {
    const gridDiv = document.getElementById('grid');
    if (!gridDiv) return;
    if (removed && typeof removed.x === 'number' && typeof removed.y === 'number') {
      const el = gridDiv.querySelector(`.cell[data-x="${removed.x}"][data-y="${removed.y}"]`);
      if (el) el.classList.remove('selected', 'chain-preview-valid', 'chain-preview-invalid');
    }
    if (added && typeof added.x === 'number' && typeof added.y === 'number') {
      const el = gridDiv.querySelector(`.cell[data-x="${added.x}"][data-y="${added.y}"]`);
      if (el) el.classList.add('selected');
    }
  } catch (error) {
    ErrorHandler.warn('_applySelectionHighlight failed', error);
  }
};
