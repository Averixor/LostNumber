class ScreenManager {
  constructor(game) {
    this.game = game;
  }

  showScreen(name) {
    try {
      const wasGame = this.game.screenState === 'game';
      this.game.screenState = name;

      document.querySelectorAll('.screen').forEach((screen) => {
        try {
          screen.classList.add('hidden');
        } catch (error) {
          ErrorHandler.warn('Failed to hide screen', { screen: screen.id, error });
        }
      });

      const target = document.getElementById(name + 'Screen');
      if (target) {
        try {
          target.classList.remove('hidden');
          ErrorHandler.debug('Screen shown', { name, wasGame });
        } catch (error) {
          ErrorHandler.handle(error, { type: 'screen_show', name });
        }
      } else {
        ErrorHandler.warn('Screen not found', { name });
      }

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
          BackgroundRotator.onMainMenuEnter();
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
      const mainScreen = document.getElementById('mainMenuScreen');
      if (mainScreen) {
        mainScreen.classList.remove('hidden');
      }
    }
  }
}
