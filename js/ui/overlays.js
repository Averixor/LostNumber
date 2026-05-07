class OverlayManager {
  constructor(game) {
    this.game = game;
  }

  setupOverlays() {
    document.getElementById('levelNextBtn')?.addEventListener('click', () => {
      document.getElementById('levelOverlay').classList.add('hidden');
      this.game.completeLevelTransition();
    });

    document.getElementById('levelMenuBtn')?.addEventListener('click', () => {
      this.game.saveGameState();
      this.game.setGamePhase('blocked');
      document.getElementById('levelOverlay').classList.add('hidden');
      this.game.screenManager.showScreen('mainMenu');
    });

    document.getElementById('playAgainBtn')?.addEventListener('click', () => {
      this.game.audioManager.playTap();
      this.hideVictory();
      this.game.startNewGame();
    });

    document.getElementById('backToMenuBtn')?.addEventListener('click', () => {
      this.game.audioManager.playTap();
      this.hideVictory();
      this.game.screenManager.showScreen('mainMenu');
    });

    document.getElementById('wheelCloseBtn')?.addEventListener('click', () => {
      this.game.audioManager.playTap();
      this.game.wheelManager.closeWheel();
    });

    document.getElementById('spinWheelBtn')?.addEventListener('click', () => {
      this.game.audioManager.playTap();
      this.game.wheelManager.spinWheel();
    });
  }

  showVictory() {
    const overlay = document.getElementById('victoryOverlay');
    if (overlay) overlay.classList.remove('hidden');
  }

  hideVictory() {
    const overlay = document.getElementById('victoryOverlay');
    if (overlay) overlay.classList.add('hidden');
  }

  updatePreviewBubble() {
    const bubble = document.getElementById('previewBubble');
    if (!bubble) return;

    bubble.textContent = this.game.formatNumber(Chain.sum);

    if (!this.game.selected || this.game.selected.length === 0) {
      bubble.style.opacity = '0';
      bubble.classList.remove('valid', 'invalid');
      bubble.classList.remove('valid-sum');
      return;
    }

    const first = Chain.numbers[0];
    const sum = Chain.sum;

    const canFinish = this.game.core.canFinishChain(Chain);

    bubble.classList.remove('valid', 'invalid', 'valid-sum');

    if (canFinish) {
      bubble.classList.add('valid');
      bubble.classList.add('valid-sum');
    } else if (Chain.numbers.length >= 2) {
      bubble.classList.add('invalid');
    }

    bubble.style.opacity = '1';

    const container = document.querySelector('#gameScreen .grid-container');
    const grid = document.getElementById('grid');
    if (!container || !grid) return;

    const containerRect = container.getBoundingClientRect();
    const gridRect = grid.getBoundingClientRect();

    const cellW = gridRect.width / this.game.GRID_W;
    const cellH = gridRect.height / this.game.GRID_H;

    const anchor = this.game.selected[this.game.selected.length - 1];

    const x = gridRect.left - containerRect.left + (anchor.x + 0.5) * cellW;

    const y = gridRect.top - containerRect.top + anchor.y * cellH - cellH;

    bubble.style.left = x + 'px';
    bubble.style.top = y + 'px';

    // ВАЖНО: Не вызываем gridManager.render() здесь!
    // Вместо этого обновим только состояние selected клеток
    this.updateSelectedCells();
  }

  // НОВЫЙ МЕТОД: Обновить только состояние selected клеток
  updateSelectedCells() {
    const gridDiv = document.getElementById('grid');
    if (!gridDiv) return;

    const cells = gridDiv.querySelectorAll('.cell');
    cells.forEach((cell) => {
      const x = parseInt(cell.dataset.x);
      const y = parseInt(cell.dataset.y);
      const shouldBeSelected = this.game.selected.some((s) => s.x === x && s.y === y);

      if (shouldBeSelected) {
        cell.classList.add('selected');
      } else {
        cell.classList.remove('selected');
      }
    });
  }

  // В overlays.js в класс OverlayManager добавьте:
  clearSelectionHighlight(selectedCells) {
    const gridDiv = document.getElementById('grid');
    if (!gridDiv) return;

    selectedCells.forEach((cell) => {
      const cellEl = gridDiv.querySelector(`.cell[data-x="${cell.x}"][data-y="${cell.y}"]`);
      if (cellEl) {
        cellEl.classList.remove('selected');
      }
    });
  }

  hidePreviewBubble() {
    const bubble = document.getElementById('previewBubble');
    if (!bubble) return;
    bubble.style.opacity = '0';
    bubble.classList.remove('valid', 'invalid', 'valid-sum');
  }

  showMessage(text) {
    const container = document.querySelector('#gameScreen .grid-container');
    if (!container) return;

    let toast = container.querySelector('.system-toast');
    if (!toast) {
      toast = document.createElement('div');
      toast.className = 'system-toast';
      container.appendChild(toast);
    }

    toast.textContent = String(text ?? '');
    toast.classList.add('show');

    clearTimeout(this.game._toastTimer);
    this.game._toastTimer = setTimeout(() => {
      toast.classList.remove('show');
    }, 2200);
  }
}
