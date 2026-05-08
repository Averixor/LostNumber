class OverlayManager {
  constructor(game) {
    this.game = game;
  }

  /** Мобільний / lite: суму показуємо кольором клітинок ланцюга, бульбашку ховаємо. */
  static shouldHintChainOnCells() {
    try {
      if (document.documentElement.classList.contains('low-performance')) return true;
      if (typeof PlatformDetector !== 'undefined' && PlatformDetector.isMobile?.()) return true;
      if (
        typeof window.matchMedia === 'function' &&
        window.matchMedia('(pointer: coarse)').matches &&
        window.innerWidth <= 900
      ) {
        return true;
      }
    } catch (_) {}
    return false;
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

  clearChainPreviewClasses() {
    try {
      document
        .querySelectorAll('#grid .cell.chain-preview-valid, #grid .cell.chain-preview-invalid')
        .forEach((el) => el.classList.remove('chain-preview-valid', 'chain-preview-invalid'));
    } catch (_) {}
  }

  updatePreviewBubble() {
    const bubble = document.getElementById('previewBubble');
    if (!bubble) return;

    bubble.textContent = this.game.formatNumber(Chain.sum);

    if (!this.game.selected || this.game.selected.length === 0) {
      bubble.style.opacity = '0';
      bubble.classList.remove('valid', 'invalid');
      bubble.classList.remove('valid-sum');
      this.clearChainPreviewClasses();
      return;
    }

    const canFinish = this.game.core.canFinishChain(Chain);
    const chainLen = Chain.numbers?.length ?? 0;

    bubble.classList.remove('valid', 'invalid', 'valid-sum');

    if (canFinish) {
      bubble.classList.add('valid');
      bubble.classList.add('valid-sum');
    } else if (chainLen >= 2) {
      bubble.classList.add('invalid');
    }

    const useChainGlow = OverlayManager.shouldHintChainOnCells();
    let chainHint = null;
    if (useChainGlow && chainLen >= 2) {
      chainHint = canFinish ? 'valid' : 'invalid';
    }

    if (useChainGlow) {
      bubble.style.opacity = '0';
      bubble.classList.remove('valid', 'invalid', 'valid-sum');
      this.updateSelectedCells(chainHint);
      return;
    }

    bubble.style.opacity = '1';

    const container = document.querySelector('#gameScreen .grid-container');
    const grid = document.getElementById('grid');
    if (!container || !grid) {
      this.updateSelectedCells(null);
      return;
    }

    const containerRect = container.getBoundingClientRect();
    const gridRect = grid.getBoundingClientRect();

    const anchor = this.game.selected[this.game.selected.length - 1];

    const gap = 8;
    const minY = gap;
    const maxBottom = containerRect.height - gap;

    const g = this.game;
    const usePointer =
      g.isDragging &&
      typeof g._bubblePointerX === 'number' &&
      typeof g._bubblePointerY === 'number' &&
      !Number.isNaN(g._bubblePointerX) &&
      !Number.isNaN(g._bubblePointerY);

    let xCenter;
    let yCandidate;

    if (usePointer) {
      xCenter = g._bubblePointerX - containerRect.left;
      const py = g._bubblePointerY - containerRect.top;
      const fingerLift = 52;
      yCandidate = py - fingerLift;
    } else {
      const gridOffsetX = gridRect.left - containerRect.left;
      const gridOffsetY = gridRect.top - containerRect.top;
      const cellW = gridRect.width / this.game.GRID_W;
      const cellH = gridRect.height / this.game.GRID_H;

      xCenter = gridOffsetX + (anchor.x + 0.5) * cellW;

      const yAbove = gridOffsetY + anchor.y * cellH - cellH - gap;
      const yBelow = gridOffsetY + (anchor.y + 1) * cellH + gap;

      yCandidate = yAbove;
      if (yCandidate < minY || yCandidate + 44 > maxBottom) {
        yCandidate = yBelow;
      }
    }

    bubble.style.left = `${xCenter}px`;
    bubble.style.top = `${yCandidate}px`;

    const bubbleH = bubble.offsetHeight || 44;
    const bubbleW = bubble.offsetWidth || 72;

    let y = yCandidate;
    if (usePointer) {
      if (y < minY) {
        const py = g._bubblePointerY - containerRect.top;
        y = py + 16;
      }
    } else {
      if (y < minY || y + bubbleH > maxBottom) {
        const gridOffsetY = gridRect.top - containerRect.top;
        const cellH = gridRect.height / this.game.GRID_H;
        y = gridOffsetY + (anchor.y + 1) * cellH + gap;
      }
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

    this.updateSelectedCells(null);
  }

  /**
   * @param {null | 'valid' | 'invalid'} chainHint — колір ланцюга (лише коли shouldHintChainOnCells)
   */
  updateSelectedCells(chainHint = null) {
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

      if (!shouldBeSelected) {
        cell.classList.remove('chain-preview-valid', 'chain-preview-invalid');
        return;
      }

      if (chainHint === 'valid') {
        cell.classList.add('chain-preview-valid');
        cell.classList.remove('chain-preview-invalid');
      } else if (chainHint === 'invalid') {
        cell.classList.add('chain-preview-invalid');
        cell.classList.remove('chain-preview-valid');
      } else {
        cell.classList.remove('chain-preview-valid', 'chain-preview-invalid');
      }
    });
  }

  hidePreviewBubble() {
    const bubble = document.getElementById('previewBubble');
    if (!bubble) return;
    bubble.style.opacity = '0';
    bubble.classList.remove('valid', 'invalid', 'valid-sum');
    this.clearChainPreviewClasses();
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
