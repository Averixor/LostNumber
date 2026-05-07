class BonusManager {
  constructor(game) {
    this.game = game;
    ErrorHandler.info('BonusManager initialized');
  }

  activateBonus(type) {
    try {
      if (this.game.activeBonus === type) {
        this.game.activeBonus = null;
        this.updateBonusesUI();
        return;
      }

      // Валидация наличия бонуса
      if (!this.game.bonusInventory || typeof this.game.bonusInventory[type] !== 'number') {
        ErrorHandler.warn('Invalid bonus inventory', { type, inventory: this.game.bonusInventory });
        this.showMessage(this.game.t('bonus_error') || 'Бонус недоступний');
        return;
      }

      if (this.game.getBonusCount(type) <= 0) {
        this.showMessage(this.game.t('no_bonus'));
        return;
      }

      if (type === 'shuffle') {
        if (!this.game.consumeBonus('shuffle', 1)) {
          this.showMessage(this.game.t('no_bonus'));
          return;
        }
        this.game.incrementStat('bonusesUsed', 1);

        // Анимированное перемешивание с обработкой ошибок
        this.animatedShuffleGrid();
        this.updateBonusesUI();
        this.showMessage(this.game.t('shuffle_done'));

        // Обновление достижений
        if (this.game.achievementManager) {
          ErrorHandler.safeExecute(() => {
            this.game.achievementManager.updateAchievementProgress('useAllBonuses', 1);
          });
        }

        // Обновление ежедневных заданий
        if (this.game.dailyQuestManager) {
          ErrorHandler.safeExecute(() => {
            this.game.dailyQuestManager.completeDailyQuest('useBonus');
          });
        }

        // Автосохранение
        ErrorHandler.safeExecute(() => {
          this.game.saveGameState();
        });

        return;
      }

      // Активация бонуса для выбора клетки
      this.game.activeBonus = type;
      this.updateBonusesUI();
      this.showMessage(this.game.t('choose_cell_bonus'));
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'bonus_activation',
        bonusType: type,
        activeBonus: this.game.activeBonus,
        inventory: this.game.bonusInventory,
      });
      this.showMessage(this.game.t('bonus_error') || 'Помилка активації бонусу');
    }
  }

  animatedShuffleGrid() {
    try {
      const gridDiv = document.getElementById('grid');
      if (!gridDiv) {
        ErrorHandler.warn('Grid not found for shuffle animation');
        // Продолжаем без анимации
        if (this.game.gridManager) {
          this.game.gridManager.shuffleGrid();
        }
        return;
      }

      const cells = gridDiv.querySelectorAll('.cell');
      cells.forEach((c) => {
        try {
          c.classList.add('shuffle-anim');
        } catch (e) {
          // Игнорируем ошибки добавления классов
        }
      });

      setTimeout(() => {
        try {
          if (this.game.gridManager) {
            this.game.gridManager.shuffleGrid();
          }
          cells.forEach((c) => {
            try {
              c.classList.remove('shuffle-anim');
            } catch (e) {
              // Игнорируем ошибки удаления классов
            }
          });
        } catch (error) {
          ErrorHandler.handle(error, { type: 'shuffle_execution' });
        }
      }, 350);
    } catch (error) {
      ErrorHandler.handle(error, { type: 'shuffle_animation' });
      // Пытаемся выполнить перемешивание без анимации
      if (this.game.gridManager) {
        this.game.gridManager.shuffleGrid();
      }
    }
  }

  useDestroyBonus(x, y) {
    try {
      // Проверка валидности координат
      if (x < 0 || x >= this.game.GRID_W || y < 0 || y >= this.game.GRID_H) {
        ErrorHandler.warn('Invalid coordinates for destroy bonus', {
          x,
          y,
          gridW: this.game.GRID_W,
          gridH: this.game.GRID_H,
        });
        this.showMessage(this.game.t('bonus_error') || 'Некоректні координати');
        return;
      }

      if (this.game.getBonusCount('destroy') <= 0) {
        this.showMessage(this.game.t('no_bonus'));
        this.game.activeBonus = null;
        this.updateBonusesUI();
        return;
      }

      if (!this.game.consumeBonus('destroy', 1)) {
        this.game.activeBonus = null;
        this.updateBonusesUI();
        this.showMessage(this.game.t('no_bonus'));
        return;
      }
      this.game.incrementStat('bonusesUsed', 1);

      const removedCells = [{ x, y }];

      if (this.game.gridManager) {
        this.game.gridManager.animatePopping(removedCells, () => {
          this.game.gridManager.animateGravity(removedCells, () => {
            try {
              // ВАЖНО: Вызываем гравитацию
              this.game.gridManager.applyLocalGravity(removedCells);
              this.game.activeBonus = null;
              this.updateBonusesUI();
              this.showMessage(this.game.t('destroy_done'));

              // Обновление достижений
              if (this.game.achievementManager) {
                this.game.achievementManager.updateAchievementProgress('useAllBonuses', 1);
              }

              // Обновление ежедневных заданий
              if (this.game.dailyQuestManager) {
                this.game.dailyQuestManager.completeDailyQuest('useBonus');
              }

              // Автосохранение
              this.game.saveGameState();
            } catch (error) {
              ErrorHandler.handle(error, {
                type: 'destroy_bonus_aftermath',
                x,
                y,
                removedCells,
              });
              this.game.activeBonus = null;
              this.updateBonusesUI();
            }
          });
        });
      } else {
        ErrorHandler.warn('GridManager not available for destroy bonus');
        this.game.activeBonus = null;
        this.updateBonusesUI();
      }
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'destroy_bonus',
        x,
        y,
        bonusInventory: this.game.bonusInventory,
      });
      this.game.activeBonus = null;
      this.updateBonusesUI();
      this.showMessage(this.game.t('bonus_error') || 'Помилка використання бонусу');
    }
  }

  useExplosionBonus(x, y) {
    try {
      // Проверка валидности координат
      if (x < 0 || x >= this.game.GRID_W || y < 0 || y >= this.game.GRID_H) {
        ErrorHandler.warn('Invalid coordinates for explosion bonus', {
          x,
          y,
          gridW: this.game.GRID_W,
          gridH: this.game.GRID_H,
        });
        this.showMessage(this.game.t('bonus_error') || 'Некоректні координати');
        return;
      }

      if (this.game.getBonusCount('explosion') <= 0) {
        this.showMessage(this.game.t('no_bonus'));
        this.game.activeBonus = null;
        this.updateBonusesUI();
        return;
      }

      if (!this.game.consumeBonus('explosion', 1)) {
        this.game.activeBonus = null;
        this.updateBonusesUI();
        this.showMessage(this.game.t('no_bonus'));
        return;
      }
      this.game.incrementStat('bonusesUsed', 1);

      const removedCells = [];
      for (let dx = -1; dx <= 1; dx++) {
        for (let dy = -1; dy <= 1; dy++) {
          const nx = x + dx,
            ny = y + dy;
          if (nx >= 0 && nx < this.game.GRID_W && ny >= 0 && ny < this.game.GRID_H) {
            removedCells.push({ x: nx, y: ny });
          }
        }
      }

      if (this.game.gridManager) {
        this.game.gridManager.animatePopping(removedCells, () => {
          this.game.gridManager.animateGravity(removedCells, () => {
            try {
              // ВАЖНО: Вызываем гравитацию
              this.game.gridManager.applyLocalGravity(removedCells);
              this.game.activeBonus = null;
              this.updateBonusesUI();
              this.showMessage(this.game.t('explosion_done'));

              // Обновление достижений
              if (this.game.achievementManager) {
                this.game.achievementManager.updateAchievementProgress('useAllBonuses', 1);
              }

              // Обновление ежедневных заданий
              if (this.game.dailyQuestManager) {
                this.game.dailyQuestManager.completeDailyQuest('useBonus');
              }

              // Автосохранение
              this.game.saveGameState();
            } catch (error) {
              ErrorHandler.handle(error, {
                type: 'explosion_bonus_aftermath',
                x,
                y,
                removedCells,
              });
              this.game.activeBonus = null;
              this.updateBonusesUI();
            }
          });
        });
      } else {
        ErrorHandler.warn('GridManager not available for explosion bonus');
        this.game.activeBonus = null;
        this.updateBonusesUI();
      }
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'explosion_bonus',
        x,
        y,
        bonusInventory: this.game.bonusInventory,
      });
      this.game.activeBonus = null;
      this.updateBonusesUI();
      this.showMessage(this.game.t('bonus_error') || 'Помилка використання бонусу');
    }
  }

  updateBonusesUI() {
    try {
      const countExplosion = document.getElementById('count-explosion');
      const countShuffle = document.getElementById('count-shuffle');
      const countDestroy = document.getElementById('count-destroy');

      const bonusExplosion = document.getElementById('bonus-explosion');
      const bonusShuffle = document.getElementById('bonus-shuffle');
      const bonusDestroy = document.getElementById('bonus-destroy');

      // Безопасное получение данных бонусов через facade
      const b =
        typeof this.game.getBonusInventorySnapshot === 'function'
          ? this.game.getBonusInventorySnapshot()
          : this.game.bonusInventory || { explosion: 0, shuffle: 0, destroy: 0 };

      if (countExplosion) countExplosion.textContent = b.explosion || 0;
      if (countShuffle) countShuffle.textContent = b.shuffle || 0;
      if (countDestroy) countDestroy.textContent = b.destroy || 0;

      const activeBonus = this.game.activeBonus;
      const explosionDisabled = (b.explosion || 0) <= 0 && activeBonus !== 'explosion';
      const shuffleDisabled = (b.shuffle || 0) <= 0 && activeBonus !== 'shuffle';
      const destroyDisabled = (b.destroy || 0) <= 0 && activeBonus !== 'destroy';

      if (bonusExplosion) {
        bonusExplosion.disabled = explosionDisabled;
        bonusExplosion.classList.toggle('active', activeBonus === 'explosion');
      }
      if (bonusShuffle) {
        bonusShuffle.disabled = shuffleDisabled;
        bonusShuffle.classList.toggle('active', activeBonus === 'shuffle');
      }
      if (bonusDestroy) {
        bonusDestroy.disabled = destroyDisabled;
        bonusDestroy.classList.toggle('active', activeBonus === 'destroy');
      }
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'bonus_ui_update',
        bonusInventory: this.game.bonusInventory,
        activeBonus: this.game.activeBonus,
      });
    }
  }

  showMessage(text) {
    try {
      if (this.game && typeof this.game.showMessage === 'function') {
        this.game.showMessage(text);
      } else {
        ErrorHandler.warn('showMessage not available in game', { text });
      }
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'bonus_message',
        text: text?.substring(0, 50),
      });
    }
  }

  // === НОВЫЕ МЕТОДЫ ДЛЯ ОБРАБОТКИ ОШИБОК ===

  // Валидация состояния бонусов
  validateBonusState() {
    try {
      const issues = [];

      if (!this.game.bonusInventory || typeof this.game.bonusInventory !== 'object') {
        issues.push('Bonus inventory not initialized');
        return false;
      }

      const requiredBonuses = ['explosion', 'shuffle', 'destroy'];
      for (const bonus of requiredBonuses) {
        if (typeof this.game.bonusInventory[bonus] !== 'number' || this.game.bonusInventory[bonus] < 0) {
          issues.push(`Invalid bonus count for ${bonus}: ${this.game.bonusInventory[bonus]}`);
        }
      }

      if (issues.length > 0) {
        ErrorHandler.warn('Bonus state validation failed', {
          type: 'bonus_validation',
          issues,
          bonusInventory: this.game.bonusInventory,
        });
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'bonus_validation_error' });
      return false;
    }
  }

  // Исправление состояния бонусов
  repairBonusState() {
    try {
      ErrorHandler.info('Attempting to repair bonus state');

      let repaired = false;

      if (!this.game.bonusInventory || typeof this.game.bonusInventory !== 'object') {
        this.game.bonusInventory = { explosion: 0, shuffle: 0, destroy: 0 };
        repaired = true;
      } else {
        const defaultBonuses = { explosion: 0, shuffle: 0, destroy: 0 };
        for (const key in defaultBonuses) {
          if (typeof this.game.bonusInventory[key] !== 'number' || this.game.bonusInventory[key] < 0) {
            this.game.bonusInventory[key] = defaultBonuses[key];
            repaired = true;
          }
        }
      }

      if (repaired) {
        ErrorHandler.info('Bonus state repaired', { bonusInventory: this.game.bonusInventory });
        this.updateBonusesUI();
      }

      return repaired;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'bonus_repair_failed' });
      return false;
    }
  }

  // Безопасное использование бонуса с fallback
  safeActivateBonus(type, fallbackAction = null) {
    try {
      return this.activateBonus(type);
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'safe_bonus_activation',
        bonusType: type,
      });

      // Fallback действия
      if (typeof fallbackAction === 'function') {
        try {
          return fallbackAction();
        } catch (fallbackError) {
          ErrorHandler.handle(fallbackError, { type: 'bonus_fallback_failed' });
        }
      }

      this.showMessage(this.game.t('bonus_error') || 'Бонус недоступний');
      return false;
    }
  }
}
