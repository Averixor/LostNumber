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
        this.game.resetRuntimeState();
      }
    } catch (error) {
      ErrorHandler.handle(error, { type: 'screen_manager', method: 'showScreen', name });
      // Fallback: показываем главный экран
      const mainScreen = document.getElementById('mainMenuScreen');
      if (mainScreen) {
        mainScreen.classList.remove('hidden');
      }
    }
  }

  createFloatingNumbers() {
    try {
      if (this.game && this.game.floatingNumbersEnabled === false) {
        const container = document.getElementById('floatingHearts');
        if (container) container.innerHTML = '';
        return;
      }

      const container = document.getElementById('floatingHearts');
      if (!container) {
        ErrorHandler.warn('Floating numbers container not found');
        return;
      }

      const count = typeof PlatformDetector !== 'undefined' && PlatformDetector.isMobile?.() ? 6 : 14;
      const symbols = ['2', '4', '8', '16', '32', '64', '128'];

      // Очищаем старые элементы
      container.innerHTML = '';

      for (let i = 0; i < count; i++) {
        const h = document.createElement('div');
        h.className = 'floating-heart';
        h.textContent = symbols[Math.floor(Math.random() * symbols.length)];
        h.style.left = Math.random() * 100 + 'vw';
        h.style.top = Math.random() * 100 + 'vh';
        h.style.animationDelay = Math.random() * 7 + 's';
        h.style.fontSize = 0.9 + Math.random() * 1.2 + 'rem';

        try {
          container.appendChild(h);
        } catch (error) {
          ErrorHandler.warn('Failed to append floating number', error);
        }
      }

      ErrorHandler.debug('Floating numbers created', { count });
    } catch (error) {
      ErrorHandler.handle(error, { type: 'screen_manager', method: 'createFloatingNumbers' });
    }
  }

  // === НОВЫЕ МЕТОДЫ ДЛЯ ОБРАБОТКИ ОШИБОК ===

  // Безопасное скрытие всех экранов
  hideAllScreens() {
    try {
      document.querySelectorAll('.screen').forEach((screen) => {
        try {
          screen.classList.add('hidden');
        } catch (error) {
          // Игнорируем ошибки скрытия
        }
      });
    } catch (error) {
      ErrorHandler.warn('hideAllScreens failed', error);
    }
  }

  // Показ экрана с fallback
  safeShowScreen(name, fallbackName = 'mainMenu') {
    try {
      this.showScreen(name);
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'safe_screen_show',
        target: name,
        fallback: fallbackName,
      });

      // Показываем fallback экран
      try {
        this.showScreen(fallbackName);
      } catch (fallbackError) {
        ErrorHandler.warn('Fallback screen also failed', fallbackError);
      }
    }
  }

  // Проверка существования экрана
  screenExists(name) {
    try {
      return !!document.getElementById(name + 'Screen');
    } catch (error) {
      ErrorHandler.warn('screenExists failed', { name, error });
      return false;
    }
  }

  // Список доступных экранов
  getAvailableScreens() {
    try {
      const screens = [];
      document.querySelectorAll('.screen').forEach((screen) => {
        try {
          const id = screen.id;
          if (id && id.endsWith('Screen')) {
            screens.push(id.replace('Screen', ''));
          }
        } catch (error) {
          // Пропускаем ошибки
        }
      });
      return screens;
    } catch (error) {
      ErrorHandler.warn('getAvailableScreens failed', error);
      return ['mainMenu', 'game']; // Минимальный набор
    }
  }

  // Восстановление UI после ошибки
  recoverUI() {
    try {
      ErrorHandler.info('Attempting UI recovery');

      this.showScreen('mainMenu');
      this.createFloatingNumbers();

      ErrorHandler.info('UI recovery completed');
      return true;
    } catch (error) {
      ErrorHandler.handle(error, { type: 'ui_recovery_failed' });
      return false;
    }
  }
}
