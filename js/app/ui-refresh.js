LostNumberGame.prototype.updateTargetInfo = function () {
  try {
    const levelIndex = Math.max(0, Math.floor(Number(this.currentLevel) || 0));
    const level = this.getLevelConfig(levelIndex);
    const target = Number(level?.target);
    const targetValue = document.getElementById('targetValue');
    const levelLabel = document.getElementById('levelLabel');

    if (targetValue && Number.isFinite(target) && target > 0) {
      targetValue.textContent = this.formatNumber(target);
    } else if (targetValue) {
      targetValue.textContent = this.formatNumber(64);
    }
    if (levelLabel) {
      levelLabel.textContent = this.formatTemplate('level_label', {
        level: levelIndex + 1,
      });
    }
  } catch (error) {
    ErrorHandler.warn('updateTargetInfo failed', error);
  }
};

LostNumberGame.prototype.updateXPBar = function () {
  try {
    const bar = document.getElementById('xpBar');
    const txt = document.getElementById('xpText');
    if (bar && txt) {
      bar.style.width = '100%';
      const xpText = this.formatTemplate('xp_label', { xp: this.formatNumber(this.xp) });
      txt.textContent = xpText;
      this.updateMultiplierIndicator();
    }
  } catch (error) {
    ErrorHandler.warn('updateXPBar failed', error);
  }
};

LostNumberGame.prototype.updateMultiplierIndicator = function () {
  try {
    const indicator = document.getElementById('xpMultiplierIndicator');

    if (!indicator) return;

    if (this.xpMultiplier > 1 && this.xpMultiplierTurns > 0) {
      indicator.style.display = 'block';
      const label = this.formatTemplate('xp_multiplier_active', {
        multiplier: this.xpMultiplier,
        turns: this.xpMultiplierTurns,
      });
      const firstText = indicator.firstChild;
      if (firstText && firstText.nodeType === Node.TEXT_NODE) {
        firstText.textContent = label;
      } else {
        indicator.insertBefore(document.createTextNode(label), indicator.firstChild);
      }
    } else {
      indicator.style.display = 'none';
    }
  } catch (error) {
    ErrorHandler.warn('updateMultiplierIndicator failed', error);
  }
};

LostNumberGame.prototype.updateGoal = function () {
  this.updateTargetInfo();
};

LostNumberGame.prototype.updateAchievementProgress = function (key, value = 1) {
  try {
    if (this.achievementManager) {
      this.achievementManager.updateAchievementProgress(key, value);
    }
  } catch (error) {
    ErrorHandler.handle(error, { type: 'achievement', key, value });
  }
};

LostNumberGame.prototype.updateBonusesUI = function () {
  try {
    if (this.bonusManager) {
      this.bonusManager.updateBonusesUI();
    }
  } catch (error) {
    ErrorHandler.handle(error, { type: 'bonus_ui' });
  }
};

LostNumberGame.prototype.completeDailyQuest = function (id) {
  try {
    if (this.dailyQuestManager) {
      return this.dailyQuestManager.completeDailyQuest(id);
    }
    return false;
  } catch (error) {
    ErrorHandler.handle(error, { type: 'daily_quest', id });
    return false;
  }
};
