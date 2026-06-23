class LostNumberGame {
  constructor() {
    this.storageManager = new StorageManager();
    this.audioManager = new AudioManager();
    this.screenManager = new ScreenManager(this);
    this.menuManager = new MenuManager(this);
    this.settingsManager = new SettingsManager(this);
    this.overlayManager = new OverlayManager(this);

    this.state = new GameState();

    this._bindStateProxy();
    this._lockStateReference();

    this.sessionSeed = 0;
    this.dailySeed = 0;
    this.currentSeed = 0;
    this.rng = null;

    this.core = new GameCore(this);
    this._initContext();

    this.initSeededRandom();

    this.gridManager = new GridManager(this);
    if (typeof this.gridManager.initFreezeSystem === 'function') {
      this.gridManager.initFreezeSystem();
    }
    this.bonusManager = new BonusManager(this);
    this.wheelManager = new WheelManager(this);
    this.achievementManager = new AchievementManager(this);
    this.dailyQuestManager = new DailyQuestManager(this);
    this.statsManager = null;

    this.state.gridManager = this.gridManager;
    this.refreshContextRefs();

    this.createFloatingNumbers = function () {};
    this.showScreen = this.screenManager.showScreen.bind(this.screenManager);
    this.showMessage = this.overlayManager.showMessage.bind(this.overlayManager);
    this.updatePreviewBubble = this.overlayManager.updatePreviewBubble.bind(this.overlayManager);
    this.hidePreviewBubble = this.overlayManager.hidePreviewBubble.bind(this.overlayManager);
    this.showVictory = this.overlayManager.showVictory.bind(this.overlayManager);
    this.hideVictory = this.overlayManager.hideVictory.bind(this.overlayManager);

    this.initializeErrorHandler();
    this.wrapCriticalMethods();

    this.formatNumber = this.state.formatNumber.bind(this.state);
    this.getWheelCost = this.wheelManager.getWheelCost.bind(this.wheelManager);
    this.checkWheelDailyReset = this.state.checkWheelDailyReset.bind(this.state);
    this.baseXPByLen = this.state.baseXPByLen.bind(this.state);
    this.levelXPMult = this.state.levelXPMult.bind(this.state);
    this.calculateXP = this.state.calculateXP.bind(this.state);
    this.getAllowedNumbers = this.state.getAllowedNumbers.bind(this.state);
    this.generateCellNumber = this.state.generateCellNumber.bind(this.state);
    this.pickWeighted = this.state.pickWeighted.bind(this.state);
    this.getTodayKey = this.state.getTodayKey.bind(this.state);
    this.generateAASuffix = this.state.generateAASuffix.bind(this.state);
    this.generateLevels = this.state.generateLevels.bind(this.state);
    this.getLevelConfig = this.state.getLevelConfig.bind(this.state);
    this.getMinimumTileForLevel = this.state.getMinimumTileForLevel.bind(this.state);
    this.getMinimumSpawnTile = this.state.getMinimumSpawnTile.bind(this.state);
    this.defaultStats = this.state.defaultStats.bind(this.state);
    this.defaultAchievements = this.state.defaultAchievements.bind(this.state);
    this.setGamePhase = this.state.setGamePhase.bind(this.state);
    this.resetRuntimeState = this.state.resetRuntimeState.bind(this.state);

    this.dailyQuests = this.dailyQuestManager.loadDailyQuests();

    this.updateAchievementProgress = this.updateAchievementProgress.bind(this);
    this.updateBonusesUI = this.updateBonusesUI.bind(this);
    this.completeDailyQuest = this.completeDailyQuest.bind(this);

    this.isFirstRun = this.storageManager.isFirstRun();
    if (this.isFirstRun) {
      this.storageManager.markFirstRunComplete();
    }

    this.settingsManager.loadSettings();

    this.applyLanguage(this.lang || 'ua');
    this.applyTheme();

    if (this.audioManager) {
      this.audioManager.setSoundEnabled(this.soundEnabled);
      this.audioManager.updateSoundStateUI();
    }

    if (!this.animationEnabled) {
      document.body.classList.add('no-animations');
    }

    this.setupUI();
    this.checkExistingSave();
    this.showScreen('mainMenu');

    this._scheduleLazySideModules();

    try {
      if (typeof ErrorBoundary !== 'undefined') {
        ErrorBoundary.wrap(this.core, 'validateMove', () => false, 'GameCore.validateMove');
        ErrorBoundary.wrap(this.gridManager, 'render', () => {}, 'GridManager.render');
        ErrorBoundary.wrap(
          this.wheelManager,
          'spinWheel',
          () => {
            this.xp += 15;
            this.updateXPBar();
            this.showMessage(this.t('wheel_fallback_xp') || '+15 XP');
          },
          'WheelManager.spinWheel',
        );
        ErrorBoundary.wrap(
          this.bonusManager,
          'activateBonus',
          () => {
            this.showMessage(this.t('bonus_error') || 'Бонус недоступний');
          },
          'BonusManager.activateBonus',
        );
        ErrorBoundary.wrap(
          this.storageManager,
          'loadGameState',
          () => null,
          'StorageManager.loadGameState',
        );
        ErrorBoundary.wrap(
          this.storageManager,
          'saveGameState',
          () => {},
          'StorageManager.saveGameState',
        );
      }
    } catch (e) {
      ErrorHandler.warn('ErrorBoundary setup failed', e);
    }

    document.getElementById('grid')?.addEventListener('contextmenu', (e) => {
      if (this.isDragging) e.preventDefault();
    });
  }

  _bindStateProxy() {
    const stateKeys = [
      'GRID_W',
      'GRID_H',
      'MAX_DAILY_SPINS',
      'levels',
      'MAX_LEVEL',
      'currentLevel',
      'xp',
      'xpMultiplier',
      'xpMultiplierTurns',
      'maxReachedNumber',
      'carryNumber',
      'grid',
      'selected',
      'isDragging',
      'activeBonus',
      'bonusInventory',
      'frozenCells',
      'stats',
      'achievements',
      'pendingTransition',
      'hasSave',
      'wheelSpinsToday',
      'lastWheelDay',
      'animationEnabled',
      'lang',
      'soundEnabled',
      'theme',
      'liteVisualMode',
      'sessionSeed',
      'dailySeed',
      'currentSeed',
      'rng',
      'screenState',
      'gamePhase',
      'gameState',
      'dailyQuests',
    ];

    stateKeys.forEach((key) => {
      const descriptor = Object.getOwnPropertyDescriptor(this, key);
      if (descriptor && descriptor.configurable === false) return;

      Object.defineProperty(this, key, {
        enumerable: true,
        configurable: true,
        get: () => this.state[key],
        set: (v) => {
          this.state[key] = v;
        },
      });
    });
  }

  _lockStateReference() {
    const descriptor = Object.getOwnPropertyDescriptor(this, 'state');
    if (!descriptor || descriptor.writable !== false) {
      Object.defineProperty(this, 'state', {
        value: this.state,
        writable: false,
        enumerable: true,
        configurable: false,
      });
    }
  }

  _initContext() {
    this.context = {
      game: this,
      state: this.state,
      core: this.core || null,
      gridManager: this.gridManager || null,
      storageManager: this.storageManager || null,
      audioManager: this.audioManager || null,
    };
  }

  refreshContextRefs() {
    if (!this.context) {
      this._initContext();
    }

    this.context.game = this;
    this.context.state = this.state;
    this.context.core = this.core || null;
    this.context.gridManager = this.gridManager || null;
    this.context.storageManager = this.storageManager || null;
    this.context.audioManager = this.audioManager || null;

    return this.context;
  }

  getContext() {
    return this.context || this.refreshContextRefs();
  }

  _scheduleLazySideModules() {
    const run = () => {
      try {
        const statsPromise =
          typeof StatsManager !== 'undefined'
            ? Promise.resolve()
            : typeof window.LN_loadScriptOnce === 'function'
              ? window.LN_loadScriptOnce('js/game/meta/stats.js')
              : Promise.resolve();

        statsPromise
          .then(() => {
            try {
              if (!this.statsManager && typeof StatsManager !== 'undefined') {
                this.statsManager = new StatsManager(this);
              }
              if (typeof this.scheduleNonCriticalI18nRender === 'function') {
                this.scheduleNonCriticalI18nRender();
              }
            } catch (e) {
              ErrorHandler.warn('Lazy stats init failed', e);
            }
          })
          .catch((e) => {
            ErrorHandler.warn('Lazy stats script failed', e);
          });

        if (window.AppEnv?.isDev === true && typeof window.LN_loadScriptOnce === 'function') {
          window
            .LN_loadScriptOnce('js/ui/overlays/DebugOverlay.js')
            .then(() => {
              try {
                if (typeof DebugOverlay !== 'undefined') {
                  this.debugOverlay = new DebugOverlay(this);
                  this.debugOverlay.init();
                }
              } catch (e) {
                ErrorHandler.warn('DebugOverlay init failed', e);
              }
            })
            .catch((e) => ErrorHandler.warn('DebugOverlay script failed', e));
        }
      } catch (e) {
        ErrorHandler.warn('_scheduleLazySideModules failed', e);
      }
    };

    if (typeof requestIdleCallback === 'function') {
      requestIdleCallback(run, { timeout: 2000 });
    } else {
      setTimeout(run, 0);
    }
  }
}
