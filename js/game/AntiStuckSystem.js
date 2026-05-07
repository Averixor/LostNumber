// AntiStuckSystem.js — исправлено обращение к свойствам ячеек
class AntiStuckSystem {
  constructor(game) {
    this.game = game;
    this.levelStartAt = Date.now();
    this.usedHintThisLevel = false;
  }

  onLevelStart() {
    this.levelStartAt = Date.now();
    this.usedHintThisLevel = false;
  }

  onCorrectMove() {
    if (this.game.gridManager && this.game.gridManager.onCorrectMove) {
      this.game.gridManager.onCorrectMove();
    }
  }

  checkPossibleMoves() {
    try {
      const g = this.game;
      const W = g.GRID_W;
      const H = g.GRID_H;
      const grid = g.grid;

      if (!grid || !grid.length) return true;

      for (let x = 0; x < W; x++) {
        for (let y = 0; y < H; y++) {
          const a = grid[x][y];
          if (!a) continue;

          // Соседние клетки (вверх, вниз, влево, вправо)
          const neigh = [
            [x + 1, y],
            [x - 1, y],
            [x, y + 1],
            [x, y - 1],
          ];
          for (const [nx, ny] of neigh) {
            if (nx < 0 || ny < 0 || nx >= W || ny >= H) continue;

            const b = grid[nx][ny];
            if (!b) continue;

            // ИСПРАВЛЕНО: используем .number вместо .value
            const av = a.number || 0;
            const bv = b.number || 0;

            if (!av || !bv) continue;

            const sum = av + bv;

            // Проверка на степень двойки через Rules или встроенный метод
            const isPower =
              typeof Rules !== 'undefined' && Rules.isPowerOfTwo
                ? Rules.isPowerOfTwo(sum)
                : sum > 0 && (sum & (sum - 1)) === 0;

            if (isPower) return true;
          }
        }
      }
      return false;
    } catch (e) {
      if (typeof ErrorHandler !== 'undefined') {
        ErrorHandler.handle(e, { where: 'AntiStuckSystem.checkPossibleMoves' });
      }
      return true; // В случае ошибки не блокируем игру
    }
  }

  maybeOfferHelp() {
    const g = this.game;
    if (this.usedHintThisLevel) return;

    const stuckLong = Date.now() - this.levelStartAt > 5 * 60 * 1000;
    const noMoves = !this.checkPossibleMoves();

    if (stuckLong || noMoves) {
      this.usedHintThisLevel = true;
      // Используем метод перевода или стандартную строку
      const msg = (g.t && g.t('need_help')) || 'Нужна помощь? Используйте бонусы!';
      g.showMessage(msg);
    }
  }
}
