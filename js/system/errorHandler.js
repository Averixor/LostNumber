// errorHandler.js — глобальный контроль ошибок (без сервера)
if (window.AppEnv?.isDev) {
  console.log('ErrorHandler loaded');
}

class ErrorHandler {
  static _installed = false;
  static _game = null;
  static _counter = 0;
  static _config = {
    showUserMessages: true,
    logToConsole: true,
    collectStackTraces: true,
    maxErrorsPerMinute: 50,
    errorHistorySize: 100,
  };
  static _errorTimestamps = [];
  static _errorHistory = [];

  static install(config = {}) {
    if (this._installed) return;
    this._installed = true;
    Object.assign(this._config, config);

    // Обработчик ошибок выполнения
    window.addEventListener(
      'error',
      (ev) => {
        if (!this._shouldProcessError()) return;

        try {
          // Resource loading error
          const t = ev.target || ev.srcElement;
          if (t && (t.src || t.href)) {
            this.handle(`Resource load failed: ${t.tagName} ${t.src || t.href}`, {
              type: 'resource',
              tag: t.tagName,
              url: t.src || t.href,
              timestamp: Date.now(),
            });
            ev.preventDefault(); // предотвращаем стандартное сообщение браузера
            return;
          }

          // Runtime error
          this.handle(ev.error || ev.message, {
            type: 'runtime',
            filename: ev.filename,
            lineno: ev.lineno,
            colno: ev.colno,
            timestamp: Date.now(),
            stack: ev.error?.stack,
          });
        } catch (e) {
          this._safeLog('[ErrorHandler] internal error', e);
        }
      },
      true,
    );

    // Unhandled promise rejections
    window.addEventListener('unhandledrejection', (ev) => {
      if (!this._shouldProcessError()) return;
      this.handle(ev.reason, {
        type: 'promise',
        timestamp: Date.now(),
      });
    });

    if (window.AppEnv?.isDev) {
      console.log('ErrorHandler installed successfully');
    }
  }

  static _shouldProcessError() {
    // Ограничиваем частоту ошибок
    const now = Date.now();
    const minuteAgo = now - 60000;
    this._errorTimestamps = this._errorTimestamps.filter((t) => t > minuteAgo);

    if (this._errorTimestamps.length >= this._config.maxErrorsPerMinute) {
      this._safeLog('[ErrorHandler] Too many errors, skipping');
      return false;
    }

    this._errorTimestamps.push(now);
    return true;
  }

  static _perfMonitorActive = false;
  static _perfMonitorRAF = 0;
  static _perfMemoryTimer = 0;

  static startPerformanceMonitoring() {
    if (this._perfMonitorActive) return;
    this._perfMonitorActive = true;
    this._setupPerformanceMonitoring();
  }

  static stopPerformanceMonitoring() {
    this._perfMonitorActive = false;
    if (this._perfMonitorRAF) {
      cancelAnimationFrame(this._perfMonitorRAF);
      this._perfMonitorRAF = 0;
    }
    if (this._perfMemoryTimer) {
      clearInterval(this._perfMemoryTimer);
      this._perfMemoryTimer = 0;
    }
  }

  static _setupPerformanceMonitoring() {
    if (typeof requestAnimationFrame === 'function') {
      let lastTime = performance.now();
      let frames = 0;

      const checkFPS = () => {
        if (!this._perfMonitorActive) return;
        frames++;
        const current = performance.now();
        if (current >= lastTime + 1000) {
          const fps = Math.round((frames * 1000) / (current - lastTime));
          if (fps < 30) {
            this.warn(`Low FPS: ${fps}`, {
              type: 'performance',
              fps,
              memory: performance.memory?.usedJSHeapSize,
            });
          }
          frames = 0;
          lastTime = current;
        }
        this._perfMonitorRAF = requestAnimationFrame(checkFPS);
      };

      this._perfMonitorRAF = requestAnimationFrame(checkFPS);
    }

    if (performance.memory) {
      this._perfMemoryTimer = setInterval(() => {
        if (!this._perfMonitorActive) return;
        const memory = performance.memory;
        if (memory.usedJSHeapSize > memory.jsHeapSizeLimit * 0.8) {
          this.warn('High memory usage', {
            type: 'memory',
            used: Math.round(memory.usedJSHeapSize / 1024 / 1024) + 'MB',
            limit: Math.round(memory.jsHeapSizeLimit / 1024 / 1024) + 'MB',
          });
        }
      }, 30000);
    }
  }

  static setGame(game) {
    this._game = game || null;
  }

  static setConfig(config) {
    Object.assign(this._config, config);
  }

  static _id() {
    this._counter++;
    return `LN-${Date.now().toString(36).slice(-6)}-${this._counter.toString(36).toUpperCase()}`;
  }

  static _ctx() {
    const g = this._game || window.game;
    if (!g) return { hasGame: false, timestamp: Date.now() };

    try {
      const ctx = {
        hasGame: true,
        timestamp: Date.now(),
        userAgent: navigator.userAgent,
        platform: navigator.platform,
        url: window.location.href,
        language: navigator.language,
        online: navigator.onLine,
        screen: `${window.screen.width}x${window.screen.height}`,
        viewport: `${window.innerWidth}x${window.innerHeight}`,
      };

      // Добавляем игровой контекст если доступен
      if (g) {
        ctx.gamePhase = g.gamePhase;
        ctx.screenState = g.screenState;
        ctx.currentLevel = g.currentLevel;
        ctx.xp = g.xp;
        ctx.seed = g.currentSeed;

        // Безопасно получаем свойства
        try {
          ctx.levelTarget =
            typeof g.getLevelConfig === 'function'
              ? g.getLevelConfig(g.currentLevel).target
              : g.levels?.[g.currentLevel]?.target;
        } catch (_) {}
        try {
          ctx.lastSpinBonus = g.lastSpinBonus;
        } catch (_) {}

        // Дополнительный контекст, если доступен
        if (g.getDebugContext && typeof g.getDebugContext === 'function') {
          try {
            Object.assign(ctx, g.getDebugContext());
          } catch (_) {}
        }
      }

      return ctx;
    } catch (e) {
      return {
        hasGame: false,
        errorInContext: e.message,
        timestamp: Date.now(),
      };
    }
  }

  static _safeLog(...args) {
    try {
      console.log(...args);
    } catch (_) {}
  }

  static _addToHistory(errorData) {
    this._errorHistory.push(errorData);
    if (this._errorHistory.length > this._config.errorHistorySize) {
      this._errorHistory.shift();
    }
  }

  static handle(err, meta = {}) {
    const id = this._id();
    const e = err instanceof Error ? err : new Error(String(err));
    const ctx = this._ctx();

    // Добавляем ID ошибки в объект
    e.errorId = id;

    // Сохраняем в историю
    const errorData = {
      id,
      timestamp: Date.now(),
      message: e.message,
      stack: e.stack,
      meta,
      context: ctx,
    };
    this._addToHistory(errorData);

    if (this._config.logToConsole) {
      console.groupCollapsed(`%c[LostNumber ERROR] ${id}`, 'color:#ff6b9d;font-weight:900');
      console.log('Time:', new Date().toISOString());
      console.log('Meta:', meta);
      console.log('Context:', ctx);
      console.error(e);
      if (e.stack) {
        console.log('Stack:', e.stack);
      }
      console.groupEnd();
    }

    // Мягкое уведомление игроку
    if (this._config.showUserMessages) {
      try {
        const g = this._game || window.game;
        if (g && typeof g.showMessage === 'function') {
          // Можно добавить разные типы сообщений в зависимости от типа ошибки
          let message = `${g.t ? g.t('error_generic') : 'Помилка'}`;
          if (meta.type === 'resource') {
            message = g.t ? g.t('error_resource') : 'Помилка завантаження ресурсу';
          } else if (meta.type === 'promise') {
            message = g.t ? g.t('error_async') : 'Асинхронна помилка';
          }

          // Форматируем сообщение с ID ошибки
          const fullMessage = `${message} (${id})`;
          g.showMessage(fullMessage);

          // Логируем показ сообщения
          this.info(`User notified: ${fullMessage}`);
        }
      } catch (error) {
        this._safeLog('[ErrorHandler] Failed to show user message:', error);
      }
    }

    // Отправка на сервер для сбора статистики
    this._reportToServer(errorData);

    return id; // Возвращаем ID для отслеживания
  }

  static _reportToServer(errorData) {
    // Проверяем, настроена ли отправка на сервер
    if (typeof this._config.onErrorReport === 'function') {
      try {
        // Ограничиваем размер данных для отправки
        const reportData = {
          id: errorData.id,
          message: errorData.message.substring(0, 500),
          stack: errorData.stack?.substring(0, 2000),
          meta: errorData.meta,
          context: {
            hasGame: errorData.context.hasGame,
            gamePhase: errorData.context.gamePhase,
            currentLevel: errorData.context.currentLevel,
            userAgent: errorData.context.userAgent?.substring(0, 200),
            url: errorData.context.url,
          },
          timestamp: errorData.timestamp,
        };

        this._config.onErrorReport(reportData);
      } catch (error) {
        this._safeLog('[ErrorHandler] Failed to report error to server:', error);
      }
    }
  }

  // В errorHandler.js, в методе warn:
  static warn(message, data = {}) {
    const id = `WARN-${Date.now().toString(36).slice(-4)}`;

    // Вместо groupCollapsed используем обычный console.warn для лучшей видимости
    console.warn(`%c[LostNumber WARN] ${id}: ${message}`, 'color:#ffa726;font-weight:bold', data);

    // Сохраняем важные предупреждения в историю
    if (data.type && ['performance', 'memory', 'validation', 'i18n', 'grid'].includes(data.type)) {
      this._addToHistory({
        id,
        timestamp: Date.now(),
        message: `WARN: ${message}`,
        meta: { type: 'warning', ...data },
        context: this._ctx(),
      });
    }

    return id;
  }

  static info(message, data = {}) {
    if (window.AppEnv?.debugMode === 'off') return;
    try {
      console.info(`%c[LostNumber INFO] ${message}`, 'color:#4fc3f7', data);
    } catch (_) {}
  }

  static debug(message, data = {}) {
    if (window.AppEnv?.debugMode === 'off') return;
    try {
      console.debug(`%c[LostNumber DEBUG] ${message}`, 'color:#81c784', data);
    } catch (_) {}
  }

  // Методы для диагностики
  static getErrorHistory() {
    return [...this._errorHistory];
  }

  static clearErrorHistory() {
    this._errorHistory = [];
    this._errorTimestamps = [];
  }

  static getErrorStats() {
    const now = Date.now();
    const lastHour = now - 3600000;
    const lastMinute = now - 60000;

    const errorsLastHour = this._errorHistory.filter((e) => e.timestamp > lastHour);
    const errorsLastMinute = this._errorHistory.filter((e) => e.timestamp > lastMinute);

    const byType = {};
    errorsLastHour.forEach((e) => {
      const type = e.meta?.type || 'unknown';
      byType[type] = (byType[type] || 0) + 1;
    });

    return {
      totalErrors: this._errorHistory.length,
      errorsLastHour: errorsLastHour.length,
      errorsLastMinute: errorsLastMinute.length,
      errorsByType: byType,
      latestError: this._errorHistory[this._errorHistory.length - 1],
    };
  }

  // Обертка для безопасного выполнения функции
  static safeExecute(fn, context = {}, fallback = null) {
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
  }

  // Обертка для промисов
  static safePromise(promise, context = {}) {
    return promise
      .then((result) => result)
      .catch((error) => {
        this.handle(error, {
          type: 'safe_promise',
          context,
        });
        throw error;
      });
  }
}

window.ErrorHandler = ErrorHandler;

// Автоматическая установка с настройками по умолчанию
if (typeof ErrorHandler !== 'undefined') {
  const userConfig = window.ErrorHandlerConfig || {};

  const debugMode = window.AppEnv?.debugMode || 'off';
  const isDevelopment = debugMode !== 'off';

  if (isDevelopment) {
    Object.assign(userConfig, {
      logToConsole: true,
      showUserMessages: debugMode === 'full',
      maxErrorsPerMinute: window.AppEnv?.isDebugFull ? 250 : 120,
    });
  }

  setTimeout(() => {
    try {
      ErrorHandler.install(userConfig);
      ErrorHandler.info('ErrorHandler configured', {
        mode: debugMode,
        config: { ...userConfig, onErrorReport: userConfig.onErrorReport ? '[fn]' : undefined },
      });
    } catch (error) {
      console.error('Failed to install ErrorHandler:', error);
    }
  }, 0);
}
