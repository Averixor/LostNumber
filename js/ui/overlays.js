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

    const gridOffsetX = gridRect.left - containerRect.left;
    const gridOffsetY = gridRect.top - containerRect.top;

    const cellW = gridRect.width / this.game.GRID_W;
    const cellH = gridRect.height / this.game.GRID_H;

    const anchor = this.game.selected[this.game.selected.length - 1];

    const xCenter = gridOffsetX + (anchor.x + 0.5) * cellW;

    const gap = 8;
    const minY = gap;
    const maxBottom = containerRect.height - gap;
    const yAbove = gridOffsetY + anchor.y * cellH - cellH - gap;
    const yBelow = gridOffsetY + (anchor.y + 1) * cellH + gap;

    bubble.style.left = `${xCenter}px`;
    bubble.style.top = `${yAbove}px`;

    const bubbleH = bubble.offsetHeight || 44;
    const bubbleW = bubble.offsetWidth || 72;

    let y = yAbove;
    if (y < minY || y + bubbleH > maxBottom) {
      y = yBelow;
    }
    if (y + bubbleH > maxBottom) {
      y = Math.max(minY, maxBottom - bubbleH);
    }
    if (y < minY) {
      y = minY;
    }

    bubble.style.top = `${y}px`;

    const halfW = bubbleW / 2;
    const minX = halfW + gap;
    const maxX = containerRect.width - halfW - gap;
    if (maxX > minX) {
      const clampedX = Math.max(minX, Math.min(maxX, xCenter));
      bubble.style.left = `${clampedX}px`;
    }

    // ВАЖНО: Не вызываем gridManager.render() здесь!
    // Вместо этого обновим только состояние selected клеток
    this.updateSelectedCells();
  }

  // НОВЫЙ МЕТОД: Обновить только состояние selected клеток
  updateSelectedCells() {
    const gridDiv = document.getElementById('grid');
    if (!gridDiv) return;

    const selected = this.game.selected || [];
    const selectedSet = new Set(selected.map((s) => `${s.x},${s.y}`));

    const cells = gridDiv.querySelectorAll('.cell');
    cells.forEach((cell) => {
      const x = parseInt(cell.dataset.x, 10);
      const y = parseInt(cell.dataset.y, 10);
      const shouldBeSelected = selectedSet.has(`${x},${y}`);
      cell.classList.toggle('selected', shouldBeSelected);
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
