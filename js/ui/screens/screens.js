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
        if (typeof this.game.saveGameState === 'function') {
          this.game.saveGameState();
        }
        this.game.resetRuntimeState();
      }

      if (name === 'mainMenu' && typeof this.game.checkExistingSave === 'function') {
        this.game.checkExistingSave();
      }
    } catch (error) {
      ErrorHandler.handle(error, { type: 'screen_manager', method: 'showScreen', name });
      const mainScreen = document.getElementById('mainMenuScreen');
      if (mainScreen) {
        mainScreen.classList.remove('hidden');
      }
    }
  }

  hideAllScreens() {
    try {
      document.querySelectorAll('.screen').forEach((screen) => {
        try {
          screen.classList.add('hidden');
        } catch (error) {}
      });
    } catch (error) {
      ErrorHandler.warn('hideAllScreens failed', error);
    }
  }

  safeShowScreen(name, fallbackName = 'mainMenu') {
    try {
      this.showScreen(name);
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'safe_screen_show',
        target: name,
        fallback: fallbackName,
      });

      try {
        this.showScreen(fallbackName);
      } catch (fallbackError) {
        ErrorHandler.warn('Fallback screen also failed', fallbackError);
      }
    }
  }

  screenExists(name) {
    try {
      return !!document.getElementById(name + 'Screen');
    } catch (error) {
      ErrorHandler.warn('screenExists failed', { name, error });
      return false;
    }
  }

  getAvailableScreens() {
    try {
      const screens = [];
      document.querySelectorAll('.screen').forEach((screen) => {
        try {
          const id = screen.id;
          if (id && id.endsWith('Screen')) {
            screens.push(id.replace('Screen', ''));
          }
        } catch (error) {}
      });
      return screens;
    } catch (error) {
      ErrorHandler.warn('getAvailableScreens failed', error);
      return ['mainMenu', 'game'];
    }
  }

  recoverUI() {
    try {
      ErrorHandler.info('Attempting UI recovery');

      this.showScreen('mainMenu');

      ErrorHandler.info('UI recovery completed');
      return true;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'ui_recovery_failed' });
      return false;
    }
  }
}
