(function () {
  if (typeof window.ErrorHandler !== 'undefined') {
    if (window.AppEnv?.isDev) {
      console.log('Main ErrorHandler available, skipping fallback');
    }
    return;
  }

  if (window.AppEnv?.isDev) {
    console.log('Loading fallback ErrorHandler...');
  }

  const errorHistory = [];
  const maxHistorySize = 50;

  const addToHistory = (error, context) => {
    errorHistory.push({
      timestamp: Date.now(),
      error: error instanceof Error ? error.message : String(error),
      context: context,
      stack: error instanceof Error ? error.stack : null,
    });

    if (errorHistory.length > maxHistorySize) {
      errorHistory.shift();
    }
  };

  const safeLog = (...args) => {
    try {
      console.log(...args);
    } catch (_) {}
  };

  window.ErrorHandler = {
    _installed: false,
    _isFallback: true,
    _game: null,

    handle: function (error, context) {
      try {
        console.error('[LostNumber ERROR]', error);
        if (context) console.error('[Context]', context);

        addToHistory(error, context);

        try {
          if (window.game && typeof window.game.showMessage === 'function') {
            const message = window.game.t
              ? window.game.t('error_generic') || 'Произошла ошибка. Игра продолжается.'
              : 'Произошла ошибка. Игра продолжается.';
            window.game.showMessage(message);
          }
        } catch (e) {
          safeLog('Could not show error message:', e);
        }
      } catch (e) {
        safeLog('Error in fallback handler:', e);
      }
    },

    wrap: function (obj, methodName, fallback, label) {
      if (!obj || !methodName) return;

      const original = obj[methodName];
      if (typeof original !== 'function') return;

      const handler = this;
      obj[methodName] = function (...args) {
        try {
          return original.apply(this, args);
        } catch (error) {
          handler.handle(error, {
            where: label || methodName,
            args: args.slice(0, 3),
          });
          return typeof fallback === 'function' ? fallback() : (fallback ?? null);
        }
      };
    },

    setGame: function (game) {
      this._game = game;
    },

    install: function (config) {
      try {
        if (this._installed) return;
        this._installed = true;

        if (window.AppEnv?.isDev) {
          console.log('Fallback ErrorHandler installed with config:', config);
        }

        window.addEventListener('error', (e) => {
          this.handle(e.error || e.message, { type: 'global' });
        });

        window.addEventListener('unhandledrejection', (e) => {
          this.handle(e.reason, { type: 'promise' });
        });

        safeLog('Fallback ErrorHandler installed');
      } catch (e) {
        safeLog('Failed to install fallback:', e);
      }
    },

    warn: function (msg, data) {
      console.warn('[LostNumber WARN]', msg, data);
    },

    info: function (msg, data) {
      console.info('[LostNumber INFO]', msg, data);
    },

    debug: function (msg, data) {
      console.debug('[LostNumber DEBUG]', msg, data);
    },

    setConfig: function (config) {},

    getErrorHistory: function () {
      return [...errorHistory];
    },

    clearErrorHistory: function () {
      errorHistory.length = 0;
    },

    getErrorStats: function () {
      const now = Date.now();
      const lastHour = now - 3600000;

      return {
        totalErrors: errorHistory.length,
        errorsLastHour: errorHistory.filter((e) => e.timestamp > lastHour).length,
        latestError: errorHistory[errorHistory.length - 1],
      };
    },

    safeExecute: function (fn, context, fallback) {
      try {
        return fn();
      } catch (error) {
        this.handle(error, {
          type: 'safe_execute',
          functionName: fn.name || 'anonymous',
          context,
        });
        return typeof fallback === 'function' ? fallback() : fallback;
      }
    },

    safePromise: function (promise, context) {
      return promise
        .then((result) => result)
        .catch((error) => {
          this.handle(error, {
            type: 'safe_promise',
            context,
          });
          throw error;
        });
    },
  };

  setTimeout(() => {
    try {
      // If the main ErrorHandler replaced the fallback by now, do nothing.
      if (typeof window.ErrorHandler !== 'undefined' && !window.ErrorHandler._isFallback) {
        if (window.AppEnv?.isDev) {
          console.log('Main ErrorHandler installed during timeout, using main');
        }
        return;
      }

      window.ErrorHandler.install();
    } catch (e) {
      safeLog('Auto-install failed:', e);
    }
  }, 500);
})();
