// MicroComboSystem.js — микро-комбо (легкий дофамин, без разлома баланса)
class MicroComboSystem {
  constructor(game) {
    this.game = game;
    this.combo = 0;
    this.lastActionAt = 0;
  }

  onChainComplete() {
    const now = Date.now();
    if (now - this.lastActionAt > 30000) this.combo = 0;
    this.combo++;
    this.lastActionAt = now;
    this.game.combo = this.combo;
    if (this.combo >= 2) {
      this.game.showMessage(`COMBO x${this.combo}`);
    }
  }

  onChainInvalid() {
    this.combo = 0;
    this.game.combo = 0;
  }

  getXPMultiplier() {
    if (this.combo >= 4) return 1.5;
    if (this.combo === 3) return 1.25;
    if (this.combo === 2) return 1.1;
    return 1.0;
  }
}
