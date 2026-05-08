// Ui Events: LostNumberGame prototype methods.

LostNumberGame.prototype.ensureGridEventListeners = function () {
  try {
    const grid = document.getElementById('grid');
    if (!grid) return;

    // Проверяем есть ли уже обработчики
    const hasListeners = grid._listenersAttached || false;

    if (!hasListeners) {
      // Привязываем обработчики
      const onDown = (e) => this.handlePointerDown(e);
      const onMove = (e) => this.handlePointerMove(e);
      const onUp = (e) => this.handlePointerUp(e);

      grid.addEventListener('pointerdown', onDown, { passive: false });
      grid.addEventListener('pointermove', onMove, { passive: false });
      grid.addEventListener('pointerup', onUp, { passive: false });
      grid.addEventListener('pointercancel', onUp, { passive: false });

      // сохраняем ссылки (на всякий)
      grid._lnHandlers = { onDown, onMove, onUp };

      // Помечаем что обработчики привязаны
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
      this.setGamePhase('blocked');
      // АВТОСОХРАНЕНИЕ ПРИ ВЫХОДЕ В ГЛАВНОЕ МЕНЮ
      this.saveGameState();
      this.showScreen('mainMenu');
    });

    const footerSoundBtn = document.getElementById('footerSoundBtn');
    bindClickOnce(footerSoundBtn, () => {
      this.audioManager.playTap();
      this.soundEnabled = !this.soundEnabled;
      this.audioManager.setSoundEnabled(this.soundEnabled);
      this.audioManager.updateSoundStateUI();
      this.saveSettings(); // Сохраняем только настройки
    });

    const footerSaveBtn = document.getElementById('footerSaveBtn');
    bindClickOnce(footerSaveBtn, () => {
      this.audioManager.playTap();
      this.saveGameState();
      this.showMessage(this.t('save_done'));
    });

    // ВАЖНОЕ ИСПРАВЛЕНИЕ: Привязываем обработчики grid
    this.ensureGridEventListeners();
  } catch (error) {
    ErrorHandler.handle(error, { type: 'ui_setup' });
  }
};

LostNumberGame.prototype.handlePointerDown = function (e) {
  try {
    if (this.gamePhase !== 'playing') return;

    const posCell = this.gridManager.getCellFromPoint(e.clientX, e.clientY);
    if (!posCell) return;

    const idx = posCell.y * this.GRID_W + posCell.x;
    if (this.isCellFrozen(idx)) {
      this.showMessage(this.t('cell_frozen'));
      return;
    }

    if (this.activeBonus === 'destroy') {
      if (this.getBonusCount('destroy') <= 0) {
        this.showMessage(this.t('no_bonus'));
        return;
      }
      this.bonusManager.useDestroyBonus(posCell.x, posCell.y);
      return;
    }
    if (this.activeBonus === 'explosion') {
      if (this.getBonusCount('explosion') <= 0) {
        this.showMessage(this.t('no_bonus'));
        return;
      }
      this.bonusManager.useExplosionBonus(posCell.x, posCell.y);
      return;
    }

    this.isDragging = true;
    this.selected = [posCell];
    Chain.numbers = [this.grid[posCell.x][posCell.y].number];
    updateChainSum();
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
    e.preventDefault();

    const posCell = this.gridManager.getCellFromPoint(e.clientX, e.clientY);
    if (!posCell) return;

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

    this._schedulePreviewBubbleUpdate?.();
    this._applySelectionHighlight?.(null, posCell);
  } catch (error) {
    ErrorHandler.handle(error, { type: 'pointer_move', clientX: e.clientX, clientY: e.clientY });
  }
};

LostNumberGame.prototype.handlePointerUp = function (e) {
  try {
    if (!this.isDragging) return;
    this.isDragging = false;
    this.hidePreviewBubble();

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
        cellEl.classList.remove('selected');
      }
    });
  } catch (error) {
    ErrorHandler.warn('clearSelectionHighlight failed', error);
  }
};

LostNumberGame.prototype.resetChain = function (reason = null) {
  try {
    this.isDragging = false;

    // HARD RESET визуала
    document
      .querySelectorAll('.cell.selected, .cell.highlight')
      .forEach((el) => el.classList.remove('selected', 'highlight'));

    const oldSelected = [...this.selected];
    this.selected = [];
    Chain.numbers = [];
    Chain.sum = 0;

    this.hidePreviewBubble();

    // Очищаем подсветку в DOM
    this.clearSelectionHighlight(oldSelected);

    if (reason === 'invalid') {
      // ИСПРАВЛЕНИЕ: проверяем наличие метода playError или playSound
      if (this.audioManager) {
        if (typeof this.audioManager.playError === 'function') {
          this.audioManager.playError();
        } else if (typeof this.audioManager.playSound === 'function') {
          this.audioManager.playSound('error');
        } else if (typeof this.audioManager.playTap === 'function') {
          this.audioManager.playTap(); // fallback на tap звук
        }
      }
      this.showMessage(this.t('chain_invalid'));
    }

    // На мобільних повний re-render тут дорогий і не потрібен:
    // ми вже очистили selected/highlight в DOM вище.
  } catch (error) {
    ErrorHandler.handle(error, { type: 'reset_chain', reason });
  }
};

/** rAF-throttled: зменшує виклики updatePreviewBubble під час pointermove (до 1 на кадр). */
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

/** Миттєва підсвітка клітинок без повного scan гріда в updateSelectedCells (дешевше на move). */
LostNumberGame.prototype._applySelectionHighlight = function (removed, added) {
  try {
    const gridDiv = document.getElementById('grid');
    if (!gridDiv) return;
    if (removed && typeof removed.x === 'number' && typeof removed.y === 'number') {
      const el = gridDiv.querySelector(`.cell[data-x="${removed.x}"][data-y="${removed.y}"]`);
      if (el) el.classList.remove('selected');
    }
    if (added && typeof added.x === 'number' && typeof added.y === 'number') {
      const el = gridDiv.querySelector(`.cell[data-x="${added.x}"][data-y="${added.y}"]`);
      if (el) el.classList.add('selected');
    }
  } catch (error) {
    ErrorHandler.warn('_applySelectionHighlight failed', error);
  }
};
