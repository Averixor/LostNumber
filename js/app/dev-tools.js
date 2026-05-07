// Dev Tools: LostNumberGame prototype methods.

LostNumberGame.prototype.forceError = function () {
  try {
    throw new Error('Forced error (debug)');
  } catch (error) {
    ErrorHandler.handle(error, { type: 'debug_forced' });
  }
};

LostNumberGame.prototype.skipLevel = function () {
  try {
    this.setGamePhase?.('win');
    this.handleLevelComplete?.();
    this.showMessage?.('DEV: level skipped');
  } catch (error) {
    ErrorHandler.handle(error, { where: 'skipLevel' });
  }
};

LostNumberGame.prototype.addBonus = function (type, count = 1) {
  try {
    if (!type) return;
    if (!this.bonusInventory) this.bonusInventory = {};
    this.bonusInventory[type] = (this.bonusInventory[type] || 0) + (Number(count) || 1);
    this.updateBonusesUI?.();
    this.saveGameState?.();
    this.showMessage?.(`+${count} ${type}`);
  } catch (error) {
    ErrorHandler.handle(error, { where: 'addBonus', type, count });
  }
};
