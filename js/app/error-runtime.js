// Error Runtime: LostNumberGame prototype methods.

LostNumberGame.prototype.initializeErrorHandler = function () {
  try {
    const isDev =
      (window.AppEnv && window.AppEnv.isDev === true) ||
      (typeof window.LN_isLocalDevEnvironment === 'function' && window.LN_isLocalDevEnvironment());

    if (window.ErrorHandlerConfig) {
      ErrorHandler.setConfig(window.ErrorHandlerConfig);
    } else {
      ErrorHandler.setConfig({
        showUserMessages: !isDev,
        logToConsole: isDev,
        maxErrorsPerMinute: isDev ? 100 : 50,
        collectStackTraces: true,
        onErrorReport: isDev ? null : this.reportErrorToAnalytics.bind(this),
      });
    }

    ErrorHandler.setGame(this);
    ErrorHandler.install();

    ErrorHandler.info('ErrorHandler initialized', {
      mode: isDev ? 'development' : 'production',
    });
  } catch (error) {
    console.error('Failed to initialize ErrorHandler:', error);
    // Используем fallback если основной не загрузился
    if (typeof ErrorHandlerFallback !== 'undefined') {
      window.ErrorHandler = ErrorHandlerFallback;
    }
  }
};

LostNumberGame.prototype.wrapCriticalMethods = function () {
  if (this._criticalMethodsWrapped) {
    return;
  }
  this._criticalMethodsWrapped = true;

  // Обертываем методы GameCore
  this.wrapMethod(this.core, 'validateMove', 'GameCore.validateMove');
  this.wrapMethod(this.core, 'canFinishChain', 'GameCore.canFinishChain');

  // Обертываем методы UI
  if (this.showMessage) {
    const originalShowMessage = this.showMessage;
    this.showMessage = function (...args) {
      try {
        return originalShowMessage.apply(this, args);
      } catch (error) {
        ErrorHandler.handle(error, {
          type: 'ui_error',
          method: 'showMessage',
          args: args.slice(0, 3), // берем первые 3 аргумента
        });
        // Fallback: простой alert если все сломалось
        if (typeof alert === 'function') {
          alert(args[0] || 'Error');
        }
      }
    }.bind(this);
  }

  // Обертываем методы сохранения
  if (this.saveGameState) {
    const originalSave = this.saveGameState;
    this.saveGameState = function () {
      try {
        return originalSave.apply(this, arguments);
      } catch (error) {
        ErrorHandler.handle(error, {
          type: 'save_error',
          method: 'saveGameState',
        });
        // Продолжаем работу даже если сохранение не удалось
      }
    }.bind(this);
  }
};

LostNumberGame.prototype.wrapMethod = function (obj, methodName, label) {
  if (!obj || !obj[methodName] || typeof obj[methodName] !== 'function') {
    return;
  }

  const originalMethod = obj[methodName];
  obj[methodName] = function (...args) {
    try {
      return originalMethod.apply(this, args);
    } catch (error) {
      ErrorHandler.handle(error, {
        type: 'method_error',
        method: label || methodName,
        args: args.slice(0, 5), // ограничиваем размер аргументов
      });

      // Возвращаем безопасное значение в зависимости от метода
      if (methodName.includes('validateMove')) return { valid: false, reason: 'error' };
      if (methodName.includes('validate')) return false;
      if (methodName.includes('calculate')) return 0;
      if (methodName.includes('get')) return null;

      throw error; // Пробрасываем дальше для остальных случаев
    }
  };
};

LostNumberGame.prototype.reportErrorToAnalytics = function (errorData) {
  try {
    // Проверяем, нужно ли отправлять (только важные ошибки)
    const importantErrors = ['resource', 'runtime', 'promise'];
    if (!importantErrors.includes(errorData.meta?.type)) {
      return;
    }

    // Собираем базовые данные
    const analyticsData = {
      event: 'game_error',
      error_id: errorData.id,
      message: errorData.message?.substring(0, 200), // ограничиваем длину
      type: errorData.meta?.type,
      timestamp: errorData.timestamp,
      level: errorData.context?.level || 0,
      phase: errorData.context?.phase || 'unknown',
      url: window.location.href,
      user_agent: navigator.userAgent.substring(0, 100),
    };

    // Опційно: глобальний об'єкт analytics з .track; інакше лише sendBeacon нижче
    if (typeof analytics !== 'undefined' && typeof analytics.track === 'function') {
      analytics.track('game_error', analyticsData);
    }

    // Альтернативно через navigator.sendBeacon
    if (navigator.sendBeacon && window.ANALYTICS_ENDPOINT) {
      const blob = new Blob([JSON.stringify(analyticsData)], { type: 'application/json' });
      navigator.sendBeacon(window.ANALYTICS_ENDPOINT + '/error', blob);
    }
  } catch (e) {
    // Тихий сбой - не логируем ошибку об ошибке
  }
};
