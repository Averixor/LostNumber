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

    // Инициализация игрового состояния
    this.state = new GameState();

    // Seeded RNG (инициализируется в main.js)
    this.sessionSeed = 0;
    this.dailySeed = 0;
    this.currentSeed = 0;
    this.rng = null;

    this.core = new GameCore(this);

    this.initSeededRandom();

    // Копируем свойства из состояния для обратной совместимости
    Object.assign(this, this.state);

    // Инициализация менеджеров игровых систем
    this.gridManager = new GridManager(this);
    this.bonusManager = new BonusManager(this);
    this.wheelManager = new WheelManager(this);
    this.achievementManager = new AchievementManager(this);
    this.dailyQuestManager = new DailyQuestManager(this);
    this.statsManager = new StatsManager(this);

    // Привязка менеджеров
    this.state.gridManager = this.gridManager;

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
    this.getWheelCost = this.state.getWheelCost.bind(this.state);
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

    this.createFloatingNumbers();

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

    this.setupUI();
    this.checkExistingSave();
    this.showScreen('mainMenu');

    // Debug overlay (Ctrl+D) — только в dev режиме или при ?dev=1
    try {
      if (typeof DebugOverlay !== 'undefined') {
        this.debugOverlay = new DebugOverlay(this);
        this.debugOverlay.init();
      }
    } catch (e) {
      ErrorHandler.warn('DebugOverlay init failed', e);
    }

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
}
