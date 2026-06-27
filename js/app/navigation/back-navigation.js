LostNumberGame.prototype.handleBackNavigation = function () {
  try {
    if (this.menuManager?.dismissFeatureStubFromBack?.()) {
      return;
    }

    if (this.menuManager?.dismissNewGameConfirmFromBack?.()) {
      return;
    }

    const wheelOverlay = document.getElementById('wheelOverlay');
    if (wheelOverlay && !wheelOverlay.classList.contains('hidden')) {
      this.wheelManager?.closeWheel?.();
      return;
    }

    const levelOverlay = document.getElementById('levelOverlay');
    if (levelOverlay && !levelOverlay.classList.contains('hidden')) {
      levelOverlay.classList.add('hidden');
      this.requestSaveAndExitToMenu();
      return;
    }

    const victoryOverlay = document.getElementById('victoryOverlay');
    if (victoryOverlay && !victoryOverlay.classList.contains('hidden')) {
      this.hideVictory?.();
      this.showScreen('mainMenu');
      return;
    }

    const screen = this.screenState || 'mainMenu';

    if (screen === 'game') {
      this.audioManager?.playTap?.();
      this.requestSaveAndExitToMenu();
      return;
    }

    const secondaryScreens = ['settings', 'about', 'achievements', 'stats', 'dailyQuests'];
    if (secondaryScreens.includes(screen)) {
      this.audioManager?.playTap?.();
      this.showScreen('mainMenu');
      return;
    }

    const App = window.Capacitor?.Plugins?.App;
    if (App && typeof App.exitApp === 'function') {
      App.exitApp();
    } else if (App && typeof App.minimizeApp === 'function') {
      App.minimizeApp();
    }
  } catch (error) {
    ErrorHandler.handle(error, { type: 'back_navigation' });
  }
};

LostNumberGame.prototype.requestAppExit = function () {
  try {
    const App = window.Capacitor?.Plugins?.App;
    if (App && typeof App.exitApp === 'function') {
      App.exitApp();
      return;
    }
    if (App && typeof App.minimizeApp === 'function') {
      App.minimizeApp();
      return;
    }
    this.showMessage(this.t('exit_web_hint'));
  } catch (error) {
    ErrorHandler.handle(error, { type: 'app_exit' });
    this.showMessage(this.t('exit_web_hint'));
  }
};

LostNumberGame.prototype.setupNativeBackButton = function () {
  try {
    if (
      !window.Capacitor ||
      typeof window.Capacitor.isNativePlatform !== 'function' ||
      !window.Capacitor.isNativePlatform()
    ) {
      return;
    }

    const App = window.Capacitor.Plugins?.App;
    if (!App || typeof App.addListener !== 'function') {
      return;
    }

    if (this._backButtonListener) {
      return;
    }

    this._backButtonListener = App.addListener('backButton', () => {
      this.handleBackNavigation();
    });
  } catch (error) {
    ErrorHandler.warn('setupNativeBackButton failed', { error });
  }
};
