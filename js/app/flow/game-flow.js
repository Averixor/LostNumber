LostNumberGame.prototype.startNewGame = function () {
  try {
    this.initSeededRandom(true);

    this.currentLevel = 0;
    this.xp = 0;
    this.xpMultiplier = 1;
    this.xpMultiplierTurns = 0;
    this.resetBonusInventory();
    this.frozenCells.clear();
    if (this.freezeSystem && typeof this.freezeSystem.clearAll === 'function') {
      this.freezeSystem.clearAll();
    }
    this.stats = this.defaultStats();
    this.achievements = this.defaultAchievements();
    this.pendingTransition = null;

    this.maxReachedNumber = 8;
    this.carryNumber = null;

    this.checkWheelDailyReset();

    this.resetRuntimeState();

    this.gridManager.initGame(0);

    this.setGamePhase('playing');
    this.showScreen('game');

    this.updateTargetInfo();
    this.updateXPBar();
    if (this.bonusManager) {
      this.bonusManager.updateBonusesUI();
    }
    if (this.wheelManager) {
      this.wheelManager.updateWheelUI();
    }

    this.incrementStat('gamesPlayed', 1);
    this.saveGameState({ force: true });
  } catch (error) {
    ErrorHandler.handle(error, { type: 'new_game' });
    this.showScreen('mainMenu');
    this.showMessage(this.t('error_start_game'));
  }
};

LostNumberGame.prototype.mergeChain = function () {
  let removedCells = null;
  let mergeCellsCleared = false;

  try {
    const level = this.getLevelConfig(this.currentLevel);
    const sum = Chain.sum;
    const target = level.target;
    const isLevelComplete = sum >= target;
    const resultNumber = isLevelComplete ? target : sum;

    this.maxReachedNumber = Math.max(this.maxReachedNumber, resultNumber);

    const surplus = isLevelComplete ? Math.max(0, sum - target) : 0;

    if (Chain.numbers.length < 2) {
      this.resetChain('invalid');
      return;
    }

    if (!this.core.canFinishChain(Chain)) {
      this.resetChain('invalid');
      return;
    }

    const anchor = this.selected[this.selected.length - 1];
    removedCells = this.selected.slice(0, -1);
    const chainLen = this.selected.length;

    this.setGamePhase('animating');
    this.audioManager?.playChainComplete?.();

    this.grid[anchor.x][anchor.y].number = resultNumber;
    this.grid[anchor.x][anchor.y].merged = true;

    removedCells.forEach((cell) => {
      this.grid[cell.x][cell.y].number = null;
    });
    mergeCellsCleared = true;

    this.selected = [];
    Chain.numbers = [];
    Chain.sum = 0;

    this.hidePreviewBubble?.();
    this.gridManager.render();

    this.gridManager.runPostMergeEffects(removedCells, () => {
      try {
        const oldXp = this.xp;
        const xpEarned = this.calculateXP(chainLen);
        this.xp += xpEarned;

        if (xpEarned > 0) {
          this.audioManager?.playXp?.();
        }

        this.incrementStat('totalXP', xpEarned);
        this.incrementStat('totalMerges', 1);
        this.setStatMax('longestChain', chainLen);

        this.achievementManager.updateAchievementProgress('chain5', chainLen >= 5 ? 1 : 0);
        this.achievementManager.updateAchievementProgress('chain10', chainLen >= 10 ? 1 : 0);
        this.achievementManager.updateAchievementProgress('xp1000', xpEarned);
        this.achievementManager.updateAchievementProgress('xp5000', xpEarned);

        if (chainLen >= 5) {
          this.dailyQuestManager.completeDailyQuest('chain5');
        }

        if (this.xp >= 100 && oldXp < 100) {
          this.dailyQuestManager.completeDailyQuest('xp100');
        }

        if (surplus > 0) {
          this.xp += surplus;
          this.incrementStat('totalXP', surplus);
          this.showMessage(this.formatTemplate('surplus_xp', { surplus }));
        }

        this.updatePreviewBubble();

        this.updateXPBar();
        this.bonusManager.updateBonusesUI();

        if (this.xpMultiplierTurns > 0) {
          this.xpMultiplierTurns--;
          if (this.xpMultiplierTurns <= 0) {
            this.xpMultiplier = 1;
          }
          this.updateMultiplierIndicator();
        }

        this.gridManager.updateFrozenCells();

        this.gridManager.render();

        this.saveGameState({ force: true });

        if (this.gamePhase === 'animating') {
          this.setGamePhase('playing');
        }

        this.checkWin();
      } catch (callbackError) {
        ErrorHandler.handle(callbackError, { type: 'merge_chain_callback', chainLen });
        this.repairMergeGridState(removedCells);
        if (this.gamePhase === 'animating') {
          this.setGamePhase('playing');
        }
      }
    });
  } catch (error) {
    ErrorHandler.handle(error, { type: 'merge_chain', chainLength: Chain.numbers?.length ?? 0 });
    if (mergeCellsCleared) {
      this.repairMergeGridState(removedCells);
    }
    this._postMergeEffectsPending = false;
    if (this.gamePhase === 'animating') {
      this.setGamePhase('playing');
    }
    this.resetChain('error');
    this.flushDeferredSaveActions();
  }
};

LostNumberGame.prototype.checkWin = function () {
  try {
    const level = this.getLevelConfig(this.currentLevel);
    for (let x = 0; x < this.GRID_W; x++) {
      for (let y = 0; y < this.GRID_H; y++) {
        if (this.grid[x][y].number === level.target) {
          this.setGamePhase('win');
          this.handleLevelComplete();
          return;
        }
      }
    }
  } catch (error) {
    ErrorHandler.handle(error, { type: 'check_win', level: this.currentLevel });
  }
};

LostNumberGame.prototype.handleLevelComplete = function () {
  try {
    this.audioManager?.playVictory?.();

    const oldXp = this.xp;
    const level = this.getLevelConfig(this.currentLevel);
    const carryNumber = level.target;

    this.xp = oldXp;
    this.updateXPBar();
    this.bonusManager.updateBonusesUI();

    const prevLevelIndex = this.currentLevel;
    const prevLevelNumber = prevLevelIndex + 1;
    const nextLevelIndex = prevLevelIndex + 1;
    const nextLevelNumber = nextLevelIndex + 1;

    this.carryNumber = carryNumber;
    this.pendingTransition = {
      active: true,
      nextLevel: nextLevelIndex,
      carryNumber: carryNumber,
      completedLevelIndex: prevLevelIndex,
    };

    this.incrementStat('levelsCompleted', 1);
    this.setStatMax('highestLevel', nextLevelNumber);
    this.saveGameState({ force: true });

    this.achievementManager.updateAchievementProgress('level10', 1);
    this.achievementManager.updateAchievementProgress('level25', 1);
    this.achievementManager.updateAchievementProgress('firstGame', 1);

    this.dailyQuestManager.completeDailyQuest('completeLevel');

    const overlay = document.getElementById('levelOverlay');
    const title = document.getElementById('levelOverlayTitle');
    const text = document.getElementById('levelOverlayText');
    const stats = document.getElementById('levelStats');

    let power = 0;
    if (level.target > 0 && Number.isFinite(level.target)) {
      power = Math.round(Math.log2(level.target));
      if (!Number.isFinite(power) || power < 0) {
        power = 0;
      }
    }

    if (title) title.textContent = this.formatTemplate('level_completed_title');
    if (text)
      text.innerHTML = this.formatTemplate('level_new_number', {
        power: power,
        target: this.formatNumber(level.target),
      });

    let statsHtml = '';
    statsHtml +=
      this.formatTemplate('level_stats_points', { points: this.formatNumber(this.xp) }) + '<br/>';
    statsHtml += this.formatTemplate('level_stats_carry', {
      value: this.gridManager.formatCarryVisual(carryNumber),
    });
    if (stats) stats.innerHTML = statsHtml;

    if (overlay) overlay.classList.remove('hidden');

    this.gridManager.updateFrozenCells();
  } catch (error) {
    ErrorHandler.handle(error, { type: 'level_complete', level: this.currentLevel });
    this.completeLevelTransition();
  }
};

LostNumberGame.prototype.completeLevelTransition = function () {
  try {
    if (!this.pendingTransition || !this.pendingTransition.active) return;
    const nextLevelIndex = this.pendingTransition.nextLevel;
    const carry = this.pendingTransition.carryNumber ?? null;
    const completedLevelIndex =
      typeof this.pendingTransition.completedLevelIndex === 'number'
        ? this.pendingTransition.completedLevelIndex
        : Math.max(0, nextLevelIndex - 1);
    this.pendingTransition = null;

    this.currentLevel = nextLevelIndex;
    this.carryNumber = carry;
    this.gridManager.initGame(this.currentLevel);
    this.refreshLevelUI();
    this.saveGameState({ force: true });
  } catch (error) {
    ErrorHandler.handle(error, { type: 'level_transition', pending: this.pendingTransition });
    this.showScreen('mainMenu');
  }
};

LostNumberGame.prototype.refreshLevelUI = function () {
  try {
    this.updateTargetInfo?.();
    this.updateGoal?.();
    this.updateXPBar?.();
    this.updateMultiplierIndicator?.();
    if (this.bonusManager) this.bonusManager.updateBonusesUI();
    if (this.wheelManager) this.wheelManager.updateWheelUI();
  } catch (error) {
    ErrorHandler.warn('refreshLevelUI failed', { error });
  }
};
