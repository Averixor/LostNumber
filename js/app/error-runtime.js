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

  this.wrapMethod(this.core, 'validateMove', 'GameCore.validateMove');
  this.wrapMethod(this.core, 'canFinishChain', 'GameCore.canFinishChain');

  if (this.showMessage) {
    const originalShowMessage = this.showMessage;
    this.showMessage = function (...args) {
      try {
        return originalShowMessage.apply(this, args);
      } catch (error) {
        ErrorHandler.handle(error, {
          type: 'ui_error',
          method: 'showMessage',
          args: args.slice(0, 3),
        });
        if (typeof alert === 'function') {
          alert(args[0] || 'Error');
        }
      }
    }.bind(this);
  }

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
        args: args.slice(0, 5),
      });

      if (methodName.includes('validateMove')) return { valid: false, reason: 'error' };
      if (methodName.includes('validate')) return false;
      if (methodName.includes('calculate')) return 0;
      if (methodName.includes('get')) return null;

      throw error;
    }
  };
};

LostNumberGame.prototype.reportErrorToAnalytics = function (errorData) {
  try {
    const importantErrors = ['resource', 'runtime', 'promise'];
    if (!importantErrors.includes(errorData.meta?.type)) {
      return;
    }

    const analyticsData = {
      event: 'game_error',
      error_id: errorData.id,
      message: errorData.message?.substring(0, 200),
      type: errorData.meta?.type,
      timestamp: errorData.timestamp,
      level: errorData.context?.level || 0,
      phase: errorData.context?.phase || 'unknown',
      url: window.location.href,
      user_agent: navigator.userAgent.substring(0, 100),
    };

    if (typeof analytics !== 'undefined' && typeof analytics.track === 'function') {
      analytics.track('game_error', analyticsData);
    }

    if (navigator.sendBeacon && window.ANALYTICS_ENDPOINT) {
      const blob = new Blob([JSON.stringify(analyticsData)], { type: 'application/json' });
      navigator.sendBeacon(window.ANALYTICS_ENDPOINT + '/error', blob);
    }
  } catch (e) {}
};
