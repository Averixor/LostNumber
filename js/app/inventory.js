// Inventory: facade-методы для bonusInventory у LostNumberGame.
// Не читать/писать state.bonusInventory или game.bonusInventory[...] напрямую в gameplay-коде.
// API:
//   getBonusCount(type)            -> number (0 если нет/невалидно)
//   grantBonus(type, amount=1)     -> new count (никогда не отрицательное)
//   consumeBonus(type, amount=1)   -> boolean (true если count > 0 и списано)
//   getBonusInventorySnapshot()    -> { destroy, shuffle, explosion }
//   resetBonusInventory()          -> void (в zero-значения)

(function () {
  const BONUS_TYPES = ['destroy', 'shuffle', 'explosion'];

  function isValidType(type) {
    return typeof type === 'string' && BONUS_TYPES.indexOf(type) !== -1;
  }

  function ensureInventory(game) {
    if (!game.bonusInventory || typeof game.bonusInventory !== 'object') {
      game.bonusInventory = { destroy: 0, shuffle: 0, explosion: 0 };
    }
    return game.bonusInventory;
  }

  function readCount(inv, type) {
    if (!inv || typeof inv !== 'object') return 0;
    const v = inv[type];
    return typeof v === 'number' && v >= 0 ? v : 0;
  }

  LostNumberGame.prototype.getBonusCount = function (type) {
    try {
      if (!isValidType(type)) return 0;
      return readCount(this.bonusInventory, type);
    } catch (error) {
      ErrorHandler.warn('getBonusCount failed', { error, type });
      return 0;
    }
  };

  LostNumberGame.prototype.grantBonus = function (type, amount = 1) {
    try {
      if (!isValidType(type)) {
        ErrorHandler.warn('grantBonus: invalid bonus type', { type, amount });
        return 0;
      }
      const n = Number(amount);
      if (!Number.isFinite(n) || n <= 0) {
        return readCount(this.bonusInventory, type);
      }
      const inv = ensureInventory(this);
      inv[type] = readCount(inv, type) + n;
      return inv[type];
    } catch (error) {
      ErrorHandler.warn('grantBonus failed', { error, type, amount });
      return 0;
    }
  };

  LostNumberGame.prototype.consumeBonus = function (type, amount = 1) {
    try {
      if (!isValidType(type)) {
        ErrorHandler.warn('consumeBonus: invalid bonus type', { type, amount });
        return false;
      }
      const inv = ensureInventory(this);
      const cur = readCount(inv, type);
      if (cur <= 0) return false;
      const n = Number(amount);
      const dec = Number.isFinite(n) && n > 0 ? n : 1;
      inv[type] = cur - dec;
      return true;
    } catch (error) {
      ErrorHandler.warn('consumeBonus failed', { error, type, amount });
      return false;
    }
  };

  LostNumberGame.prototype.getBonusInventorySnapshot = function () {
    try {
      const inv = ensureInventory(this);
      return {
        destroy: readCount(inv, 'destroy'),
        shuffle: readCount(inv, 'shuffle'),
        explosion: readCount(inv, 'explosion'),
      };
    } catch (error) {
      ErrorHandler.warn('getBonusInventorySnapshot failed', { error });
      return { destroy: 0, shuffle: 0, explosion: 0 };
    }
  };

  LostNumberGame.prototype.resetBonusInventory = function () {
    try {
      this.bonusInventory = { destroy: 0, shuffle: 0, explosion: 0 };
    } catch (error) {
      ErrorHandler.warn('resetBonusInventory failed', { error });
    }
  };
})();
