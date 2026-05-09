// LostNumberGame class shell. Runtime methods are attached from js/app/*.js.

class LostNumberGame {
  constructor() {
    // === ИНИЦИАЛИЗАЦИЯ ERROR HANDLER В САМОМ НАЧАЛЕ ===
    this.initializeErrorHandler();

    // Инициализация менеджеров
    this.storageManager = new StorageManager();
    this.audioManager = new AudioManager();
    this.screenManager = new ScreenManager(this);
    this.menuManager = new MenuManager(this);
    this.settingsManager = new SettingsManager(this);
    this.overlayManager = new OverlayManager(this);

    // Floating background numbers state (can be disabled by user or auto-disabled by FPS).
    this.floatingNumbersEnabled = true;
    this.floatingNumbersDisabledBy = null; // null | "user" | "fps"

    // Инициализация игрового состояния
    this.state = new GameState();

    // Проксируем ТОЛЬКО state-data (без runtime/service полей).
    this._bindStateProxy();
    this._lockStateReference();

    // Seeded RNG (инициализируется в main.js)
    this.sessionSeed = 0;
    this.dailySeed = 0;
    this.currentSeed = 0;
    this.rng = null;

    this.core = new GameCore(this);
    this._initContext();

    this.initSeededRandom();

    // Инициализация менеджеров игровых систем
    this.gridManager = new GridManager(this);
    if (typeof this.gridManager.initFreezeSystem === 'function') {
      this.gridManager.initFreezeSystem();
    }
    this.bonusManager = new BonusManager(this);
    this.wheelManager = new WheelManager(this);
    this.achievementManager = new AchievementManager(this);
    this.dailyQuestManager = new DailyQuestManager(this);
    this.statsManager = null;

    // Привязка менеджеров
    this.state.gridManager = this.gridManager;
    this.refreshContextRefs();

    // Инициализация
    this.createFloatingNumbers = this.screenManager.createFloatingNumbers.bind(this.screenManager);
    this.showScreen = this.screenManager.showScreen.bind(this.screenManager);
    this.showMessage = this.overlayManager.showMessage.bind(this.overlayManager);
    this.updatePreviewBubble = this.overlayManager.updatePreviewBubble.bind(this.overlayManager);
    this.hidePreviewBubble = this.overlayManager.hidePreviewBubble.bind(this.overlayManager);
    this.showVictory = this.overlayManager.showVictory.bind(this.overlayManager);
    this.hideVictory = this.overlayManager.hideVictory.bind(this.overlayManager);

    // Явное копирование методов из GameState
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
    this.defaultStats = this.state.defaultStats.bind(this.state);
    this.defaultAchievements = this.state.defaultAchievements.bind(this.state);
    this.setGamePhase = this.state.setGamePhase.bind(this.state);
    this.resetRuntimeState = this.state.resetRuntimeState.bind(this.state);

    // Инициализация ежедневных заданий
    this.dailyQuests = this.dailyQuestManager.loadDailyQuests();

    // ДОБАВЛЕНО: Методы для обратной совместимости
    this.updateAchievementProgress = this.updateAchievementProgress.bind(this);
    this.updateBonusesUI = this.updateBonusesUI.bind(this);
    this.completeDailyQuest = this.completeDailyQuest.bind(this);

    this.isFirstRun = this.storageManager.isFirstRun();
    if (this.isFirstRun) {
      this.storageManager.markFirstRunComplete();
    }

    // ЗАГРУЖАЕМ НАСТРОЙКИ ПЕРВЫМИ
    this.settingsManager.loadSettings();

    // Применяем настройки к текущей сессии
    this.applyLanguage(this.lang || 'ua');
    this.applyTheme();

    // Применяем настройки звука
    if (this.audioManager) {
      this.audioManager.setSoundEnabled(this.soundEnabled);
      this.audioManager.updateSoundStateUI();
    }

    // Применяем настройки анимаций
    if (!this.animationEnabled) {
      document.body.classList.add('no-animations');
    }

    // Создаем фоновые эффекты только если разрешены
    if (this.floatingNumbersEnabled !== false) {
      this.createFloatingNumbers();
    }

    this.setupUI();
    this.checkExistingSave();
    this.showScreen('mainMenu');

    this._installFloatingNumbersAutoDisableListener();

    this._scheduleLazySideModules();

    // Error boundaries
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
          'WheelManager.spinWheel'
        );
        ErrorBoundary.wrap(
          this.bonusManager,
          'activateBonus',
          () => {
            this.showMessage(this.t('bonus_error') || 'Бонус недоступний');
          },
          'BonusManager.activateBonus'
        );
        ErrorBoundary.wrap(this.storageManager, 'loadGameState', () => null, 'StorageManager.loadGameState');
        ErrorBoundary.wrap(this.storageManager, 'saveGameState', () => {}, 'StorageManager.saveGameState');
      }
    } catch (e) {
      ErrorHandler.warn('ErrorBoundary setup failed', e);
    }

    document.addEventListener('contextmenu', (e) => e.preventDefault());
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
      eventBus: typeof window !== 'undefined' ? window.EventBus || null : null,
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
    this.context.eventBus = typeof window !== 'undefined' ? window.EventBus || null : null;

    return this.context;
  }

  getContext() {
    return this.context || this.refreshContextRefs();
  }

  _installFloatingNumbersAutoDisableListener() {
    try {
      window.addEventListener('lostnumber:floating-numbers-auto-disable', (e) => {
        try {
          if (this.floatingNumbersEnabled === false) return;
          this.floatingNumbersEnabled = false;
          this.floatingNumbersDisabledBy = 'fps';

          if (this.settingsManager && typeof this.settingsManager.applyFloatingNumbers === 'function') {
            this.settingsManager.applyFloatingNumbers();
          }
          if (this.settingsManager && typeof this.settingsManager.saveSettings === 'function') {
            this.settingsManager.saveSettings();
          }

          const averageFps = e?.detail?.averageFps;
          const critical = !!e?.detail?.critical;
          ErrorHandler.info('Floating numbers auto-disabled due to low FPS', {
            averageFps,
            critical,
            reason: 'fps',
          });
          try {
            this.showMessage?.('FPS просів — фонові цифри вимкнено');
          } catch (_) {}
        } catch (err) {
          ErrorHandler.warn('Auto-disable floating numbers failed', { err });
        }
      });
    } catch (error) {
      ErrorHandler.warn('_installFloatingNumbersAutoDisableListener failed', { error });
    }
  }

  /**
   * Модулі, які не потрібні для першого кадру меню: stats (екран статистики), DebugOverlay (лише dev).
   * daily/achievements/overlays лишаються синхронними — їх очікує конструктор, save-load і game-flow.
   */
  _scheduleLazySideModules() {
    const run = () => {
      try {
        const statsPromise =
          typeof StatsManager !== 'undefined'
            ? Promise.resolve()
            : typeof window.LN_loadScriptOnce === 'function'
              ? window.LN_loadScriptOnce('js/game/stats.js')
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
            .LN_loadScriptOnce('js/ui/DebugOverlay.js')
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
