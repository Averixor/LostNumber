class ScreenManager {
  constructor(game) {
    this.game = game;
  }

  setActiveScreenDatasets(name) {
    if (document.body) {
      document.body.dataset.activeScreen = name;
    }
    if (document.documentElement) {
      document.documentElement.dataset.activeScreen = name;
    }
  }

  hideAllScreens() {
    document.querySelectorAll('.screen').forEach((screen) => {
      try {
        screen.classList.add('hidden');
        screen.classList.remove('is-active');
        screen.setAttribute('aria-hidden', 'true');
      } catch (error) {
        ErrorHandler.warn('Failed to hide screen', { screen: screen.id, error });
      }
    });
  }

  showScreen(name) {
    try {
      const wasGame = this.game.screenState === 'game';
      this.game.screenState = name;

      this.hideAllScreens();

      const target = document.getElementById(name + 'Screen');
      if (target) {
        try {
          target.classList.remove('hidden');
          target.classList.add('is-active');
          target.setAttribute('aria-hidden', 'false');
          ErrorHandler.debug('Screen shown', { name, wasGame });
        } catch (error) {
          ErrorHandler.handle(error, { type: 'screen_show', name });
        }
      } else {
        ErrorHandler.warn('Screen not found', { name });
      }

      this.setActiveScreenDatasets(name);

      if (wasGame && name !== 'game') {
        if (typeof this.game.requestSaveGameState === 'function') {
          this.game.requestSaveGameState();
        } else if (typeof this.game.saveGameState === 'function') {
          this.game.saveGameState();
        }
        this.game.resetRuntimeState();
      }

      if (name === 'mainMenu') {
        if (typeof BackgroundRotator !== 'undefined') {
          BackgroundRotator.onMainMenuEnter(this.game.theme);
        }
        if (typeof this.game.checkExistingSave === 'function') {
          this.game.checkExistingSave();
        }
        if (typeof this.game.menuManager?.refreshMainMenuUI === 'function') {
          this.game.menuManager.refreshMainMenuUI();
        }
      }
    } catch (error) {
      ErrorHandler.handle(error, { type: 'screen_manager', method: 'showScreen', name });
      this.hideAllScreens();
      const fallback = document.getElementById('mainMenuScreen');
      if (fallback) {
        fallback.classList.remove('hidden');
        fallback.classList.add('is-active');
        fallback.setAttribute('aria-hidden', 'false');
      }
      this.setActiveScreenDatasets('mainMenu');
    }
  }
}
