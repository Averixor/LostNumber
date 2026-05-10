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

LostNumberGame.prototype.getDebugContext = function () {
  try {
    const base = {
      currentLevel: this.currentLevel,
      gamePhase: this.gamePhase,
      screenState: this.screenState,
      carryNumber: this.carryNumber,
    };
    if (!window.AppEnv?.isDebugFull) {
      return base;
    }
    return {
      ...base,
      animationEnabled: this.animationEnabled,
      liteVisualMode: this.liteVisualMode,
      floatingNumbersEnabled: this.floatingNumbersEnabled,
      xpMultiplier: this.xpMultiplier,
      xpMultiplierTurns: this.xpMultiplierTurns,
      bonusInventory: this.bonusInventory ? { ...this.bonusInventory } : null,
      selectedLen: this.selected?.length,
      chainSum: typeof Chain !== 'undefined' && Chain ? Chain.sum : null,
    };
  } catch (e) {
    return { getDebugContextError: String(e) };
  }
};

LostNumberGame.prototype.addBonus = function (type, count = 1) {
  try {
    if (!type) return;
    const amount = Number(count) || 1;
    this.grantBonus(type, amount);
    this.updateBonusesUI?.();
    this.saveGameState?.();
    this.showMessage?.(`+${amount} ${type}`);
  } catch (error) {
    ErrorHandler.handle(error, { where: 'addBonus', type, count });
  }
};

if (typeof window !== 'undefined' && window.AppEnv?.isDev) {
  window.__testLowFpsDisableFloatingNumbers = function () {
    window.dispatchEvent(
      new CustomEvent('lostnumber:floating-numbers-auto-disable', {
        detail: { reason: 'fps', averageFps: 10, critical: true },
      }),
    );
  };
}

if (typeof window !== 'undefined' && window.AppEnv?.isDebugFull) {
  window.__LN_SENIOR = {
    help: () => window.LN_DEBUG?.help?.(),
    dumpErrors: () => ErrorHandler.getErrorHistory?.(),
    clearErrors: () => ErrorHandler.clearErrorHistory?.(),
    game: () => window.game,
  };
}
