class WheelManager {
  constructor(game) {
    this.game = game;
    this.isSpinning = false;
    this.currentRotation = 0;
    this.highlightedSectorIndex = null;

    this.wheelSectors = [
      { id: 0, type: 'xp_plus', label: 'XP+', color: '#4CAF50', effect: 'xp', value: 15, messageKey: 'wheel_xp_plus' },
      {
        id: 1,
        type: 'xp_minus',
        label: 'XP−',
        color: '#F44336',
        effect: 'xp',
        value: -10,
        messageKey: 'wheel_xp_minus',
      },
      {
        id: 2,
        type: 'shuffle',
        label: '🔄',
        color: '#2196F3',
        effect: 'bonus',
        value: 'shuffle',
        messageKey: 'wheel_bonus_shuffle_added',
      },
      {
        id: 3,
        type: 'destroy',
        label: '🔨',
        color: '#FF9800',
        effect: 'bonus',
        value: 'destroy',
        messageKey: 'wheel_bonus_destroy_added',
      },
      {
        id: 4,
        type: 'explosion',
        label: '💥',
        color: '#9C27B0',
        effect: 'bonus',
        value: 'explosion',
        messageKey: 'wheel_bonus_explosion_added',
      },
      {
        id: 5,
        type: 'xp_multiplier',
        label: '×2 XP',
        color: '#FFC107',
        effect: 'multiplier',
        value: 5,
        messageKey: 'wheel_xp_multiplier',
        multiplier: 2,
        turns: 3,
      },
      { id: 6, type: 'gift', label: '🎁', color: '#00BCD4', effect: 'gift', value: null, messageKey: 'wheel_gift' },
      {
        id: 7,
        type: 'freeze',
        label: '❄️',
        color: '#607D8B',
        effect: 'freeze',
        value: 5,
        messageKey: 'wheel_freeze_message',
        fallbackXP: 50,
      },
    ];

    ErrorHandler.info('WheelManager initialized', { sectorCount: this.wheelSectors.length });
  }

  getWheelCost() {
    try {
      const BASE = 25;
      const STEP = 10;
      const FREE = 5;

      if (!this.game.wheelSpinsToday || this.game.wheelSpinsToday < FREE) return BASE;
      return BASE + (this.game.wheelSpinsToday - FREE) * STEP;
    } catch (error) {
      ErrorHandler.warn('getWheelCost failed', error);
      return 25; // Базовая стоимость при ошибке
    }
  }

  handleWheel() {
    try {
      this.game.checkWheelDailyReset();

      // Проверка лимита прокруток
      if (this.game.wheelSpinsToday >= this.game.MAX_DAILY_SPINS) {
        this.game.showMessage(this.game.t('wheel_limit_reached'));
        return;
      }

      const cost = this.getWheelCost();

      // Проверка достаточности XP
      if (this.game.xp < cost) {
        this.game.showMessage(this.game.t('dice_not_enough'));
        return;
      }

      // Инициализация колеса
      this.initWheel();

      // Показ overlay
      const wheelOverlay = document.getElementById('wheelOverlay');
      if (wheelOverlay) {
        wheelOverlay.classList.remove('hidden');
      } else {
        ErrorHandler.warn('Wheel overlay not found');
        return;
      }

      this.updateWheelUI();
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'wheel_handle',
        wheelSpinsToday: this.game.wheelSpinsToday,
        xp: this.game.xp,
      });
      this.game.showMessage(this.game.t('error_generic') || 'Помилка колеса');
    }
  }

  initWheel() {
    try {
      const canvas = document.getElementById('fortuneWheel');
      if (!canvas) {
        ErrorHandler.warn('Wheel canvas not found');
        return;
      }

      const ctx = canvas.getContext('2d');
      if (!ctx) {
        ErrorHandler.warn('Canvas context not available');
        return;
      }

      const centerX = canvas.width / 2;
      const centerY = canvas.height / 2;
      const radius = Math.min(centerX, centerY) - 10;

      this.wheelCtx = ctx;
      this.wheelCenterX = centerX;
      this.wheelCenterY = centerY;
      this.wheelRadius = radius;

      this.drawWheel();
    } catch (error) {
      ErrorHandler.handle(error, { type: 'wheel_init' });
    }
  }

  drawWheel() {
    try {
      if (!this.wheelCtx) {
        ErrorHandler.warn('Wheel context not initialized');
        return;
      }

      const ctx = this.wheelCtx;
      const centerX = this.wheelCenterX;
      const centerY = this.wheelCenterY;
      const radius = this.wheelRadius;

      // Очищаем canvas
      ctx.clearRect(0, 0, 300, 300);

      const anglePerSector = (2 * Math.PI) / this.wheelSectors.length;

      // Рисуем сектора
      this.wheelSectors.forEach((sector, i) => {
        const startAngle = i * anglePerSector;
        const endAngle = (i + 1) * anglePerSector;

        ctx.beginPath();
        ctx.moveTo(centerX, centerY);
        ctx.arc(centerX, centerY, radius, startAngle, endAngle);
        ctx.closePath();
        ctx.fillStyle = sector.color;
        ctx.fill();
        ctx.strokeStyle = '#FFF';
        ctx.lineWidth = 2;
        ctx.stroke();

        // Текст на секторе
        const midAngle = startAngle + anglePerSector / 2;
        const textX = centerX + radius * 0.7 * Math.cos(midAngle);
        const textY = centerY + radius * 0.7 * Math.sin(midAngle);

        ctx.save();
        ctx.translate(textX, textY);
        ctx.rotate(midAngle + Math.PI / 2);
        ctx.textAlign = 'center';
        ctx.fillStyle = '#FFF';
        ctx.font = 'bold 16px Arial';

        // Безопасное получение текста
        let sectorText = '';
        try {
          sectorText = this.game.t(`wheel_sector_${sector.type}`) || sector.label;
        } catch (e) {
          sectorText = sector.label;
        }

        ctx.fillText(sectorText, 0, 0);
        ctx.restore();
      });

      // Рисуем подсветку выделенного сектора, если есть
      if (this.highlightedSectorIndex !== null) {
        const sectorIndex = this.highlightedSectorIndex;
        if (sectorIndex >= 0 && sectorIndex < this.wheelSectors.length) {
          const startAngle = sectorIndex * anglePerSector;
          const endAngle = (sectorIndex + 1) * anglePerSector;

          // Подсветка градиентом
          const gradient = ctx.createRadialGradient(centerX, centerY, radius, centerX, centerY, radius + 8);
          gradient.addColorStop(0, 'rgba(255, 215, 0, 0.4)');
          gradient.addColorStop(1, 'rgba(255, 215, 0, 0)');

          ctx.beginPath();
          ctx.moveTo(centerX, centerY);
          ctx.arc(centerX, centerY, radius + 8, startAngle, endAngle);
          ctx.closePath();
          ctx.fillStyle = gradient;
          ctx.fill();

          // Золотая обводка
          ctx.beginPath();
          ctx.moveTo(centerX, centerY);
          ctx.arc(centerX, centerY, radius + 6, startAngle, endAngle);
          ctx.closePath();
          ctx.lineWidth = 3;
          ctx.strokeStyle = '#FFD700';
          ctx.stroke();
        }
      }

      // Центральная точка
      ctx.beginPath();
      ctx.arc(centerX, centerY, 10, 0, 2 * Math.PI);
      ctx.fillStyle = '#FF4081';
      ctx.fill();
      ctx.strokeStyle = '#FFF';
      ctx.lineWidth = 3;
      ctx.stroke();
    } catch (error) {
      ErrorHandler.handle(error, { type: 'wheel_draw' });
    }
  }

  spinWheel() {
    try {
      if (this.isSpinning) {
        ErrorHandler.debug('Wheel already spinning');
        return;
      }

      const cost = this.getWheelCost();

      // Проверка достаточности XP
      if (this.game.xp < cost) {
        this.game.showMessage(this.game.t('dice_not_enough'));
        return;
      }

      // Проверка лимита прокруток
      if (this.game.wheelSpinsToday >= this.game.MAX_DAILY_SPINS) {
        this.game.showMessage(this.game.t('wheel_limit_reached'));
        return;
      }

      this.isSpinning = true;

      // Списание XP
      this.game.xp -= cost;
      this.game.wheelSpinsToday = (this.game.wheelSpinsToday || 0) + 1;
      this.game.incrementStat('wheelSpins', 1);

      // Обновление достижений
      if (this.game.achievementManager) {
        ErrorHandler.safeExecute(() => {
          this.game.achievementManager.updateAchievementProgress('spinWheel', 1);
          this.game.achievementManager.updateAchievementProgress('spinWheel10', 1);
        });
      }

      // Обновление ежедневных заданий
      if (this.game.dailyQuestManager) {
        ErrorHandler.safeExecute(() => {
          this.game.dailyQuestManager.completeDailyQuest('spinWheel');
        });
      }

      this.game.updateXPBar();
      this.updateWheelUI();

      // Обновление кнопки вращения
      const spinBtn = document.getElementById('spinWheelBtn');
      if (spinBtn) {
        spinBtn.disabled = true;
        try {
          spinBtn.textContent = this.game.t('wheel_spinning');
        } catch (e) {
          spinBtn.textContent = 'Spinning...';
        }
      }

      // Выбор случайного сектора
      const sectorCount = this.wheelSectors.length;
      const randomIndex = Math.floor(Math.random() * sectorCount);
      const selectedSector = this.wheelSectors[randomIndex];

      // Расчет вращения
      const angle = 360 / sectorCount;
      this.currentRotation += 360 * 5 + randomIndex * angle;

      // Применение вращения
      const wheel = document.getElementById('fortuneWheel');
      if (wheel) {
        const transitionEnabled = this.game.animationEnabled !== false;
        wheel.style.transition = transitionEnabled ? 'transform 3s cubic-bezier(0.15, 0, 0.15, 1)' : 'none';
        wheel.style.transform = `rotate(${this.currentRotation}deg)`;
      }

      const spinDuration = this.game.animationEnabled !== false ? 3100 : 0;

      setTimeout(() => {
        try {
          // Показываем результат
          const resultEl = document.getElementById('wheelResult');
          if (resultEl) {
            try {
              const messageParams = selectedSector.turns ? { turns: selectedSector.turns } : {};
              const message =
                this.game.formatTemplate(selectedSector.messageKey, messageParams) || selectedSector.label;
              resultEl.textContent = message;
              resultEl.classList.remove('hidden');
            } catch (e) {
              resultEl.textContent = selectedSector.label;
              resultEl.classList.remove('hidden');
            }
          }

          // Подсветка выпавшего сектора
          this.highlightWheelSector(randomIndex);

          // Применяем результат
          this.applyWheelResult(selectedSector);

          // Разблокируем кнопку
          const spinBtn2 = document.getElementById('spinWheelBtn');
          if (spinBtn2) {
            spinBtn2.disabled = false;
            try {
              spinBtn2.textContent = this.game.formatTemplate('btn_spin_wheel', { cost: this.getWheelCost() });
            } catch (e) {
              spinBtn2.textContent = `Spin (${this.getWheelCost()} XP)`;
            }
          }

          // Автосохранение
          ErrorHandler.safeExecute(() => {
            this.game.saveGameState();
          });

          this.isSpinning = false;
        } catch (error) {
          ErrorHandler.handle(error, {
            type: 'wheel_spin_completion',
            sectorIndex: randomIndex,
            selectedSector,
          });
          this.isSpinning = false;

          // Fallback: даем XP при ошибке
          this.game.xp += 15;
          this.game.showMessage(this.game.t('wheel_fallback_xp') || '+15 XP');
        }
      }, spinDuration);
    } catch (error) {
      ErrorHandler.handle(error, { type: 'wheel_spin' });
      this.isSpinning = false;
      this.game.showMessage(this.game.t('error_generic') || 'Помилка колеса');
    }
  }

  applyWheelResult(sector) {
    try {
      if (!sector || !sector.effect) {
        ErrorHandler.warn('Invalid sector in wheel result', { sector });
        return;
      }

      switch (sector.effect) {
        case 'xp':
          if (typeof sector.value === 'number') {
            this.game.xp += sector.value;
            this.game.incrementStat('totalXP', Math.max(0, sector.value));
            this.game.showMessage(
              this.game.t(sector.messageKey) || `XP: ${sector.value > 0 ? '+' : ''}${sector.value}`
            );
          }
          break;

        case 'bonus':
          if (sector.value && typeof this.game.getBonusInventorySnapshot === 'function') {
            const snapshot = this.game.getBonusInventorySnapshot();
            if (typeof snapshot[sector.value] === 'number') {
              this.game.grantBonus(sector.value, 1);
              if (this.game.bonusManager) {
                this.game.bonusManager.updateBonusesUI();
              }
              this.game.showMessage(this.game.t(sector.messageKey) || `+1 ${sector.value} bonus`);
            }
          }
          break;

        case 'multiplier':
          this.game.xpMultiplier = sector.multiplier || 2;
          this.game.xpMultiplierTurns = sector.turns || 3;
          this.game.updateMultiplierIndicator();
          this.game.showMessage(
            this.game.formatTemplate(sector.messageKey, { turns: this.game.xpMultiplierTurns }) ||
              `×${sector.multiplier} XP for ${sector.turns} turns`
          );
          break;

        case 'gift':
          const gifts = [
            { type: 'xp', value: 50, messageKey: 'wheel_gift_xp50' },
            { type: 'bonus', value: 'explosion', amount: 2, messageKey: 'wheel_gift_explosion2' },
            { type: 'xp', value: 30, messageKey: 'wheel_gift_xp30' },
          ];
          const gift = gifts[Math.floor(Math.random() * gifts.length)];

          if (gift.type === 'xp') {
            this.game.xp += gift.value;
            this.game.incrementStat('totalXP', gift.value);
            this.game.showMessage(this.game.t(gift.messageKey) || `Gift: +${gift.value} XP`);
          } else if (gift.type === 'bonus' && gift.value) {
            this.game.grantBonus(gift.value, gift.amount);
            if (this.game.bonusManager) {
              this.game.bonusManager.updateBonusesUI();
            }
            this.game.showMessage(this.game.t(gift.messageKey) || `Gift: +${gift.amount} ${gift.value}`);
          }
          break;

        case 'freeze': {
          if (!this.game.freezeSystem) {
            console.warn('FreezeSystem not initialized');
            break;
          }

          const turns = sector.value || 5;
          const result = this.game.freezeSystem.freezeRandomCell(turns);

          if (result && result.success) {
            // ✅ НОРМАЛЬНОЕ сообщение, БЕЗ {turns}
            this.game.showMessage(`❄️ Клетка заморожена на ${result.turns} ходов!`);

            // 🔄 обновляем визуал
            this.game.gridManager.updateFrozenStates();
          } else if (sector.fallbackXP) {
            // fallback — XP
            this.game.xp += sector.fallbackXP;
            this.game.incrementStat('totalXP', sector.fallbackXP);
            this.game.showMessage(`+${sector.fallbackXP} XP`);
          }

          break;
        }

        default:
          ErrorHandler.warn('Unknown wheel effect', { effect: sector.effect });
          // Fallback по умолчанию
          this.game.xp += 10;
          this.game.showMessage('+10 XP (default prize)');
      }

      this.game.updateXPBar();
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'wheel_result_application',
        sector,
      });

      // Fallback при ошибке применения результата
      this.game.xp += 15;
      this.game.showMessage(this.game.t('wheel_fallback_xp') || '+15 XP (error fallback)');
    }
  }

  highlightWheelSector(sectorIndex) {
    try {
      if (sectorIndex < 0 || sectorIndex >= this.wheelSectors.length) {
        ErrorHandler.warn('Invalid sector index for highlighting', {
          sectorIndex,
          sectorCount: this.wheelSectors.length,
        });
        return;
      }

      this.highlightedSectorIndex = sectorIndex;
      this.drawWheel();

      let blinkCount = 0;
      const maxBlinks = 3;

      const blink = () => {
        try {
          if (blinkCount >= maxBlinks * 2) {
            this.clearWheelHighlight();
            return;
          }

          // Мигание: четный счет - подсветка, нечетный - нет
          if (blinkCount % 2 === 0) {
            this.highlightedSectorIndex = sectorIndex;
          } else {
            this.highlightedSectorIndex = null;
          }

          this.drawWheel();
          blinkCount++;

          setTimeout(blink, 300);
        } catch (error) {
          ErrorHandler.handle(error, { type: 'wheel_highlight_blink', sectorIndex });
          this.clearWheelHighlight();
        }
      };

      blink();
    } catch (error) {
      ErrorHandler.handle(error, { type: 'wheel_highlight', sectorIndex });
    }
  }

  clearWheelHighlight() {
    try {
      this.highlightedSectorIndex = null;
      this.drawWheel();
    } catch (error) {
      ErrorHandler.handle(error, { type: 'wheel_highlight_clear' });
    }
  }

  closeWheel() {
    try {
      const wheelOverlay = document.getElementById('wheelOverlay');
      if (wheelOverlay) {
        wheelOverlay.classList.add('hidden');
      }

      const resultEl = document.getElementById('wheelResult');
      if (resultEl) {
        resultEl.textContent = '';
        resultEl.classList.add('hidden');
      }

      // Очищаем подсветку
      this.clearWheelHighlight();

      this.isSpinning = false;
      this.updateWheelUI();
    } catch (error) {
      ErrorHandler.handle(error, { type: 'wheel_close' });
    }
  }

  updateWheelUI() {
    try {
      const cost = this.getWheelCost();
      const remainingSpins = Math.max(0, (this.game.MAX_DAILY_SPINS || 20) - (this.game.wheelSpinsToday || 0));

      // Удаляем счетчик опыта (проблема 4)
      const xpLabel = document.getElementById('wheelXpLabel');
      if (xpLabel) {
        xpLabel.style.display = 'none';
      }

      const wheelCostLabel = document.getElementById('wheelCostLabel');
      if (wheelCostLabel) wheelCostLabel.textContent = cost;

      const wheelRemainingSpins = document.getElementById('wheelRemainingSpins');
      if (wheelRemainingSpins) {
        wheelRemainingSpins.textContent = `(${remainingSpins})`;
      }

      const spinBtn = document.getElementById('spinWheelBtn');
      if (spinBtn) {
        try {
          spinBtn.textContent = this.game.formatTemplate('btn_spin_wheel', { cost });
        } catch (e) {
          spinBtn.textContent = `Spin (${cost} XP)`;
        }
        spinBtn.disabled = this.isSpinning || (this.game.wheelSpinsToday || 0) >= (this.game.MAX_DAILY_SPINS || 20);
      }

      const dailyInfo = document.getElementById('wheelDailyInfo');
      if (dailyInfo) {
        try {
          dailyInfo.innerHTML = `
            ${this.game.formatTemplate('wheel_daily_limit', { used: this.game.wheelSpinsToday || 0, total: this.game.MAX_DAILY_SPINS || 20 })}<br>
            <small>${this.game.t('wheel_daily_reset')}</small>
          `;
        } catch (e) {
          dailyInfo.innerHTML = `Limit: ${this.game.wheelSpinsToday || 0}/${this.game.MAX_DAILY_SPINS || 20}<br><small>Resets daily</small>`;
        }
      }

      const wheelBtn = document.getElementById('bonus-wheel');
      if (wheelBtn) {
        wheelBtn.disabled = (this.game.wheelSpinsToday || 0) >= (this.game.MAX_DAILY_SPINS || 20);
        if (wheelBtn.disabled) {
          wheelBtn.style.opacity = '0.4';
          try {
            wheelBtn.title = this.game.t('wheel_limit_reached');
          } catch (e) {
            wheelBtn.title = 'Daily limit reached';
          }
        } else {
          wheelBtn.style.opacity = '1';
          try {
            wheelBtn.title = this.game.t('bonus_wheel_title');
          } catch (e) {
            wheelBtn.title = 'Wheel of Fortune';
          }
        }
      }

      // Обновляем стоимость прокрутки на игровом поле
      const gameWheelCost = document.getElementById('gameWheelCost');
      if (gameWheelCost) {
        gameWheelCost.textContent = cost;
      }
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'wheel_ui_update',
        cost,
        wheelSpinsToday: this.game.wheelSpinsToday,
        maxSpins: this.game.MAX_DAILY_SPINS,
      });
    }
  }

  // === НОВЫЕ МЕТОДЫ ДЛЯ ОБРАБОТКИ ОШИБОК ===

  // Валидация состояния колеса
  validateWheelState() {
    try {
      const issues = [];

      if (typeof this.game.wheelSpinsToday !== 'number' || this.game.wheelSpinsToday < 0) {
        issues.push(`Invalid wheelSpinsToday: ${this.game.wheelSpinsToday}`);
      }

      if (typeof this.game.MAX_DAILY_SPINS !== 'number' || this.game.MAX_DAILY_SPINS <= 0) {
        issues.push(`Invalid MAX_DAILY_SPINS: ${this.game.MAX_DAILY_SPINS}`);
      }

      if (this.game.wheelSpinsToday > this.game.MAX_DAILY_SPINS) {
        issues.push(`wheelSpinsToday exceeds limit: ${this.game.wheelSpinsToday} > ${this.game.MAX_DAILY_SPINS}`);
      }

      if (issues.length > 0) {
        ErrorHandler.warn('Wheel state validation failed', {
          type: 'wheel_validation',
          issues,
          wheelSpinsToday: this.game.wheelSpinsToday,
          MAX_DAILY_SPINS: this.game.MAX_DAILY_SPINS,
        });
        return false;
      }

      return true;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'wheel_validation_error' });
      return false;
    }
  }

  // Исправление состояния колеса
  repairWheelState() {
    try {
      ErrorHandler.info('Attempting to repair wheel state');

      let repaired = false;

      // Исправляем счетчик прокруток
      if (typeof this.game.wheelSpinsToday !== 'number' || this.game.wheelSpinsToday < 0) {
        this.game.wheelSpinsToday = 0;
        repaired = true;
      }

      // Исправляем лимит прокруток
      if (typeof this.game.MAX_DAILY_SPINS !== 'number' || this.game.MAX_DAILY_SPINS <= 0) {
        this.game.MAX_DAILY_SPINS = 20;
        repaired = true;
      }

      // Исправляем превышение лимита
      if (this.game.wheelSpinsToday > this.game.MAX_DAILY_SPINS) {
        this.game.wheelSpinsToday = this.game.MAX_DAILY_SPINS;
        repaired = true;
      }

      if (repaired) {
        ErrorHandler.info('Wheel state repaired', {
          wheelSpinsToday: this.game.wheelSpinsToday,
          MAX_DAILY_SPINS: this.game.MAX_DAILY_SPINS,
        });
        this.updateWheelUI();
      }

      return repaired;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'wheel_repair_failed' });
      return false;
    }
  }

  // Безопасное вращение колеса с fallback
  safeSpinWheel(fallbackPrize = 15) {
    try {
      return this.spinWheel();
    } catch (error) {
      ErrorHandler.handle(error, { type: 'safe_wheel_spin' });

      // Fallback: даем фиксированный приз при ошибке
      this.game.xp += fallbackPrize;
      this.game.showMessage(`+${fallbackPrize} XP (fallback prize)`);
      this.game.updateXPBar();
      return false;
    }
  }

  // Проверка доступности колеса
  isWheelAvailable() {
    try {
      return (
        (this.game.wheelSpinsToday || 0) < (this.game.MAX_DAILY_SPINS || 20) &&
        (this.game.xp || 0) >= this.getWheelCost()
      );
    } catch (error) {
      ErrorHandler.warn('isWheelAvailable failed', error);
      return false;
    }
  }

  // Сброс состояния колеса (для тестирования)
  resetWheelState() {
    try {
      this.isSpinning = false;
      this.currentRotation = 0;
      this.highlightedSectorIndex = null;
      this.updateWheelUI();
      ErrorHandler.info('Wheel state reset');
      return true;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'wheel_reset' });
      return false;
    }
  }
}
